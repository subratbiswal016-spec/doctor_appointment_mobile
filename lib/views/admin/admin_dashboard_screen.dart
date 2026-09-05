import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/doctor.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Doctor> _doctors = [];
  List<Map<String, dynamic>> _allAppointments = [];
  List<Map<String, dynamic>> _allUsers = [];
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final stats = await ApiService.getAdminStats();
    final docs = await ApiService.getDoctors();
    final appts = await ApiService.getAllAppointments();
    final users = await ApiService.getAllUsers();
    if (mounted) {
      setState(() {
        _stats = stats;
        _doctors = docs;
        _allAppointments = appts;
        _allUsers = users;
        _isLoading = false;
      });
    }
  }

  // ────── Add Doctor Modal ──────
  void _showAddDoctorModal() {
    final nameCtrl = TextEditingController();
    final qualCtrl = TextEditingController(text: 'MBBS, MD');
    final feeCtrl = TextEditingController(text: '700');
    final regCtrl = TextEditingController(text: 'MCI-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final expCtrl = TextEditingController(text: '12');
    final clinicCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Kolkata');
    final customSpecCtrl = TextEditingController();

    final defaultSpecs = [
      'Cardiologist', 'Dermatologist', 'General Physician', 'Pediatrician',
      'Neurologist', 'Orthopedic', 'Gynecologist', 'ENT', 'Dentist', 'Custom (Type below)'
    ];
    String selectedSpeciality = defaultSpecs.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '➕ Register New Doctor',
                      style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryBright),
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Doctor Name', hintText: 'e.g. Dr. S. K. Roy')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedSpeciality,
                  dropdownColor: AppTheme.cardDark,
                  decoration: const InputDecoration(labelText: 'Speciality / Type'),
                  items: defaultSpecs.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedSpeciality = val);
                  },
                ),
                if (selectedSpeciality == 'Custom (Type below)') ...[
                  const SizedBox(height: 10),
                  TextField(controller: customSpecCtrl, decoration: const InputDecoration(labelText: 'Enter Custom Speciality', hintText: 'e.g. Psychiatrist')),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: qualCtrl, decoration: const InputDecoration(labelText: 'Qualification'))),
                    const SizedBox(width: 10),
                    SizedBox(width: 80, child: TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fee ₹'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: regCtrl, decoration: const InputDecoration(labelText: 'Reg. Number'))),
                    const SizedBox(width: 10),
                    SizedBox(width: 80, child: TextField(controller: expCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Exp Yrs'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: clinicCtrl, decoration: const InputDecoration(labelText: 'Clinic Name', hintText: 'e.g. Apollo Clinic')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address'))),
                    const SizedBox(width: 10),
                    SizedBox(width: 100, child: TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City'))),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final spec = selectedSpeciality == 'Custom (Type below)' ? customSpecCtrl.text.trim() : selectedSpeciality;
                      final ok = await ApiService.createDoctor({
                        'name': nameCtrl.text.trim(),
                        'speciality': spec,
                        'qualification': qualCtrl.text.trim(),
                        'fee': int.tryParse(feeCtrl.text.trim()) ?? 700,
                        'registrationNumber': regCtrl.text.trim(),
                        'experienceYears': int.tryParse(expCtrl.text.trim()) ?? 10,
                        'clinicName': clinicCtrl.text.trim(),
                        'address': addrCtrl.text.trim(),
                        'city': cityCtrl.text.trim(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (ok) {
                        _loadDashboardData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Doctor registered!'), backgroundColor: AppTheme.primary),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check, color: Colors.black),
                    label: const Text('Register Doctor', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBright,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────── Add Session Modal ──────
  void _showAddSessionModal() {
    String? selectedDoctorId = _doctors.isNotEmpty ? _doctors.first.id : null;
    final dateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final startCtrl = TextEditingController(text: '10:00 AM');
    final endCtrl = TextEditingController(text: '01:00 PM');
    final maxCtrl = TextEditingController(text: '30');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('🗓 Create Session Slot', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryBright)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedDoctorId,
                  dropdownColor: AppTheme.cardDark,
                  decoration: const InputDecoration(labelText: 'Select Doctor'),
                  items: _doctors.map((d) => DropdownMenuItem(value: d.id, child: Text('${d.name} (${d.speciality})', overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) { if (val != null) selectedDoctorId = val; },
                ),
                const SizedBox(height: 10),
                TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', hintText: 'e.g. 2026-08-30')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Time'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Time'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: maxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Patients', hintText: '30')),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final date = dateCtrl.text.trim();
                      final ok = await ApiService.createSession({
                        'doctorId': selectedDoctorId,
                        'date': date,
                        'displayDate': date,
                        'startTime': startCtrl.text.trim(),
                        'endTime': endCtrl.text.trim(),
                        'maxPatients': int.tryParse(maxCtrl.text.trim()) ?? 30,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (ok) {
                        _loadDashboardData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Session created!'), backgroundColor: AppTheme.primary),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check, color: Colors.black),
                    label: const Text('Create Session', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBright,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE0AE4E)))
            : RefreshIndicator(
                color: const Color(0xFFE0AE4E),
                onRefresh: _loadDashboardData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildMasterStats()),
                    SliverToBoxAdapter(child: _buildTabBar()),
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [
                          _buildAppointmentsTab(),
                          _buildUsersTab(),
                          _buildDoctorsTab(),
                          _buildActionsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2000), Color(0xFF091312)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0AE4E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFE0AE4E), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMIN CONTROL PANEL',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFE0AE4E), letterSpacing: 1.5),
                ),
                const SizedBox(height: 2),
                Text(
                  'System Overview',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterStats() {
    final activeDoctors = _stats['activeDoctors'] ?? 0;
    final totalUsers = _stats['totalUsers'] ?? 0;
    final bookedTokens = _stats['bookedTokens'] ?? 0;
    final totalRevenue = _stats['totalRevenue'] ?? 0;
    final todayBooked = _stats['todayBooked'] ?? 0;
    final todayRevenue = _stats['todayRevenue'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _miniStat(Icons.people_alt_rounded, 'Total Users', '$totalUsers', const Color(0xFF4DA6FF))),
              const SizedBox(width: 10),
              Expanded(child: _miniStat(Icons.medical_services_rounded, 'Doctors', '$activeDoctors', AppTheme.primaryBright)),
              const SizedBox(width: 10),
              Expanded(child: _miniStat(Icons.confirmation_number_rounded, 'Bookings', '$bookedTokens', AppTheme.colorAvailable)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _miniStat(Icons.currency_rupee_rounded, 'Total Revenue', '₹$totalRevenue', const Color(0xFFE0AE4E))),
              const SizedBox(width: 10),
              Expanded(child: _miniStat(Icons.today_rounded, 'Today Booked', '$todayBooked', AppTheme.colorAvailable)),
              const SizedBox(width: 10),
              Expanded(child: _miniStat(Icons.payments_rounded, 'Today ₹', '₹$todayRevenue', AppTheme.primaryBright)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabCtrl,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: const Color(0xFFE0AE4E).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0AE4E).withValues(alpha: 0.4)),
          ),
          labelColor: const Color(0xFFE0AE4E),
          unselectedLabelColor: Colors.grey[500],
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: '📋 Bookings'),
            Tab(text: '👥 Users'),
            Tab(text: '👨‍⚕️ Doctors'),
            Tab(text: '⚙ Actions'),
          ],
        ),
      ),
    );
  }

  // ────── TAB 1: All Appointments ──────
  Widget _buildAppointmentsTab() {
    if (_allAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_rounded, size: 48, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text('No bookings yet', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _allAppointments.length,
      itemBuilder: (ctx, i) {
        final a = _allAppointments[i];
        final serial = a['serialNumber'] ?? 0;
        final name = a['patientName'] ?? 'Patient';
        final phone = a['patientPhone'] ?? '';
        final status = a['status'] ?? '';
        final amount = a['amount'] ?? 0;
        final doctorData = a['doctorId'];
        final sessionData = a['sessionId'];
        String doctorName = 'Doctor';
        String sessionInfo = '';
        if (doctorData is Map) {
          doctorName = doctorData['name'] ?? 'Doctor';
        }
        if (sessionData is Map) {
          sessionInfo = '${sessionData['date'] ?? ''} · ${sessionData['startTime'] ?? ''}';
        }

        Color statusColor;
        switch (status) {
          case 'COMPLETED':
            statusColor = AppTheme.primaryBright;
            break;
          case 'ARRIVED':
            statusColor = const Color(0xFF4DA6FF);
            break;
          case 'CANCELLED':
            statusColor = AppTheme.colorBooked;
            break;
          default:
            statusColor = AppTheme.colorAvailable;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryWash,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryBright.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '#${serial < 10 ? '0$serial' : serial}',
                      style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryBright),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.medical_services_rounded, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(doctorName, style: TextStyle(fontSize: 12, color: Colors.grey[400]), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.phone_rounded, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
              if (sessionInfo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 13, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(sessionInfo, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    const Spacer(),
                    Text(
                      '₹$amount',
                      style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFFE0AE4E)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ────── TAB 2: Registered Users & Profiles ──────
  Widget _buildUsersTab() {
    if (_allUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text('No users registered yet', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _allUsers.length,
      itemBuilder: (ctx, i) {
        final u = _allUsers[i];
        final name = u['name'] ?? 'Unnamed User';
        final phone = u['phone'] ?? '';
        final role = (u['role'] ?? 'PATIENT').toString().toUpperCase();
        final age = u['age'] ?? 0;
        final gender = u['gender'] ?? 'Unspecified';
        final isComplete = u['profileComplete'] == true;
        final docProfile = u['doctorProfile'];

        final isDoctor = role == 'DOCTOR';
        final roleColor = isDoctor ? const Color(0xFF4DA6FF) : (role == 'ADMIN' ? const Color(0xFFE0AE4E) : AppTheme.primaryBright);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDoctor ? Icons.medical_services_rounded : (role == 'ADMIN' ? Icons.admin_panel_settings_rounded : Icons.person_rounded),
                      color: roleColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name.isNotEmpty ? name : 'User ($phone)',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                role,
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: roleColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Phone: +91 $phone · Age: ${age > 0 ? age : 'N/A'} · $gender',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isComplete ? AppTheme.primaryWash : Colors.grey[800],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isComplete ? 'Profile Complete' : 'Incomplete',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isComplete ? AppTheme.primaryBright : Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ),
              if (isDoctor && docProfile is Map) ...[
                const Divider(color: AppTheme.borderDark, height: 16),
                Row(
                  children: [
                    const Icon(Icons.local_hospital_rounded, size: 14, color: Color(0xFF4DA6FF)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${docProfile['speciality'] ?? ''} · ${docProfile['clinicName'] ?? ''} (Fee: ₹${docProfile['fee'] ?? 0})',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF4DA6FF), fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ────── TAB 3: Registered Doctors ──────
  Widget _buildDoctorsTab() {
    if (_doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded, size: 48, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text('No doctors registered', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _doctors.length,
      itemBuilder: (ctx, i) {
        final doc = _doctors[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primaryWash,
                backgroundImage: NetworkImage(doc.photo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Color(0xFF4DA6FF), size: 14),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doc.speciality} · ${doc.qualification}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${doc.clinicName}, ${doc.city}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${doc.fee.toInt()}',
                    style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryBright),
                  ),
                  const SizedBox(height: 2),
                  Text('${doc.experienceYears} yrs exp', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ────── TAB 3: Admin Actions ──────
  Widget _buildActionsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _actionTile(
          icon: Icons.person_add_rounded,
          color: AppTheme.primaryBright,
          title: 'Register New Doctor',
          subtitle: 'Add a doctor with speciality & fee to the system',
          onTap: _showAddDoctorModal,
        ),
        const SizedBox(height: 12),
        _actionTile(
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFF4DA6FF),
          title: 'Create Session Slot',
          subtitle: 'Set date, time & max patient tokens for a doctor',
          onTap: _showAddSessionModal,
        ),
        const SizedBox(height: 12),
        _actionTile(
          icon: Icons.refresh_rounded,
          color: const Color(0xFFE0AE4E),
          title: 'Refresh All Data',
          subtitle: 'Reload stats, doctors & appointments from server',
          onTap: _loadDashboardData,
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
