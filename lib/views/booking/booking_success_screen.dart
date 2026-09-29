import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/doctor.dart';
import '../../models/session.dart';
import '../appointments/my_appointments_screen.dart';
import '../appointments/widgets/appointment_ticket_dialog.dart';

class BookingSuccessScreen extends StatelessWidget {
  final Doctor doctor;
  final Session session;
  final int serialNumber;
  final String patientName;
  final double amount;
  final String paymentId;

  const BookingSuccessScreen({
    Key? key,
    required this.doctor,
    required this.session,
    required this.serialNumber,
    required this.patientName,
    required this.amount,
    required this.paymentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Animated Icon
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryWash,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 50, color: AppTheme.primaryBright),
              ),
              const SizedBox(height: 16),
              Text(
                'Booking Confirmed!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Payment of ₹ ${amount.toInt()} verified successfully',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              const SizedBox(height: 28),

              // Digital Serial Pass / Ticket
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderDark),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Ticket Header with Big Serial Number
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'YOUR SERIAL TOKEN',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBright,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                patientName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryWash,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.primaryBright),
                            ),
                            child: Text(
                              '#$serialNumber',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryBright,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: AppTheme.borderDark, height: 1),

                    // Ticket Body Details
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildTicketRow('Doctor', doctor.name),
                          const SizedBox(height: 12),
                          _buildTicketRow('Specialty', doctor.speciality),
                          const SizedBox(height: 12),
                          _buildTicketRow('Clinic', doctor.clinicName),
                          const SizedBox(height: 12),
                          _buildTicketRow('Date & Time', '${session.displayDate}\n${session.startTime} - ${session.endTime}'),
                          const SizedBox(height: 12),
                          _buildTicketRow('Payment Ref', paymentId),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final appt = {
                      'serialNumber': serialNumber,
                      'status': 'CONFIRMED',
                      'amount': amount,
                      'patientName': patientName,
                      '_id': paymentId,
                      'doctorId': {
                        'name': doctor.name,
                        'speciality': doctor.speciality,
                        'qualification': doctor.qualification,
                        'clinicName': doctor.clinicName,
                        'address': doctor.address,
                        'city': doctor.city,
                      },
                      'sessionId': {
                        'displayDate': session.displayDate,
                        'startTime': session.startTime,
                        'endTime': session.endTime,
                      },
                    };
                    AppointmentTicketDialog.show(context, appt);
                  },
                  icon: const Icon(Icons.confirmation_number_outlined, color: AppTheme.primaryBright),
                  label: const Text(
                    'View & Download Ticket Pass (PDF)',
                    style: TextStyle(color: AppTheme.primaryBright, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryBright),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBright,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Go to My Appointments ➔',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
