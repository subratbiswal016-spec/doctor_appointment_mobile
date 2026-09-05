import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  late TextEditingController _name;
  late TextEditingController _age;
  String _gender = 'Male';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = ApiService.currentUser ?? {};
    _name = TextEditingController(text: u['name']?.toString() ?? '');
    _age = TextEditingController(text: (u['age'] != null && u['age'] != 0) ? u['age'].toString() : '');
    final g = u['gender']?.toString();
    if (g != null && ['Male', 'Female', 'Other'].contains(g)) _gender = g;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final u = ApiService.currentUser ?? {};
    final userId = u['id']?.toString() ?? '';
    if (userId.isEmpty) {
      _snack('Not logged in properly');
      return;
    }
    setState(() => _saving = true);
    final result = await ApiService.updateProfile(
      userId: userId,
      name: _name.text.trim(),
      age: int.tryParse(_age.text.trim()) ?? 0,
      gender: _gender,
      role: 'PATIENT',
    );
    setState(() => _saving = false);
    if (!mounted) return;
    _snack(result['success'] == true ? 'Profile saved' : (result['message'] ?? 'Failed'),
        ok: result['success'] == true);
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? AppTheme.colorAvailable : Colors.redAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final u = ApiService.currentUser ?? {};
    final phone = u['phone']?.toString() ?? '—';
    final initial = (_name.text.isNotEmpty ? _name.text[0] : 'U').toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D2137), Color(0xFF091312)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryBright, width: 2.5),
                      boxShadow: [BoxShadow(color: AppTheme.primaryBright.withValues(alpha: 0.35), blurRadius: 16)],
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: AppTheme.cardDark,
                      child: Text(initial,
                          style: GoogleFonts.plusJakartaSans(fontSize: 34, fontWeight: FontWeight.w800, color: AppTheme.primaryBright)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_name.text.isNotEmpty ? _name.text : 'Your Profile',
                      style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_rounded, size: 13, color: AppTheme.primaryBright),
                      const SizedBox(width: 5),
                      Text(phone, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Full name'),
                  const SizedBox(height: 6),
                  _textField(_name, 'Enter your name', Icons.person_outline),
                  const SizedBox(height: 16),
                  _label('Age'),
                  const SizedBox(height: 6),
                  _textField(_age, 'Enter your age', Icons.cake_outlined, number: true),
                  const SizedBox(height: 16),
                  _label('Gender'),
                  const SizedBox(height: 6),
                  Row(
                    children: ['Male', 'Female', 'Other'].map((g) {
                      final sel = _gender == g;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _gender = g),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.primary : AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: sel ? AppTheme.primaryBright : AppTheme.borderDark),
                            ),
                            child: Text(g,
                                style: TextStyle(color: sel ? Colors.white : Colors.grey[400], fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.save_rounded, color: Colors.black),
                      label: Text(_saving ? 'Saving…' : 'Save Profile',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBright,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ApiService.currentUser = null;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                      label: const Text('Log out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1.1));

  Widget _textField(TextEditingController c, String hint, IconData icon, {bool number = false}) {
    return TextField(
      controller: c,
      onChanged: (_) => setState(() {}),
      keyboardType: number ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.primaryBright, size: 20),
        filled: true,
        fillColor: AppTheme.cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderDark)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderDark)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryBright, width: 1.5)),
      ),
    );
  }
}
