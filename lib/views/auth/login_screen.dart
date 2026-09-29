import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:flutter/services.dart';
import '../home/patient_shell_screen.dart';
import '../doctor/doctor_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _LoginStep { phone, otp, password, setPassword }

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adminPassController = TextEditingController();

  _LoginStep _step = _LoginStep.phone;
  bool _isLoading = false;
  String _selectedRole = 'PATIENT';
  bool _showAdminLogin = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adminPassController.dispose();
    super.dispose();
  }

  void _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      _showSnack('Please enter a valid 10-digit phone number.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.sendOtp(phone: phone);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (result['hasPassword'] == true) {
        setState(() => _step = _LoginStep.password);
        _showSnack('Welcome back! Enter your password.');
      } else {
        setState(() => _step = _LoginStep.otp);
        _showSnack('OTP Sent! Check your phone.');
      }
    } else {
      _showSnack(result['message'] ?? 'Failed to connect', isError: true);
    }
  }

  void _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnack('Please enter a 6-digit OTP.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.verifyOtp(
      phone: _phoneController.text.trim(),
      otp: otp,
      role: _selectedRole,
    );
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _isLoading = false;
        _step = _LoginStep.setPassword;
      });
      _showSnack('Verified! Now set a password for future logins.');
    } else {
      setState(() => _isLoading = false);
      _showSnack(result['message'] ?? 'Invalid OTP', isError: true);
    }
  }

  void _handleSetPassword() async {
    final pw = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    if (pw.length < 4) {
      _showSnack('Password must be at least 4 characters.', isError: true);
      return;
    }
    if (pw != confirm) {
      _showSnack('Passwords do not match.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.setPassword(
      phone: _phoneController.text.trim(),
      password: pw,
    );
    if (!mounted) return;

    if (result['success'] == true) {
      final loginResult = await ApiService.loginWithPassword(
        phone: _phoneController.text.trim(),
        password: pw,
        role: _selectedRole,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (loginResult['success'] == true) {
        _showSnack('Password set! Logging you in...');
        _navigateToRole(loginResult['role'] ?? _selectedRole, loginResult);
      } else {
        _showSnack(loginResult['message'] ?? 'Login failed after setting password', isError: true);
      }
    } else {
      setState(() => _isLoading = false);
      _showSnack(result['message'] ?? 'Failed to set password', isError: true);
    }
  }

  void _handlePasswordLogin() async {
    final pw = _passwordController.text.trim();
    if (pw.isEmpty) {
      _showSnack('Please enter your password.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.loginWithPassword(
      phone: _phoneController.text.trim(),
      password: pw,
      role: _selectedRole,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _navigateToRole(result['role'] ?? _selectedRole, result);
    } else {
      _showSnack(result['message'] ?? 'Login failed', isError: true);
    }
  }

  void _handleAdminLogin() async {
    final pass = _adminPassController.text.trim();
    if (pass != _adminPassword) {
      _showSnack('Invalid Admin Password', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final result = await ApiService.verifyOtp(
      phone: '9999000001',
      otp: '123456',
      role: 'ADMIN',
    );
    if (!mounted) return;

    if (result['success'] == true) {
      _navigateToRole('ADMIN', result);
    } else {
      setState(() => _isLoading = false);
      _showSnack(result['message'] ?? 'Admin login failed', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.colorBooked : AppTheme.primary,
      ),
    );
  }

  void _navigateToRole(String role, Map<String, dynamic> data) {
    final profileComplete = data['profileComplete'] == true;
    final isNewUser = data['isNewUser'] == true;
    final userData = data['user'] ?? {};

    if ((isNewUser || !profileComplete) && role.toUpperCase() != 'ADMIN') {
      Navigator.push(
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
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
                      : _step == _LoginStep.setPassword
                          ? 'Set a password for future logins.'
                          : _step == _LoginStep.password
                              ? 'Welcome back! Enter your password.'
                              : 'Select your role and enter phone to continue.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 24),

                if (_showAdminLogin) ...[
                  _buildAdminLoginSection(),
                ] else ...[
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

                  // ────── STEP: Phone entry ──────
                  if (_step == _LoginStep.phone) ...[
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
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
                                'Continue as ${_selectedRole == 'PATIENT' ? 'Patient' : 'Doctor'} ➤',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),
                  ],

                  // ────── STEP: OTP (new user) ──────
                  if (_step == _LoginStep.otp) ...[
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: AppTheme.primaryBright,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Enter 6-Digit OTP',
                        hintText: '------',
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
                            : const Text(
                                'Verify OTP ➤',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() {
                        _step = _LoginStep.phone;
                        _otpController.clear();
                      }),
                      child: Text('← Change Phone Number', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ),
                  ],

                  // ────── STEP: Password (returning user) ──────
                  if (_step == _LoginStep.password) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBright.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryBright.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_iphone, color: AppTheme.primaryBright, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            '+91 ${_phoneController.text.trim()}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_rounded, color: AppTheme.primaryBright),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[500],
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handlePasswordLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedRole == 'DOCTOR' ? const Color(0xFF4DA6FF) : AppTheme.primaryBright,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : Text(
                                'Login as ${_selectedRole == 'PATIENT' ? 'Patient' : 'Doctor'} ➤',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() {
                        _step = _LoginStep.phone;
                        _passwordController.clear();
                      }),
                      child: Text('← Change Phone Number', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ),
                  ],

                  // ────── STEP: Set Password (after first OTP verify) ──────
                  if (_step == _LoginStep.setPassword) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A2A1A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF43C07E).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF43C07E), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Phone verified! Set a password so you don\'t need OTP next time.',
                              style: TextStyle(color: Colors.grey[300], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Create Password',
                        prefixIcon: const Icon(Icons.lock_rounded, color: AppTheme.primaryBright),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[500],
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryBright),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[500],
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43C07E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text(
                                'Set Password & Continue ➤',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
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
          if (_step != _LoginStep.phone && _step != _LoginStep.setPassword) {
            _step = _LoginStep.phone;
            _otpController.clear();
            _passwordController.clear();
          }
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
