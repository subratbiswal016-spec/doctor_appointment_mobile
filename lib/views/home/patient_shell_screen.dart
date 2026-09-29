import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../appointments/my_appointments_screen.dart';
import '../profile/patient_profile_screen.dart';
import 'patient_home_screen.dart';

/// Bottom-nav shell for patients: Home · Appointments · Profile
class PatientShellScreen extends StatefulWidget {
  const PatientShellScreen({super.key});

  @override
  State<PatientShellScreen> createState() => _PatientShellScreenState();
}

class _PatientShellScreenState extends State<PatientShellScreen> {
  int _index = 0;

  final _pages = const [
    PatientHomeScreen(),
    MyAppointmentsScreen(),
    PatientProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: const Border(top: BorderSide(color: AppTheme.borderDark, width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primaryBright,
              unselectedItemColor: Colors.grey[500],
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
              unselectedLabelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined),
                  activeIcon: Icon(Icons.explore_rounded, color: AppTheme.primaryBright),
                  label: 'Discover',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.confirmation_number_outlined),
                  activeIcon: Icon(Icons.confirmation_number_rounded, color: AppTheme.primaryBright),
                  label: 'Appointments',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded, color: AppTheme.primaryBright),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
