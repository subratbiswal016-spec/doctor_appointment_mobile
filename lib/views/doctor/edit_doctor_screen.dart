import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class EditDoctorScreen extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic>? profile;
  const EditDoctorScreen({super.key, required this.doctorId, this.profile});

  @override
  State<EditDoctorScreen> createState() => _EditDoctorScreenState();
}

class _EditDoctorScreenState extends State<EditDoctorScreen> {
  late final TextEditingController _name;
  late final TextEditingController _qualification;
  late final TextEditingController _speciality;
  late final TextEditingController _fee;
  late final TextEditingController _clinic;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _about;
  late final TextEditingController _email;
  late final TextEditingController _languages;

  bool _saving = false;
  bool _gettingLocation = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile ?? {};
    _name = TextEditingController(text: p['name']?.toString() ?? '');
    _qualification = TextEditingController(text: p['qualification']?.toString() ?? '');
    _speciality = TextEditingController(text: p['speciality']?.toString() ?? '');
    _fee = TextEditingController(text: (p['fee'] ?? '').toString());
    _clinic = TextEditingController(text: p['clinicName']?.toString() ?? '');
    _address = TextEditingController(text: p['address']?.toString() ?? '');
    _city = TextEditingController(text: p['city']?.toString() ?? '');
    _lat = TextEditingController(text: (p['latitude'] ?? '').toString());
    _lng = TextEditingController(text: (p['longitude'] ?? '').toString());
    _about = TextEditingController(text: p['about']?.toString() ?? '');
    _email = TextEditingController(text: p['email']?.toString() ?? '');
    final langs = p['languages'];
    _languages = TextEditingController(
      text: langs is List ? langs.join(', ') : (langs?.toString() ?? ''),
    );
  }

  @override
  void dispose() {
    for (final c in [_name, _qualification, _speciality, _fee, _clinic, _address, _city, _lat, _lng, _about, _email, _languages]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gettingLocation = true);
    final pos = await LocationService.getCurrentPosition();
    setState(() => _gettingLocation = false);
    if (!mounted) return;
    if (pos != null) {
      setState(() {
        _lat.text = pos.latitude.toStringAsFixed(6);
        _lng.text = pos.longitude.toStringAsFixed(6);
      });
      _snack('Location captured', ok: true);
    } else {
      _snack('Could not get location. Enable GPS & permission.');
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _clinic.text.trim().isEmpty) {
      _snack('Name and clinic are required');
      return;
    }
    setState(() => _saving = true);
    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'qualification': _qualification.text.trim(),
      'speciality': _speciality.text.trim(),
      'clinicName': _clinic.text.trim(),
      'address': _address.text.trim(),
      'city': _city.text.trim(),
    };
    data['about'] = _about.text.trim();
    data['email'] = _email.text.trim();
    data['languages'] = _languages.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final fee = double.tryParse(_fee.text.trim());
    if (fee != null) data['fee'] = fee;
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if (lat != null) data['latitude'] = lat;
    if (lng != null) data['longitude'] = lng;

    final ok = await ApiService.updateDoctor(widget.doctorId, data);
    setState(() => _saving = false);
    if (!mounted) return;
    _snack(ok ? 'Profile updated' : 'Update failed', ok: ok);
    if (ok) Navigator.pop(context, true);
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? AppTheme.colorAvailable : Colors.redAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Edit My Details', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('Full name', _name, icon: Icons.person_outline),
          _field('Qualification (e.g. MBBS, MD)', _qualification, icon: Icons.school_outlined),
          _field('Speciality', _speciality, icon: Icons.medical_services_outlined),
          _field('Consultation fee (₹)', _fee, icon: Icons.currency_rupee_rounded, number: true),
          _field('Clinic / Hospital name', _clinic, icon: Icons.local_hospital_outlined),
          _field('Address', _address, icon: Icons.location_on_outlined, maxLines: 2),
          _field('City', _city, icon: Icons.location_city_outlined),
          _field('Email', _email, icon: Icons.email_outlined),
          _field('Languages (comma separated)', _languages, icon: Icons.translate_rounded),
          _field('About / short bio', _about, icon: Icons.info_outline, maxLines: 4),
          const SizedBox(height: 8),
          Text('LOCATION (for "Nearby" search)',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field('Latitude', _lat, icon: Icons.my_location_rounded, number: true, dense: true)),
              const SizedBox(width: 10),
              Expanded(child: _field('Longitude', _lng, icon: Icons.my_location_rounded, number: true, dense: true)),
            ],
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _gettingLocation ? null : _useCurrentLocation,
            icon: _gettingLocation
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBright))
                : const Icon(Icons.gps_fixed_rounded, color: AppTheme.primaryBright, size: 18),
            label: Text(_gettingLocation ? 'Getting location…' : 'Use my current location',
                style: const TextStyle(color: AppTheme.primaryBright, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryBright),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.save_rounded, color: Colors.black),
              label: Text(_saving ? 'Saving…' : 'Save Changes',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBright,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {IconData? icon, bool number = false, int maxLines = 1, bool dense = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 0 : 14),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: icon != null ? Icon(icon, color: AppTheme.primaryBright, size: 20) : null,
          filled: true,
          fillColor: AppTheme.cardDark,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryBright, width: 1.5),
          ),
        ),
      ),
    );
  }
}
