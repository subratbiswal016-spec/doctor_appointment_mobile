import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../home/patient_shell_screen.dart';
import '../doctor/doctor_dashboard_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String role; // PATIENT or DOCTOR
  final Map<String, dynamic> userData;

  const ProfileSetupScreen({
    super.key,
    required this.role,
    required this.userData,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  bool _isLoading = false;
  int _step = 0; // 0 = basic info, 1 = doctor details (if doctor)

  // Basic profile fields
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _gender = 'Male';

  // Doctor-specific fields
  final _qualCtrl = TextEditingController(text: 'MBBS, MD');
  final _feeCtrl = TextEditingController(text: '700');
  final _regCtrl = TextEditingController();
  final _expCtrl = TextEditingController(text: '10');
  final _clinicCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Kolkata');
  String _speciality = 'General Physician';
  String _selectedPhotoUrl = 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=400&q=80';

  final List<String> _avatarChoices = [
    'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=400&q=80',
  ];

  final _specialities = [
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Neurologist',
    'Orthopedic',
    'Gynecologist',
    'ENT',
    'Dentist',
    'Psychiatrist',
    'Urologist',
    'Oncologist',
    'Ophthalmologist',
    'Pulmonologist',
    'Gastroenterologist',
    'Nephrologist',
    'Endocrinologist',
    'Rheumatologist',
    'Hematologist',
    'Plastic Surgeon',
    'General Surgeon',
    'Neurosurgeon',
    'Cardiac Surgeon',
    'Vascular Surgeon',
    'Anesthesiologist',
    'Radiologist',
    'Pathologist',
    'Physiotherapist',
    'Ayurvedic',
    'Homeopathic',
    'Unani',
    'Sexologist',
    'Allergist',
    'Diabetologist',
    'Neonatologist',
    'Geriatrician',
    'Sports Medicine',
    'Pain Management',
    'Infectious Disease',
    'Emergency Medicine',
    'Palliative Care',
    'Intensivist (ICU)',
    'Forensic Medicine',
  ];
  final _otherSpecialityCtrl = TextEditingController();

  bool get _isDoctor => widget.role == 'DOCTOR';

  @override
  void initState() {
    super.initState();
    _regCtrl.text = 'MCI-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _qualCtrl.dispose();
    _feeCtrl.dispose();
    _regCtrl.dispose();
    _expCtrl.dispose();
    _clinicCtrl.dispose();
    _addrCtrl.dispose();
    _cityCtrl.dispose();
    _otherSpecialityCtrl.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('Please enter your name');
      return;
    }
    if (_ageCtrl.text.trim().isEmpty) {
      _showError('Please enter your age');
      return;
    }

    if (_isDoctor) {
      setState(() => _step = 1);
    } else {
      _submitProfile();
    }
  }

  void _submitProfile() async {
    setState(() => _isLoading = true);

    Map<String, dynamic>? doctorData;
    if (_isDoctor) {
      if (_clinicCtrl.text.trim().isEmpty) {
        _showError('Please enter your clinic name');
        setState(() => _isLoading = false);
        return;
      }
      doctorData = {
        'name': _nameCtrl.text.trim().startsWith('Dr.') ? _nameCtrl.text.trim() : 'Dr. ${_nameCtrl.text.trim()}',
        'photo': _selectedPhotoUrl,
        'speciality': _speciality,
        'qualification': _qualCtrl.text.trim(),
        'fee': int.tryParse(_feeCtrl.text.trim()) ?? 700,
        'registrationNumber': _regCtrl.text.trim(),
        'experienceYears': int.tryParse(_expCtrl.text.trim()) ?? 10,
        'clinicName': _clinicCtrl.text.trim(),
        'address': _addrCtrl.text.trim().isNotEmpty ? _addrCtrl.text.trim() : _clinicCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
      };
    }

    final result = await ApiService.updateProfile(
      userId: widget.userData['id'] ?? '',
      name: _isDoctor
          ? (_nameCtrl.text.trim().startsWith('Dr.') ? _nameCtrl.text.trim() : 'Dr. ${_nameCtrl.text.trim()}')
          : _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text.trim()) ?? 25,
      gender: _gender,
      role: widget.role,
      doctorData: doctorData,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      Widget destination;
      if (_isDoctor) {
        final doctorId = result['doctorId'] ?? result['user']?['doctorId'] ?? '';
        final doctorName = result['user']?['name'] ?? _nameCtrl.text.trim();
        destination = DoctorDashboardScreen(doctorId: doctorId, doctorName: doctorName);
      } else {
        destination = const PatientShellScreen();
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } else {
      setState(() => _isLoading = false);
      _showError(result['message'] ?? 'Failed to save profile');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.colorBooked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _isDoctor ? const Color(0xFF4DA6FF) : AppTheme.primaryBright;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isDoctor ? Icons.medical_services_rounded : Icons.person_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isDoctor ? 'Doctor Registration' : 'Patient Registration',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _step == 0 ? 'Complete Your Profile' : 'Professional Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _step == 0
                    ? 'Fill in your basic details to get started.'
                    : 'Add your clinic & speciality information.',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 28),

              // ────── Step 0: Basic Info ──────
              if (_step == 0) ...[
                _buildLabel('Full Name'),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: _isDoctor ? 'Dr. Rajesh Verma' : 'Amit Kumar',
                    prefixIcon: Icon(Icons.person_rounded, color: accentColor),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    // Age
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Age'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _ageCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            decoration: const InputDecoration(hintText: '28'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Gender
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Gender'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _gender,
                            dropdownColor: AppTheme.cardDark,
                            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                            items: ['Male', 'Female', 'Other'].map((g) =>
                              DropdownMenuItem(value: g, child: Text(g))
                            ).toList(),
                            onChanged: (val) { if (val != null) setState(() => _gender = val); },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : Text(
                            _isDoctor ? 'Next: Professional Details ➔' : 'Save & Continue ➔',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ),
              ],

              // ────── Step 1: Doctor Details ──────
              if (_step == 1) ...[
                _buildLabel('Select Doctor Profile Photo Avatar'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _avatarChoices.map((url) {
                    final isSel = _selectedPhotoUrl == url;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPhotoUrl = url),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? const Color(0xFF4DA6FF) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundImage: NetworkImage(url),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                _buildLabel('Speciality'),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _showSpecialityPicker,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.local_hospital_rounded, color: Color(0xFF4DA6FF)),
                      suffixIcon: Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                    ),
                    child: Text(
                      _speciality,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Qualification'),
                          const SizedBox(height: 6),
                          TextField(controller: _qualCtrl, decoration: const InputDecoration(hintText: 'MBBS, MD')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Fee ₹'),
                          const SizedBox(height: 6),
                          TextField(controller: _feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '700')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Reg. Number'),
                          const SizedBox(height: 6),
                          TextField(controller: _regCtrl, decoration: const InputDecoration(hintText: 'MCI-2026-XXX')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Exp Yrs'),
                          const SizedBox(height: 6),
                          TextField(controller: _expCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '10')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildLabel('Clinic Name'),
                const SizedBox(height: 6),
                TextField(
                  controller: _clinicCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Apollo Heart Clinic',
                    prefixIcon: Icon(Icons.business_rounded, color: Color(0xFF4DA6FF)),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Address'),
                          const SizedBox(height: 6),
                          TextField(controller: _addrCtrl, decoration: const InputDecoration(hintText: 'Park Street')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('City'),
                          const SizedBox(height: 6),
                          TextField(controller: _cityCtrl, decoration: const InputDecoration(hintText: 'Kolkata')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step = 0),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[600]!),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('← Back', style: TextStyle(color: Colors.grey[400])),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4DA6FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Text(
                                  'Register & Start ➔',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpecialityPicker() {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchCtrl.text.toLowerCase();
            final filtered = _specialities
                .where((s) => s.toLowerCase().contains(query))
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (_, scrollCtrl) {
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Select Speciality',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchCtrl,
                        autofocus: true,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search speciality...',
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF4DA6FF)),
                          suffixIcon: searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    searchCtrl.clear();
                                    setSheetState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppTheme.bgDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.borderDark),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.borderDark),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        controller: scrollCtrl,
                        children: [
                          ...filtered.map((s) {
                            final isSelected = s == _speciality;
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                color: isSelected ? const Color(0xFF4DA6FF) : Colors.grey[600],
                                size: 20,
                              ),
                              title: Text(
                                s,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFF4DA6FF) : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              onTap: () {
                                setState(() => _speciality = s);
                                Navigator.pop(ctx);
                              },
                            );
                          }),
                          if (filtered.isEmpty && query.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'No match found. Use "Other" below to add yours.',
                                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const Divider(color: AppTheme.borderDark, height: 1),
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.edit_rounded, color: Colors.orangeAccent, size: 20),
                            title: const Text('Other (type your speciality)', style: TextStyle(color: Colors.orangeAccent)),
                            onTap: () {
                              Navigator.pop(ctx);
                              _showCustomSpecialityDialog();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCustomSpecialityDialog() {
    _otherSpecialityCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Enter Your Speciality',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
        ),
        content: TextField(
          controller: _otherSpecialityCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g. Reproductive Medicine',
            filled: true,
            fillColor: AppTheme.bgDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderDark)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderDark)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              final val = _otherSpecialityCtrl.text.trim();
              if (val.isNotEmpty) {
                setState(() => _speciality = val);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DA6FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey[500],
        letterSpacing: 1,
      ),
    );
  }
}
