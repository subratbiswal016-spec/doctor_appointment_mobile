import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

import 'widgets/appointment_ticket_dialog.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    final appts = await ApiService.getMyAppointments();
    if (mounted) {
      setState(() {
        _appointments = appts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBright))
          : _appointments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey[700]),
                      const SizedBox(height: 14),
                      Text(
                        'No appointments yet',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Book a token to see it here!',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primaryBright,
                  onRefresh: _loadAppointments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _appointments.length,
                    itemBuilder: (ctx, i) => _buildAppointmentCard(_appointments[i]),
                  ),
                ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    final serial = appt['serialNumber'] ?? 0;
    final status = appt['status'] ?? 'CONFIRMED';
    final amount = appt['amount'] ?? 0;
    final name = appt['patientName'] ?? 'Patient';

    // Extract doctor info
    final doctorData = appt['doctorId'];
    String doctorName = 'Doctor';
    String speciality = '';
    String clinicName = '';
    if (doctorData is Map) {
      doctorName = doctorData['name'] ?? 'Doctor';
      speciality = doctorData['speciality'] ?? '';
      clinicName = '${doctorData['clinicName'] ?? ''}, ${doctorData['city'] ?? ''}';
    }

    // Extract session info
    final sessionData = appt['sessionId'];
    String displayDate = '';
    String timeSlot = '';
    if (sessionData is Map) {
      displayDate = sessionData['displayDate'] ?? sessionData['date'] ?? '';
      timeSlot = '${sessionData['startTime'] ?? ''} - ${sessionData['endTime'] ?? ''}';
    }

    final isCompleted = status == 'COMPLETED';
    final isCancelled = status == 'CANCELLED';
    Color statusColor;
    if (isCompleted) {
      statusColor = AppTheme.primaryBright;
    } else if (isCancelled) {
      statusColor = AppTheme.colorBooked;
    } else {
      statusColor = AppTheme.colorAvailable;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => AppointmentTicketDialog.show(context, appt),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Token # and Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryWash,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryBright),
                    ),
                    child: Text(
                      'TOKEN #${serial < 10 ? '0$serial' : serial}',
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primaryBright,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Doctor name
              Text(
                doctorName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (speciality.isNotEmpty || clinicName.isNotEmpty)
                Text(
                  '${speciality.isNotEmpty ? '$speciality · ' : ''}$clinicName',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 10),

              // Date & Time
              if (displayDate.isNotEmpty || timeSlot.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppTheme.primaryBright),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$displayDate${timeSlot.isNotEmpty ? ' ($timeSlot)' : ''}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              // Patient name
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 14, color: Colors.white54),
                  const SizedBox(width: 6),
                  Text(
                    'Booked for: $name',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),

              const Divider(color: AppTheme.borderDark, height: 24),

              // Fee & Ticket Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fee Paid: ₹ $amount',
                    style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryWash,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryBright.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.confirmation_number_outlined, size: 14, color: AppTheme.primaryBright),
                        SizedBox(width: 6),
                        Text(
                          'View Ticket ➔',
                          style: TextStyle(color: AppTheme.primaryBright, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
