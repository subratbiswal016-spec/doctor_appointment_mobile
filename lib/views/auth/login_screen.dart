import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../home/patient_shell_screen.dart';
import '../doctor/doctor_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController(text: '9876543210');
  final _otpController = TextEditingController(text: '123456');
  final _adminPassController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String _selectedRole = 'PATIENT'; // PATIENT or DOCTOR
  bool _showAdminLogin = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // Admin credentials (hardcoded single admin)
  static const String _adminPassword = 'admin123';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _adminPassController.dispose();
    super.dispose();
  }

  void _handleSendOtp() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ OTP Sent! Use demo OTP: 123456'),
          backgroundColor: AppTheme.primary,
        ),
      );
    });
  }

  void _handleVerifyOtp() async {
    setState(() => _isLoading = true);
    final result = await ApiService.verifyOtp(
      phone: _phoneController.text.trim(),
      otp: _otpController.text.trim(),
      role: _selectedRole,
    );
    if (!mounted) return;

    if (result['success'] == true) {
      _navigateToRole(result['role'] ?? _selectedRole, result);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login failed'),
          backgroundColor: AppTheme.colorBooked,
        ),
      );
    }
  }

  void _handleAdminLogin() async {
    final pass = _adminPassController.text.trim();
    if (pass != _adminPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Invalid Admin Password'),
          backgroundColor: AppTheme.colorBooked,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final result = await ApiService.demoLogin(role: 'ADMIN');
    if (!mounted) return;

    if (result['success'] == true) {
      _navigateToRole('ADMIN', result);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Admin login failed'),
          backgroundColor: AppTheme.colorBooked,
        ),
      );
    }
  }

  void _navigateToRole(String role, Map<String, dynamic> data) {
    final profileComplete = data['profileComplete'] == true;
    final isNewUser = data['isNewUser'] == true;
    final userData = data['user'] ?? {};

    // If new user or profile not complete -> go to profile setup
    if ((isNewUser || !profileComplete) && role.toUpperCase() != 'ADMIN') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(
            role: role.toUpperCase(),
            userData: userData is Map<String, dynamic> ? userData : Map<String, dynamic>.from(userData),
          ),
        ),
      );
      return;
    }

    Widget destination;
    switch (role.toUpperCase()) {
      case 'DOCTOR':
        final doctorId = data['doctorId'] ?? userData['doctorId'] ?? '';
        final doctorName = data['doctorName'] ?? userData['name'] ?? 'Doctor';
        destination = DoctorDashboardScreen(doctorId: doctorId ?? '', doctorName: doctorName);
        break;
      case 'ADMIN':
        destination = const AdminDashboardScreen();
        break;
      default:
        destination = const PatientShellScreen();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Logo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryBright],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBright.withValues(alpha: 0.3),
                        blurRadius: 15,
                      )
                    ],
                  ),
                  child: Text(
                    'SERIAL',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Book Tokens, Not Slots.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _showAdminLogin
                      ? 'Admin login requires password.'
                      : 'Select your role and enter phone to continue.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 24),

                if (_showAdminLogin) ...[
                  // ────── ADMIN LOGIN (password based) ──────
                  _buildAdminLoginSection(),
                ] else ...[
                  // ────── ROLE SELECTOR: Patient / Doctor ──────
                  Text(
                    'I AM A',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[500],
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildRoleChip('PATIENT', Icons.person_rounded, 'Patient', const Color(0xFF43C07E)),
                      const SizedBox(width: 14),
                      _buildRoleChip('DOCTOR', Icons.medical_services_rounded, 'Doctor', const Color(0xFF4DA6FF)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ────── Phone / OTP Input ──────
                  if (!_otpSent) ...[
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixText: '+91 ',
                        prefixIcon: Icon(Icons.phone_iphone, color: AppTheme.primaryBright),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedRole == 'DOCTOR' ? const Color(0xFF4DA6FF) : AppTheme.primaryBright,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : Text(
                                'Get OTP as ${_selectedRole == 'PATIENT' ? 'Patient' : 'Doctor'} ➔',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: AppTheme.primaryBright,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Enter 6-Digit OTP',
                        hintText: '123456',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleVerifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedRole == 'DOCTOR' ? const Color(0xFF4DA6FF) : AppTheme.primaryBright,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : Text(
                                'Verify & Enter as ${_selectedRole == 'PATIENT' ? 'Patient' : 'Doctor'} ➔',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _otpSent = false),
                      child: Text('← Change Phone Number', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ────── Admin Login Link (small text at bottom) ──────
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _showAdminLogin = true),
                      child: Text(
                        'Login as Admin →',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminLoginSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admin icon header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2000),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0AE4E).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0AE4E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFE0AE4E), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Panel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFE0AE4E),
                      ),
                    ),
                    Text(
                      'Master access to all system data',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _adminPassController,
          obscureText: true,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          decoration: const InputDecoration(
            labelText: 'Admin Password',
            hintText: 'Enter admin password',
            prefixIcon: Icon(Icons.lock_rounded, color: Color(0xFFE0AE4E)),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleAdminLogin,
            icon: _isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Icon(Icons.login_rounded, color: Colors.black),
            label: const Text(
              'Login as Admin',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0AE4E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _showAdminLogin = false),
            child: Text('← Back to User / Doctor Login', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleChip(String role, IconData icon, String label, Color color) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedRole = role;
          _otpSent = false;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : AppTheme.borderDark,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12)]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: isSelected ? color : Colors.grey[500]),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? color : Colors.grey[400],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
