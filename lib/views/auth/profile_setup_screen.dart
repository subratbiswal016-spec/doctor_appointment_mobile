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
    'https://images.unsplash.com/photo-1594824813566-78a01170461c?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=400&q=80',
  ];

  final _specialities = [
    'Cardiologist', 'Dermatologist', 'General Physician', 'Pediatrician',
    'Neurologist', 'Orthopedic', 'Gynecologist', 'ENT', 'Dentist',
    'Psychiatrist', 'Urologist', 'Oncologist',
  ];

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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
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
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _speciality,
                  dropdownColor: AppTheme.cardDark,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.local_hospital_rounded, color: Color(0xFF4DA6FF)),
                  ),
                  items: _specialities.map((s) =>
                    DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))
                  ).toList(),
                  onChanged: (val) { if (val != null) setState(() => _speciality = val); },
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
