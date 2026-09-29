import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/doctor.dart';
import '../../models/hospital.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../admin/admin_dashboard_screen.dart';
import 'hospital_detail_screen.dart';
import 'widgets/doctor_card.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  // 0 = Nearby Hospitals, 1 = All Doctors
  int _tab = 0;

  final _searchController = TextEditingController();

  // Location
  double? _lat;
  double? _lng;
  bool _locating = true;
  String _locationLabel = 'Locating you…';

  // Hospitals
  List<Hospital> _hospitals = [];
  bool _loadingHospitals = true;

  // Doctors
  List<Doctor> _doctors = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _selectedCity = 'All';
  final List<String> _cities = ['All', 'Chennai', 'Bengaluru', 'Kolkata', 'Bhubaneswar', 'Hyderabad'];
  bool _loadingDoctors = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      _lat = pos.latitude;
      _lng = pos.longitude;
      _locationLabel = 'Near your location';
    } else {
      // Fallback to city center — still shows hospitals, just without true distance
      _lat = null;
      _lng = null;
      _locationLabel = 'Location off · showing all areas';
    }
    if (mounted) setState(() => _locating = false);
    await _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    setState(() => _loadingHospitals = true);
    final hs = await ApiService.getNearbyHospitals(
      lat: _lat, lng: _lng, search: _searchController.text,
    );
    if (mounted) setState(() { _hospitals = hs; _loadingHospitals = false; });
  }

  Future<void> _loadDoctors() async {
    setState(() => _loadingDoctors = true);
    final cats = await ApiService.getSpecialities();
    final docs = await ApiService.getDoctors(
      search: _searchController.text,
      speciality: _selectedCategory,
      city: _selectedCity,
      lat: _lat,
      lng: _lng,
    );
    if (mounted) setState(() { _categories = cats; _doctors = docs; _loadingDoctors = false; });
  }

  void _onSearchChanged(String _) {
    if (_tab == 0) {
      _loadHospitals();
    } else {
      _loadDoctors();
    }
  }

  void _switchTab(int t) {
    setState(() => _tab = t);
    if (t == 1 && _doctors.isEmpty) _loadDoctors();
    if (t == 0) _loadHospitals();
  }

  // Quick-pick areas grouped by region (name + coordinates)
  static const Map<String, List<Map<String, dynamic>>> _areasByCity = {
    'Kolkata (West Bengal)': [
      {'name': 'Park Street, Kolkata', 'lat': 22.5535, 'lng': 88.3520},
      {'name': 'Salt Lake, Kolkata', 'lat': 22.5900, 'lng': 88.4100},
      {'name': 'Ballygunge, Kolkata', 'lat': 22.5190, 'lng': 88.3660},
      {'name': 'New Town, Kolkata', 'lat': 22.5800, 'lng': 88.4600},
      {'name': 'Howrah', 'lat': 22.5850, 'lng': 88.3100},
    ],
    'Odisha': [
      {'name': 'Bhubaneswar', 'lat': 20.2961, 'lng': 85.8245},
      {'name': 'Patia, Bhubaneswar', 'lat': 20.3558, 'lng': 85.8166},
      {'name': 'Cuttack', 'lat': 20.4625, 'lng': 85.8830},
      {'name': 'Rourkela', 'lat': 22.2604, 'lng': 84.8536},
    ],
    'Bengaluru (Karnataka)': [
      {'name': 'Koramangala, Bengaluru', 'lat': 12.9352, 'lng': 77.6245},
      {'name': 'Indiranagar, Bengaluru', 'lat': 12.9719, 'lng': 77.6412},
      {'name': 'Whitefield, Bengaluru', 'lat': 12.9698, 'lng': 77.7500},
      {'name': 'Jayanagar, Bengaluru', 'lat': 12.9250, 'lng': 77.5938},
    ],
    'Chennai (Tamil Nadu)': [
      {'name': 'T. Nagar, Chennai', 'lat': 13.0400, 'lng': 80.2337},
      {'name': 'Adyar, Chennai', 'lat': 13.0012, 'lng': 80.2565},
      {'name': 'Anna Nagar, Chennai', 'lat': 13.0850, 'lng': 80.2101},
      {'name': 'Velachery, Chennai', 'lat': 12.9791, 'lng': 80.2210},
    ],
    'Hyderabad (Telangana)': [
      {'name': 'Banjara Hills, Hyderabad', 'lat': 17.4126, 'lng': 78.4482},
      {'name': 'Gachibowli, Hyderabad', 'lat': 17.4400, 'lng': 78.3489},
      {'name': 'Secunderabad', 'lat': 17.4399, 'lng': 78.4983},
      {'name': 'Madhapur, Hyderabad', 'lat': 17.4483, 'lng': 78.3915},
    ],
  };

  void _applyLocation({double? lat, double? lng, required String label}) {
    String derivedCity = 'All';
    final lower = label.toLowerCase();
    if (lower.contains('chennai')) {
      derivedCity = 'Chennai';
    } else if (lower.contains('bengaluru') || lower.contains('bangalore')) {
      derivedCity = 'Bengaluru';
    } else if (lower.contains('kolkata') || lower.contains('howrah')) {
      derivedCity = 'Kolkata';
    } else if (lower.contains('bhubaneswar') || lower.contains('cuttack') || lower.contains('odisha')) {
      derivedCity = 'Bhubaneswar';
    } else if (lower.contains('hyderabad') || lower.contains('secunderabad')) {
      derivedCity = 'Hyderabad';
    }

    setState(() {
      _lat = lat;
      _lng = lng;
      _locationLabel = label;
      if (derivedCity != 'All') {
        _selectedCity = derivedCity;
      }
    });

    if (Navigator.canPop(context)) {
      Navigator.pop(context); // close the sheet
    }
    _loadHospitals();
    _loadDoctors();
  }

  Future<void> _useGpsAgain(void Function(void Function()) sheetSetState) async {
    sheetSetState(() {}); // trigger spinner if needed
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      _applyLocation(lat: pos.latitude, lng: pos.longitude, label: 'Near your location');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not get GPS. Enable location & permission.'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  void _openLocationPicker() {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool searching = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, sheetSetState) {
            Future<void> runSearch() async {
              final q = searchCtrl.text.trim();
              if (q.isEmpty) return;
              sheetSetState(() => searching = true);
              final r = await ApiService.geocode(q);
              sheetSetState(() { results = r; searching = false; });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: AppTheme.borderDark, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Choose location',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 14),
                  // Use GPS
                  GestureDetector(
                    onTap: () => _useGpsAgain(sheetSetState),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryWash,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryBright.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.my_location_rounded, color: AppTheme.primaryBright, size: 20),
                          SizedBox(width: 10),
                          Text('Use my current location (GPS)',
                              style: TextStyle(color: AppTheme.primaryBright, fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Free-text geocoding search
                  TextField(
                    controller: searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => runSearch(),
                    decoration: InputDecoration(
                      hintText: 'Type any city, area or landmark…',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBright, size: 20),
                      suffixIcon: TextButton(
                        onPressed: runSearch,
                        child: const Text('Search', style: TextStyle(color: AppTheme.primaryBright, fontWeight: FontWeight.bold)),
                      ),
                      filled: true,
                      fillColor: AppTheme.cardDark,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (searching)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBright)),
                    ),
                  if (!searching && results.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView(
                        shrinkWrap: true,
                        children: results.map((r) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_rounded, color: AppTheme.primaryBright, size: 20),
                          title: Text(r['name'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 12.5),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          onTap: () {
                            final short = (r['name'] as String).split(',').first;
                            _applyLocation(lat: r['lat'], lng: r['lng'], label: short);
                          },
                        )).toList(),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text('CHOOSE AN AREA',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _areasByCity.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 10, bottom: 6),
                                child: Text(entry.key,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                              ),
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: entry.value.map((a) => GestureDetector(
                                  onTap: () => _applyLocation(lat: a['lat'], lng: a['lng'], label: a['name']),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardDark,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppTheme.borderDark),
                                    ),
                                    child: Text(a['name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                )).toList(),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _tab == 0 ? _buildHospitalsBody() : _buildDoctorsBody(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── HEADER ───────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: AppTheme.borderDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryBright]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'SERIAL',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _locating ? null : _openLocationPicker,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Find & Book Appointments',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            _lat != null ? Icons.my_location_rounded : Icons.location_off_rounded,
                            size: 12, color: _lat != null ? AppTheme.colorAvailable : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _locating ? 'Locating you…' : _locationLabel,
                              style: const TextStyle(fontSize: 11, color: AppTheme.primaryBright, fontWeight: FontWeight.w600),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.primaryBright),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _iconBtn(Icons.admin_panel_settings_outlined, 'Admin & Doctor Portal', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()))
                    .then((_) => _tab == 0 ? _loadHospitals() : _loadDoctors());
              }, highlight: true),
            ],
          ),
          const SizedBox(height: 16),
          // Search
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: _tab == 0 ? 'Search hospital, area, or specialty…' : 'Search doctor, specialty, clinic…',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBright, size: 22),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
                      onPressed: () { _searchController.clear(); _onSearchChanged(''); },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: AppTheme.cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.borderDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.primaryBright, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // City Quick-Filter Chips Bar
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: _cities.map((city) {
                final isSel = _selectedCity == city;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCity = city;
                        if (_selectedCity != 'All') {
                          _locationLabel = _selectedCity;
                        }
                      });
                      if (_tab == 0) {
                        _loadHospitals();
                      } else {
                        _loadDoctors();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? AppTheme.primaryWash : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel ? AppTheme.primaryBright : AppTheme.borderDark,
                          width: isSel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (city != 'All')
                            Icon(
                              Icons.location_city_rounded,
                              size: 12,
                              color: isSel ? AppTheme.primaryBright : Colors.grey[400],
                            ),
                          if (city != 'All') const SizedBox(width: 4),
                          Text(
                            city == 'All' ? '📍 All Cities' : city,
                            style: TextStyle(
                              color: isSel ? AppTheme.primaryBright : Colors.grey[300],
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Toggle
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderDark),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _toggleBtn('🏥  Nearby Hospitals', 0),
                _toggleBtn('👨‍⚕️  All Doctors', 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, int index) {
    final sel = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: sel ? Colors.white : Colors.grey[400],
              fontWeight: sel ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tip, VoidCallback onTap, {bool highlight = false}) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: tip,
      icon: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: highlight ? AppTheme.primaryWash : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: highlight ? AppTheme.primaryBright : AppTheme.borderDark),
        ),
        child: Icon(icon, size: 18, color: AppTheme.primaryBright),
      ),
      onPressed: onTap,
    );
  }

  // ─────────────── HOSPITALS BODY ───────────────
  Widget _buildHospitalsBody() {
    if (_loadingHospitals) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBright));
    }
    if (_hospitals.isEmpty) {
      return _emptyState('No hospitals found', 'Try a different search, or switch to All Doctors.');
    }
    return RefreshIndicator(
      color: AppTheme.primaryBright,
      onRefresh: _loadHospitals,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _hospitals.length,
        itemBuilder: (ctx, i) => _hospitalCard(_hospitals[i]),
      ),
    );
  }

  Widget _hospitalCard(Hospital h) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => HospitalDetailScreen(hospital: h)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  Image.network(
                    h.photo,
                    height: 110, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 110, color: AppTheme.cardDark,
                      child: const Icon(Icons.local_hospital_rounded, size: 44, color: AppTheme.primaryBright),
                    ),
                  ),
                  if (h.distanceKm != null)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.near_me_rounded, size: 12, color: AppTheme.primaryBright),
                            const SizedBox(width: 4),
                            Text(h.distanceLabel,
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          h.clinicName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 3),
                      Text('${h.avgRating}',
                          style: const TextStyle(color: AppTheme.primaryBright, fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.primaryBright),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          h.address.isNotEmpty ? h.address : h.city,
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _miniPill(Icons.people_alt_rounded, '${h.doctorCount} doctors'),
                      const SizedBox(width: 8),
                      _miniPill(Icons.currency_rupee_rounded, 'from ₹${h.minFee.toInt()}'),
                      const Spacer(),
                      const Text('View ➔',
                          style: TextStyle(color: AppTheme.primaryBright, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  if (h.specialities.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: h.specialities.take(4).map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: Text(s, style: TextStyle(fontSize: 10.5, color: Colors.grey[300])),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppTheme.primaryBright),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─────────────── DOCTORS BODY ───────────────
  Widget _buildDoctorsBody() {
    return Column(
      children: [
        // Specialities chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: _categories.map((cat) {
                final isSel = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () { setState(() => _selectedCategory = cat); _loadDoctors(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? AppTheme.primary : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSel ? AppTheme.primaryBright : AppTheme.borderDark),
                      ),
                      child: Text(cat,
                          style: TextStyle(
                            color: isSel ? Colors.white : Colors.grey[300],
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: _loadingDoctors
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBright))
              : _doctors.isEmpty
                  ? _emptyState('No doctors found', 'Try another name, clinic, or specialty.')
                  : RefreshIndicator(
                      color: AppTheme.primaryBright,
                      onRefresh: _loadDoctors,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _doctors.length,
                        itemBuilder: (ctx, i) => DoctorCard(doctor: _doctors[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 54, color: AppTheme.primaryBright),
            const SizedBox(height: 14),
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
