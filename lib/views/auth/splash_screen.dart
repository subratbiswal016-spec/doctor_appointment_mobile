import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../home/patient_shell_screen.dart';
import '../doctor/doctor_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final session = await ApiService.loadSession();
    if (!mounted) return;

    if (session == null) {
      _goToLogin();
      return;
    }

    final role = (session['role'] as String? ?? 'PATIENT').toUpperCase();
    final user = session['user'] as Map<String, dynamic>? ?? {};
    final profileComplete = session['profileComplete'] == true || user['profileComplete'] == true;

    if (!profileComplete && role != 'ADMIN') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(role: role, userData: user),
        ),
      );
      return;
    }

    Widget destination;
    switch (role) {
      case 'DOCTOR':
        final doctorId = session['doctorId'] ?? user['doctorId'] ?? '';
        final doctorName = session['doctorName'] ?? user['name'] ?? 'Doctor';
        destination = DoctorDashboardScreen(doctorId: doctorId, doctorName: doctorName);
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

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryBright],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBright.withValues(alpha: 0.3),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Text(
                'SERIAL',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppTheme.primaryBright,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
