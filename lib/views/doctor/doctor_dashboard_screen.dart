import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'manage_availability_screen.dart';
import 'edit_doctor_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const DoctorDashboardScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic>? _doctorProfile;
  List<dynamic> _todayQueue = [];
  List<dynamic> _todaySessions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    if (widget.doctorId.isNotEmpty) {
      final data = await ApiService.getDoctorDashboard(widget.doctorId);
      if (mounted) {
        setState(() {
          _doctorProfile = data['doctorProfile'];
          _stats = data['stats'] ?? {};
          _todayQueue = data['todayQueue'] ?? [];
          _todaySessions = data['todaySessions'] ?? [];
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryBright,
          onRefresh: _loadData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBright))
              : CustomScrollView(
                  slivers: [
                    // ────── Header ──────
                    SliverToBoxAdapter(child: _buildHeader()),
                    // ────── Stat Cards ──────
                    SliverToBoxAdapter(child: _buildStatCards()),
                    // ────── Quick Actions ──────
                    SliverToBoxAdapter(child: _buildQuickActions()),
                    // ────── Today's Sessions ──────
                    SliverToBoxAdapter(child: _buildSessionsSection()),
                    // ────── Patient Queue ──────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, color: Color(0xFF4DA6FF), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Today\'s Patient Queue',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryWash,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_todayQueue.length} patients',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryBright,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_todayQueue.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey[700]),
                              const SizedBox(height: 12),
                              Text(
                                'No patients booked yet today',
                                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, index) => _buildQueueCard(_todayQueue[index], index),
                          childCount: _todayQueue.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final photo = _doctorProfile?['photo'] ?? 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=400&q=80';
    final name = _doctorProfile?['name'] ?? (widget.doctorName.isNotEmpty ? widget.doctorName : 'Doctor');
    final speciality = _doctorProfile?['speciality'] ?? 'Specialist';
    final qual = _doctorProfile?['qualification'] ?? 'MBBS, MD';
    final clinic = _doctorProfile?['clinicName'] ?? '';
    final city = _doctorProfile?['city'] ?? '';
    final fee = _doctorProfile?['fee'] ?? 700;
    final regNum = _doctorProfile?['registrationNumber'] ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF091312)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Doctor Profile Photo Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4DA6FF), width: 2),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF4DA6FF).withValues(alpha: 0.3), blurRadius: 10),
                  ],
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primaryWash,
                  backgroundImage: NetworkImage(photo),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: Color(0xFF4DA6FF), size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$speciality · $qual',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF4DA6FF), fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (clinic.isNotEmpty)
                      Text(
                        '$clinic${city.isNotEmpty ? ', $city' : ''} · Fee: ₹$fee',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                onPressed: _loadData,
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                onPressed: () async {
                  await ApiService.clearSession();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
          if (regNum.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 12, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    'Reg. No: $regNum',
                    style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              icon: Icons.event_available_rounded,
              label: 'Manage Availability',
              onTap: () {
                if (widget.doctorId.isEmpty) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ManageAvailabilityScreen(doctorId: widget.doctorId)),
                ).then((_) => _loadData());
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionButton(
              icon: Icons.edit_location_alt_rounded,
              label: 'Edit Details',
              onTap: () {
                if (widget.doctorId.isEmpty) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditDoctorScreen(doctorId: widget.doctorId, profile: _doctorProfile)),
                ).then((_) => _loadData());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryWash,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primaryBright.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primaryBright, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: AppTheme.primaryBright, fontWeight: FontWeight.w700, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    final todayBooked = _stats['todayBooked'] ?? 0;
    final todayMax = _stats['todayMax'] ?? 0;
    final todayRevenue = _stats['todayRevenue'] ?? 0;
    final totalPatients = _stats['totalPatients'] ?? 0;
    final totalRevenue = _stats['totalRevenue'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          // Top row: Today's bookings + Today's revenue
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.confirmation_number_rounded,
                  iconColor: AppTheme.colorAvailable,
                  label: 'Today Booked',
                  value: '$todayBooked / $todayMax',
                  bgColor: const Color(0xFF0A2A1A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.currency_rupee_rounded,
                  iconColor: AppTheme.primaryBright,
                  label: 'Today Revenue',
                  value: '₹ $todayRevenue',
                  bgColor: const Color(0xFF0A2520),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom row: All-time patients + All-time revenue
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.people_rounded,
                  iconColor: const Color(0xFF4DA6FF),
                  label: 'Total Patients',
                  value: '$totalPatients',
                  bgColor: const Color(0xFF0D1D2A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFFE0AE4E),
                  label: 'Total Earned',
                  value: '₹ $totalRevenue',
                  bgColor: const Color(0xFF2A2000),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsSection() {
    if (_todaySessions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY\'S SESSIONS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          ..._todaySessions.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: AppTheme.primaryBright, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${s['startTime'] ?? ''} - ${s['endTime'] ?? ''}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryWash,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${s['maxPatients'] ?? 30} slots',
                        style: const TextStyle(fontSize: 11, color: AppTheme.primaryBright, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildQueueCard(dynamic patient, int index) {
    final serial = patient['serialNumber'] ?? 0;
    final name = patient['patientName'] ?? 'Patient';
    final age = patient['patientAge'] ?? 0;
    final gender = patient['patientGender'] ?? '';
    final phone = patient['patientPhone'] ?? '';
    final status = patient['status'] ?? 'CONFIRMED';
    final amount = patient['amount'] ?? 0;

    Color statusColor;
    switch (status) {
      case 'COMPLETED':
        statusColor = AppTheme.primaryBright;
        break;
      case 'ARRIVED':
        statusColor = const Color(0xFF4DA6FF);
        break;
      default:
        statusColor = AppTheme.colorAvailable;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          // Serial badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: Text(
              '#${serial < 10 ? '0$serial' : serial}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Patient info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$gender · Age $age · $phone',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹$amount',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryBright,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
