import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/doctor.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

const Color _gold = Color(0xFFE0AE4E);
const Color _blue = Color(0xFF4DA6FF);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Doctor> _doctors = [];
  List<Map<String, dynamic>> _allAppointments = [];
  List<Map<String, dynamic>> _allUsers = [];
  late TabController _tabCtrl;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Booking filters
  String _bookingDateFilter = 'ALL';
  String _bookingStatusFilter = 'ALL';
  DateTime? _customDate;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase().trim());
    });
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
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

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color ?? AppTheme.primary),
    );
  }

  // ═══════════ CONFIRM DIALOG ═══════════
  Future<bool> _confirmAction(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            content: Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: TextStyle(color: Colors.grey[500])),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: AppTheme.colorBooked, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ═══════════ ADD DOCTOR MODAL ═══════════
  void _showAddDoctorModal() {
    final nameCtrl = TextEditingController();
    final qualCtrl = TextEditingController(text: 'MBBS, MD');
    final feeCtrl = TextEditingController(text: '700');
    final regCtrl = TextEditingController(
        text: 'MCI-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final expCtrl = TextEditingController(text: '12');
    final clinicCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Kolkata');
    final customSpecCtrl = TextEditingController();

    final defaultSpecs = [
      'Cardiologist', 'Dermatologist', 'General Physician', 'Pediatrician',
      'Neurologist', 'Orthopedic', 'Gynecologist', 'ENT', 'Dentist',
      'Psychiatrist', 'Urologist', 'Oncologist', 'Ophthalmologist',
      'Custom (Type below)'
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
                _modalHeader(ctx, 'Register New Doctor', Icons.person_add_rounded),
                const SizedBox(height: 14),
                _field(nameCtrl, 'Doctor Name', hint: 'e.g. Dr. S. K. Roy'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedSpeciality,
                  dropdownColor: AppTheme.cardDark,
                  decoration: const InputDecoration(labelText: 'Speciality'),
                  items: defaultSpecs
                      .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedSpeciality = val);
                  },
                ),
                if (selectedSpeciality == 'Custom (Type below)') ...[
                  const SizedBox(height: 10),
                  _field(customSpecCtrl, 'Custom Speciality', hint: 'e.g. Psychiatrist'),
                ],
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _field(qualCtrl, 'Qualification')),
                  const SizedBox(width: 10),
                  SizedBox(width: 80, child: _field(feeCtrl, 'Fee', numeric: true)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _field(regCtrl, 'Reg. Number')),
                  const SizedBox(width: 10),
                  SizedBox(width: 80, child: _field(expCtrl, 'Exp Yrs', numeric: true)),
                ]),
                const SizedBox(height: 10),
                _field(clinicCtrl, 'Clinic Name', hint: 'e.g. Apollo Clinic'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _field(addrCtrl, 'Address')),
                  const SizedBox(width: 10),
                  SizedBox(width: 100, child: _field(cityCtrl, 'City')),
                ]),
                const SizedBox(height: 20),
                _primaryBtn('Register Doctor', () async {
                  final spec = selectedSpeciality == 'Custom (Type below)'
                      ? customSpecCtrl.text.trim()
                      : selectedSpeciality;
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
                    _snack('Doctor registered!');
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════ ADD SESSION MODAL ═══════════
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _modalHeader(ctx, 'Create Session Slot', Icons.calendar_month_rounded),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedDoctorId,
                  dropdownColor: AppTheme.cardDark,
                  decoration: const InputDecoration(labelText: 'Select Doctor'),
                  items: _doctors
                      .map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text('${d.name} (${d.speciality})',
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) selectedDoctorId = val;
                  },
                ),
                const SizedBox(height: 10),
                _field(dateCtrl, 'Date (YYYY-MM-DD)', hint: '2026-09-30'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _field(startCtrl, 'Start Time')),
                  const SizedBox(width: 10),
                  Expanded(child: _field(endCtrl, 'End Time')),
                ]),
                const SizedBox(height: 10),
                _field(maxCtrl, 'Max Patients', hint: '30', numeric: true),
                const SizedBox(height: 20),
                _primaryBtn('Create Session', () async {
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
                    _snack('Session created!');
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════ EDIT BOOKING MODAL ═══════════
  void _showEditBookingModal(Map<String, dynamic> appt) {
    final id = (appt['_id'] ?? appt['id'] ?? '').toString();
    final nameCtrl = TextEditingController(text: appt['patientName'] ?? '');
    final phoneCtrl = TextEditingController(text: appt['patientPhone'] ?? '');
    final ageCtrl = TextEditingController(text: '${appt['patientAge'] ?? ''}');
    final amountCtrl = TextEditingController(text: '${appt['amount'] ?? ''}');
    String status = appt['status'] ?? 'CONFIRMED';
    final statuses = ['CONFIRMED', 'ARRIVED', 'COMPLETED', 'CANCELLED'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _modalHeader(ctx, 'Edit Booking #${appt['serialNumber'] ?? ''}', Icons.edit_rounded),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: statuses.contains(status) ? status : 'CONFIRMED',
                  dropdownColor: AppTheme.cardDark,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: statuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => status = val);
                  },
                ),
                const SizedBox(height: 10),
                _field(nameCtrl, 'Patient Name'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _field(phoneCtrl, 'Phone')),
                  const SizedBox(width: 10),
                  SizedBox(width: 80, child: _field(ageCtrl, 'Age', numeric: true)),
                ]),
                const SizedBox(height: 10),
                _field(amountCtrl, 'Amount', numeric: true),
                const SizedBox(height: 20),
                _primaryBtn('Save Changes', () async {
                  final ok = await ApiService.adminUpdateBooking(id, {
                    'status': status,
                    'patientName': nameCtrl.text.trim(),
                    'patientPhone': phoneCtrl.text.trim(),
                    'patientAge': int.tryParse(ageCtrl.text.trim()) ?? 0,
                    'amount': int.tryParse(amountCtrl.text.trim()) ?? 0,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (ok) {
                    _loadDashboardData();
                    _snack('Booking updated!');
                  } else {
                    _snack('Failed to update', color: AppTheme.colorBooked);
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════ EDIT USER MODAL ═══════════
  void _showEditUserModal(Map<String, dynamic> user) {
    final id = (user['_id'] ?? user['id'] ?? '').toString();
    final nameCtrl = TextEditingController(text: user['name'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');
    final ageCtrl = TextEditingController(text: '${user['age'] ?? ''}');
    String gender = user['gender'] ?? 'Unspecified';
    String role = (user['role'] ?? 'PATIENT').toString().toUpperCase();
    final genders = ['Male', 'Female', 'Other', 'Unspecified'];
    final roles = ['PATIENT', 'DOCTOR', 'ADMIN'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _modalHeader(ctx, 'Edit User', Icons.person_rounded),
                const SizedBox(height: 14),
                _field(nameCtrl, 'Name'),
                const SizedBox(height: 10),
                _field(phoneCtrl, 'Phone'),
                const SizedBox(height: 10),
                Row(children: [
                  SizedBox(width: 80, child: _field(ageCtrl, 'Age', numeric: true)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: genders.contains(gender) ? gender : 'Unspecified',
                      dropdownColor: AppTheme.cardDark,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => gender = val);
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: roles.contains(role) ? role : 'PATIENT',
                  dropdownColor: AppTheme.cardDark,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => role = val);
                  },
                ),
                const SizedBox(height: 20),
                _primaryBtn('Save Changes', () async {
                  final ok = await ApiService.adminUpdateUser(id, {
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'age': int.tryParse(ageCtrl.text.trim()) ?? 0,
                    'gender': gender,
                    'role': role,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (ok) {
                    _loadDashboardData();
                    _snack('User updated!');
                  } else {
                    _snack('Failed to update', color: AppTheme.colorBooked);
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════ BOOKING DETAIL SHEET ═══════════
  void _showBookingDetail(Map<String, dynamic> a) {
    final doctorData = a['doctorId'];
    final sessionData = a['sessionId'];
    String doctorName = 'Unknown';
    String clinicName = '';
    String sessionInfo = '';
    if (doctorData is Map) {
      doctorName = doctorData['name'] ?? 'Unknown';
      clinicName = doctorData['clinicName'] ?? '';
    }
    if (sessionData is Map) {
      sessionInfo = '${sessionData['date'] ?? ''} | ${sessionData['startTime'] ?? ''} - ${sessionData['endTime'] ?? ''}';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusChip(a['status'] ?? ''),
                const SizedBox(width: 10),
                Text('Serial #${a['serialNumber'] ?? ''}',
                    style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryBright)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(color: AppTheme.borderDark),
            _detailRow(Icons.person, 'Patient', a['patientName'] ?? 'N/A'),
            _detailRow(Icons.phone, 'Phone', a['patientPhone'] ?? 'N/A'),
            _detailRow(Icons.cake, 'Age / Gender', '${a['patientAge'] ?? 'N/A'} / ${a['patientGender'] ?? 'N/A'}'),
            _detailRow(Icons.medical_services, 'Doctor', doctorName),
            _detailRow(Icons.local_hospital, 'Clinic', clinicName),
            _detailRow(Icons.schedule, 'Session', sessionInfo),
            _detailRow(Icons.currency_rupee, 'Amount', '${a['amount'] ?? 0}'),
            _detailRow(Icons.payment, 'Payment ID', a['paymentId'] ?? 'N/A'),
            _detailRow(Icons.access_time, 'Booked At', _formatDate(a['createdAt'])),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showEditBookingModal(a);
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _gold,
                    side: BorderSide(color: _gold.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final id = (a['_id'] ?? a['id'] ?? '').toString();
                    final yes = await _confirmAction('Delete Booking', 'Delete Serial #${a['serialNumber']} booking for ${a['patientName']}?');
                    if (yes) {
                      final ok = await ApiService.adminDeleteBooking(id);
                      if (ok) {
                        _loadDashboardData();
                        _snack('Booking deleted');
                      } else {
                        _snack('Failed to delete', color: AppTheme.colorBooked);
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.colorBooked,
                    side: BorderSide(color: AppTheme.colorBooked.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ═══════════ USER DETAIL SHEET ═══════════
  void _showUserDetail(Map<String, dynamic> u) {
    final docProfile = u['doctorProfile'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _roleBadge(u['role'] ?? 'PATIENT'),
              const SizedBox(width: 10),
              Expanded(
                child: Text(u['name'] ?? 'Unnamed',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
            ]),
            const Divider(color: AppTheme.borderDark),
            _detailRow(Icons.phone, 'Phone', '+91 ${u['phone'] ?? ''}'),
            _detailRow(Icons.cake, 'Age', '${u['age'] ?? 'N/A'}'),
            _detailRow(Icons.wc, 'Gender', u['gender'] ?? 'Unspecified'),
            _detailRow(Icons.check_circle, 'Profile', u['profileComplete'] == true ? 'Complete' : 'Incomplete'),
            _detailRow(Icons.access_time, 'Joined', _formatDate(u['createdAt'])),
            if (docProfile is Map) ...[
              const Divider(color: AppTheme.borderDark),
              Text('Doctor Profile', style: TextStyle(color: _blue, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              _detailRow(Icons.local_hospital, 'Speciality', docProfile['speciality'] ?? ''),
              _detailRow(Icons.school, 'Qualification', docProfile['qualification'] ?? ''),
              _detailRow(Icons.business, 'Clinic', docProfile['clinicName'] ?? ''),
              _detailRow(Icons.location_on, 'City', docProfile['city'] ?? ''),
              _detailRow(Icons.currency_rupee, 'Fee', '${docProfile['fee'] ?? 0}'),
            ],
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showEditUserModal(u);
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _gold,
                    side: BorderSide(color: _gold.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final id = (u['_id'] ?? u['id'] ?? '').toString();
                    final yes = await _confirmAction('Delete User', 'Delete "${u['name'] ?? u['phone']}" and all their data?');
                    if (yes) {
                      final ok = await ApiService.adminDeleteUser(id);
                      if (ok) {
                        _loadDashboardData();
                        _snack('User deleted');
                      } else {
                        _snack('Failed to delete', color: AppTheme.colorBooked);
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.colorBooked,
                    side: BorderSide(color: AppTheme.colorBooked.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ═══════════ DOCTOR DETAIL SHEET ═══════════
  void _showDoctorDetail(Doctor doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(radius: 24, backgroundImage: NetworkImage(doc.photo), backgroundColor: AppTheme.primaryWash),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(doc.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(doc.speciality, style: TextStyle(fontSize: 13, color: _blue, fontWeight: FontWeight.w600)),
                ]),
              ),
              IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
            ]),
            const Divider(color: AppTheme.borderDark),
            _detailRow(Icons.school, 'Qualification', doc.qualification),
            _detailRow(Icons.badge, 'Registration', doc.registrationNumber),
            _detailRow(Icons.work_history, 'Experience', '${doc.experienceYears} years'),
            _detailRow(Icons.currency_rupee, 'Fee', '${doc.fee.toInt()}'),
            _detailRow(Icons.business, 'Clinic', doc.clinicName),
            _detailRow(Icons.location_on, 'Address', '${doc.address}, ${doc.city}'),
            _detailRow(Icons.star, 'Rating', '${doc.rating} (${doc.reviewsCount} reviews)'),
            _detailRow(Icons.verified, 'Verified', doc.isVerified ? 'Yes' : 'No'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final yes = await _confirmAction('Delete Doctor', 'Delete "${doc.name}" and all their sessions & bookings?');
                    if (yes) {
                      final ok = await ApiService.adminDeleteDoctor(doc.id);
                      if (ok) {
                        _loadDashboardData();
                        _snack('Doctor deleted');
                      } else {
                        _snack('Failed to delete', color: AppTheme.colorBooked);
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete Doctor'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.colorBooked,
                    side: BorderSide(color: AppTheme.colorBooked.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ═══════════ FILTERED DATA HELPERS ═══════════

  List<Map<String, dynamic>> get _filteredAppointments {
    var list = _allAppointments;

    if (_bookingStatusFilter != 'ALL') {
      list = list.where((a) => a['status'] == _bookingStatusFilter).toList();
    }

    if (_bookingDateFilter == 'TODAY') {
      final todayStr = DateTime.now().toString().split(' ')[0];
      list = list.where((a) {
        final sess = a['sessionId'];
        if (sess is Map && sess['date'] != null) return sess['date'] == todayStr;
        final created = a['createdAt']?.toString() ?? '';
        return created.startsWith(todayStr);
      }).toList();
    } else if (_bookingDateFilter == 'CUSTOM' && _customDate != null) {
      final dateStr = _customDate!.toString().split(' ')[0];
      list = list.where((a) {
        final sess = a['sessionId'];
        if (sess is Map && sess['date'] != null) return sess['date'] == dateStr;
        final created = a['createdAt']?.toString() ?? '';
        return created.startsWith(dateStr);
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((a) {
        final name = (a['patientName'] ?? '').toString().toLowerCase();
        final phone = (a['patientPhone'] ?? '').toString().toLowerCase();
        final serial = '${a['serialNumber'] ?? ''}';
        final doc = a['doctorId'];
        final docName = doc is Map ? (doc['name'] ?? '').toString().toLowerCase() : '';
        return name.contains(_searchQuery) ||
            phone.contains(_searchQuery) ||
            serial.contains(_searchQuery) ||
            docName.contains(_searchQuery);
      }).toList();
    }

    return list;
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _allUsers;
    return _allUsers.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final phone = (u['phone'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || phone.contains(_searchQuery) || role.contains(_searchQuery);
    }).toList();
  }

  List<Doctor> get _filteredDoctors {
    if (_searchQuery.isEmpty) return _doctors;
    return _doctors.where((d) {
      final name = d.name.toLowerCase();
      final spec = d.speciality.toLowerCase();
      final city = d.city.toLowerCase();
      final clinic = d.clinicName.toLowerCase();
      return name.contains(_searchQuery) ||
          spec.contains(_searchQuery) ||
          city.contains(_searchQuery) ||
          clinic.contains(_searchQuery);
    }).toList();
  }

  // ═══════════ BUILD ═══════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _gold))
            : RefreshIndicator(
                color: _gold,
                onRefresh: _loadDashboardData,
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildMasterStats(),
                    _buildSearchBar(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [
                          _buildBookingsTab(),
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
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
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
              color: _gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: _gold, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ADMIN CONTROL PANEL',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, fontWeight: FontWeight.w700, color: _gold, letterSpacing: 1.5)),
                const SizedBox(height: 2),
                Text('System Overview',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () async {
              await ApiService.clearSession();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(children: [
        Row(children: [
          Expanded(child: _miniStat(Icons.people_alt_rounded, 'Total Users', '$totalUsers', _blue)),
          const SizedBox(width: 8),
          Expanded(child: _miniStat(Icons.medical_services_rounded, 'Doctors', '$activeDoctors', AppTheme.primaryBright)),
          const SizedBox(width: 8),
          Expanded(child: _miniStat(Icons.confirmation_number_rounded, 'Bookings', '$bookedTokens', AppTheme.colorAvailable)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _miniStat(Icons.currency_rupee_rounded, 'Revenue', '₹$totalRevenue', _gold)),
          const SizedBox(width: 8),
          Expanded(child: _miniStat(Icons.today_rounded, 'Today', '$todayBooked', AppTheme.colorAvailable)),
          const SizedBox(width: 8),
          Expanded(child: _miniStat(Icons.payments_rounded, 'Today ₹', '₹$todayRevenue', AppTheme.primaryBright)),
        ]),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by name, phone, speciality, city...',
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: _gold, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 20),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          filled: true,
          fillColor: AppTheme.cardDark,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _gold.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _gold.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _gold, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabCtrl,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: _gold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _gold.withValues(alpha: 0.4)),
          ),
          labelColor: _gold,
          unselectedLabelColor: Colors.grey[500],
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Bookings'),
            Tab(text: 'Users'),
            Tab(text: 'Doctors'),
            Tab(text: 'Actions'),
          ],
        ),
      ),
    );
  }

  // ═══════════ TAB 1: BOOKINGS ═══════════
  Widget _buildBookingsTab() {
    final filtered = _filteredAppointments;
    return Column(
      children: [
        // Date & Status filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip('All Dates', _bookingDateFilter == 'ALL', () {
                setState(() => _bookingDateFilter = 'ALL');
              }),
              _filterChip('Today', _bookingDateFilter == 'TODAY', () {
                setState(() => _bookingDateFilter = 'TODAY');
              }),
              _filterChip(
                _bookingDateFilter == 'CUSTOM' && _customDate != null
                    ? _customDate!.toString().split(' ')[0]
                    : 'Pick Date',
                _bookingDateFilter == 'CUSTOM',
                () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _customDate ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                    builder: (ctx, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(primary: _gold, surface: Color(0xFF1A2232)),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() {
                      _customDate = picked;
                      _bookingDateFilter = 'CUSTOM';
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: AppTheme.borderDark),
              const SizedBox(width: 8),
              _filterChip('All Status', _bookingStatusFilter == 'ALL', () {
                setState(() => _bookingStatusFilter = 'ALL');
              }),
              for (final s in ['CONFIRMED', 'ARRIVED', 'COMPLETED', 'CANCELLED'])
                _filterChip(s, _bookingStatusFilter == s, () {
                  setState(() => _bookingStatusFilter = s);
                }),
            ]),
          ),
        ),
        // Count
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(children: [
            Text('${filtered.length} bookings',
                style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          ]),
        ),
        // List
        Expanded(
          child: filtered.isEmpty
              ? _emptyState(Icons.event_note_rounded, 'No bookings found')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _buildBookingCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> a) {
    final serial = a['serialNumber'] ?? 0;
    final name = a['patientName'] ?? 'Patient';
    final phone = a['patientPhone'] ?? '';
    final status = a['status'] ?? '';
    final amount = a['amount'] ?? 0;
    final doctorData = a['doctorId'];
    final sessionData = a['sessionId'];
    String doctorName = 'Doctor';
    String sessionInfo = '';
    if (doctorData is Map) doctorName = doctorData['name'] ?? 'Doctor';
    if (sessionData is Map) sessionInfo = '${sessionData['date'] ?? ''} | ${sessionData['startTime'] ?? ''}';

    return InkWell(
      onTap: () => _showBookingDetail(a),
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryWash,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryBright.withValues(alpha: 0.3)),
                ),
                child: Text('#${serial < 10 ? '0$serial' : serial}',
                    style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryBright)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              _statusChip(status),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.medical_services_rounded, size: 13, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(child: Text(doctorName, style: TextStyle(fontSize: 12, color: Colors.grey[400]), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Icon(Icons.phone_rounded, size: 13, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ]),
            if (sessionInfo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.schedule_rounded, size: 13, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(sessionInfo, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const Spacer(),
                Text('₹$amount',
                    style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w800, color: _gold)),
              ]),
            ],
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _smallActionBtn(Icons.edit, 'Edit', _gold, () => _showEditBookingModal(a)),
              const SizedBox(width: 8),
              _smallActionBtn(Icons.delete_outline, 'Delete', AppTheme.colorBooked, () async {
                final id = (a['_id'] ?? a['id'] ?? '').toString();
                final yes = await _confirmAction('Delete Booking', 'Delete Serial #$serial booking?');
                if (yes) {
                  final ok = await ApiService.adminDeleteBooking(id);
                  if (ok) { _loadDashboardData(); _snack('Booking deleted'); }
                  else _snack('Failed', color: AppTheme.colorBooked);
                }
              }),
            ]),
          ],
        ),
      ),
    );
  }

  // ═══════════ TAB 2: USERS ═══════════
  Widget _buildUsersTab() {
    final filtered = _filteredUsers;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(children: [
            Text('${filtered.length} users', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          ]),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _emptyState(Icons.people_outline_rounded, 'No users found')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _buildUserCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> u) {
    final name = u['name'] ?? 'Unnamed User';
    final phone = u['phone'] ?? '';
    final role = (u['role'] ?? 'PATIENT').toString().toUpperCase();
    final age = u['age'] ?? 0;
    final gender = u['gender'] ?? 'Unspecified';
    final isComplete = u['profileComplete'] == true;
    final docProfile = u['doctorProfile'];
    final isDoctor = role == 'DOCTOR';

    return InkWell(
      onTap: () => _showUserDetail(u),
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
            Row(children: [
              _roleIcon(role),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(name.isNotEmpty ? name : 'User ($phone)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    _roleBadge(role),
                  ]),
                  const SizedBox(height: 2),
                  Text('Phone: +91 $phone  |  Age: ${age > 0 ? age : 'N/A'}  |  $gender',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isComplete ? AppTheme.primaryWash : Colors.grey[800],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(isComplete ? 'Complete' : 'Incomplete',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                        color: isComplete ? AppTheme.primaryBright : Colors.grey[400])),
              ),
            ]),
            if (isDoctor && docProfile is Map) ...[
              const Divider(color: AppTheme.borderDark, height: 14),
              Row(children: [
                const Icon(Icons.local_hospital_rounded, size: 14, color: _blue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                      '${docProfile['speciality'] ?? ''} | ${docProfile['clinicName'] ?? ''} (Fee: ₹${docProfile['fee'] ?? 0})',
                      style: const TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
            ],
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _smallActionBtn(Icons.edit, 'Edit', _gold, () => _showEditUserModal(u)),
              const SizedBox(width: 8),
              _smallActionBtn(Icons.delete_outline, 'Delete', AppTheme.colorBooked, () async {
                final id = (u['_id'] ?? u['id'] ?? '').toString();
                final yes = await _confirmAction('Delete User', 'Delete "${u['name'] ?? u['phone']}"?');
                if (yes) {
                  final ok = await ApiService.adminDeleteUser(id);
                  if (ok) { _loadDashboardData(); _snack('User deleted'); }
                  else _snack('Failed', color: AppTheme.colorBooked);
                }
              }),
            ]),
          ],
        ),
      ),
    );
  }

  // ═══════════ TAB 3: DOCTORS ═══════════
  Widget _buildDoctorsTab() {
    final filtered = _filteredDoctors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(children: [
            Text('${filtered.length} doctors', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          ]),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _emptyState(Icons.person_off_rounded, 'No doctors found')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _buildDoctorCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(Doctor doc) {
    return InkWell(
      onTap: () => _showDoctorDetail(doc),
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(doc.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 6),
                  if (doc.isVerified) const Icon(Icons.verified, color: _blue, size: 14),
                ]),
                const SizedBox(height: 2),
                Text('${doc.speciality} | ${doc.qualification}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${doc.clinicName}, ${doc.city}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${doc.fee.toInt()}',
                  style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryBright)),
              const SizedBox(height: 2),
              Text('${doc.experienceYears} yrs', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final yes = await _confirmAction('Delete Doctor', 'Delete "${doc.name}"?');
                  if (yes) {
                    final ok = await ApiService.adminDeleteDoctor(doc.id);
                    if (ok) { _loadDashboardData(); _snack('Doctor deleted'); }
                    else _snack('Failed', color: AppTheme.colorBooked);
                  }
                },
                child: Icon(Icons.delete_outline, size: 18, color: AppTheme.colorBooked.withValues(alpha: 0.7)),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ═══════════ TAB 4: ACTIONS ═══════════
  Widget _buildActionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _actionTile(
          icon: Icons.person_add_rounded,
          color: AppTheme.primaryBright,
          title: 'Register New Doctor',
          subtitle: 'Add a doctor with speciality & fee to the system',
          onTap: _showAddDoctorModal,
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.calendar_month_rounded,
          color: _blue,
          title: 'Create Session Slot',
          subtitle: 'Set date, time & max patient tokens for a doctor',
          onTap: _showAddSessionModal,
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.refresh_rounded,
          color: _gold,
          title: 'Refresh All Data',
          subtitle: 'Reload stats, doctors & appointments from server',
          onTap: _loadDashboardData,
        ),
      ],
    );
  }

  // ═══════════ SHARED WIDGETS ═══════════

  Widget _miniStat(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 8, color: Colors.grey[500], fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? _gold.withValues(alpha: 0.2) : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? _gold : AppTheme.borderDark),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? _gold : Colors.grey[500])),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color c;
    switch (status) {
      case 'COMPLETED': c = AppTheme.primaryBright; break;
      case 'ARRIVED': c = _blue; break;
      case 'CANCELLED': c = AppTheme.colorBooked; break;
      default: c = AppTheme.colorAvailable;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: c)),
    );
  }

  Widget _roleBadge(String role) {
    final r = role.toUpperCase();
    final color = r == 'DOCTOR' ? _blue : (r == 'ADMIN' ? _gold : AppTheme.primaryBright);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(r, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _roleIcon(String role) {
    final r = role.toUpperCase();
    final color = r == 'DOCTOR' ? _blue : (r == 'ADMIN' ? _gold : AppTheme.primaryBright);
    final icon = r == 'DOCTOR'
        ? Icons.medical_services_rounded
        : (r == 'ADMIN' ? Icons.admin_panel_settings_rounded : Icons.person_rounded);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }

  Widget _smallActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  Widget _emptyState(IconData icon, String label) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: Colors.grey[700]),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      ]),
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
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[600]),
        ]),
      ),
    );
  }

  Widget _modalHeader(BuildContext ctx, String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Icon(icon, color: _gold, size: 20),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: _gold)),
        ]),
        IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, {String? hint, bool numeric = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _primaryBtn(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.check, color: Colors.black),
        label: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBright,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateVal.toString());
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateVal.toString();
    }
  }
}
