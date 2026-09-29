import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/theme/app_theme.dart';

class AppointmentTicketDialog extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentTicketDialog({
    super.key,
    required this.appointment,
  });

  static void show(BuildContext context, Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AppointmentTicketDialog(appointment: appointment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serial = appointment['serialNumber'] ?? 0;
    final status = appointment['status'] ?? 'CONFIRMED';
    final amount = appointment['amount'] ?? 0;
    final name = appointment['patientName'] ?? 'Patient';
    final age = appointment['patientAge'] ?? '';
    final gender = appointment['patientGender'] ?? '';
    final phone = appointment['patientPhone'] ?? '';
    final bookingId = appointment['_id'] ?? appointment['id'] ?? 'REF-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

    // Doctor details
    final doctorData = appointment['doctorId'];
    String doctorName = 'Doctor';
    String speciality = 'Specialist';
    String qualification = '';
    String clinicName = 'Clinic / Hospital';
    String clinicAddress = '';

    if (doctorData is Map) {
      doctorName = doctorData['name'] ?? 'Doctor';
      speciality = doctorData['speciality'] ?? 'Specialist';
      qualification = doctorData['qualification'] ?? '';
      clinicName = doctorData['clinicName'] ?? 'Clinic / Hospital';
      clinicAddress = '${doctorData['address'] ?? ''}, ${doctorData['city'] ?? ''}'.trim();
      if (clinicAddress.startsWith(',')) clinicAddress = clinicAddress.substring(1).trim();
    }

    // Session details
    final sessionData = appointment['sessionId'];
    String displayDate = 'Today';
    String timeSlot = 'Morning Session';

    if (sessionData is Map) {
      displayDate = sessionData['displayDate'] ?? sessionData['date'] ?? 'Today';
      timeSlot = '${sessionData['startTime'] ?? ''} - ${sessionData['endTime'] ?? ''}';
    }

    final serialStr = serial < 10 ? '0$serial' : '$serial';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close Button
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.cancel_rounded, color: Colors.white70, size: 28),
              ),
            ),
            const SizedBox(height: 4),

            // TICKET CONTAINER
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161C24),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderDark, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // TICKET TOP HEADER
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryWash,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.local_hospital_rounded, color: AppTheme.primaryBright, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SERIAL DOCTOR APP',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryBright,
                                            letterSpacing: 1.2,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Text(
                                          'Digital Token Ticket Pass',
                                          style: TextStyle(fontSize: 12, color: Colors.white70),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.colorAvailable.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.colorAvailable.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(
                                  color: AppTheme.colorAvailable,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // TOKEN NUMBER BIG DISPLAY
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBright.withValues(alpha: 0.15),
                                AppTheme.primaryWash,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryBright.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOKEN NUMBER',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBright,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Keep pass ready at clinic',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                              Text(
                                '#$serialStr',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryBright,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SCALLOP / CUTOUT SEPARATOR LINE
                  Stack(
                    children: [
                      Container(
                        height: 20,
                        color: const Color(0xFF161C24),
                        child: Row(
                          children: List.generate(
                            30,
                            (index) => Expanded(
                              child: Container(
                                color: index % 2 == 0 ? Colors.transparent : AppTheme.borderDark,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -10,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -10,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // TICKET BODY DETAILS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Doctor Info
                        Text(
                          doctorName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (qualification.isNotEmpty || speciality.isNotEmpty)
                          Text(
                            '$speciality${qualification.isNotEmpty ? ' ($qualification)' : ''}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                          ),
                        const SizedBox(height: 12),

                        // Clinic info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: AppTheme.primaryBright, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      clinicName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                    ),
                                    if (clinicAddress.isNotEmpty)
                                      Text(
                                        clinicAddress,
                                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Date & Time grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailBox(
                                icon: Icons.calendar_today_rounded,
                                label: 'DATE',
                                value: displayDate,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDetailBox(
                                icon: Icons.access_time_rounded,
                                label: 'TIME SLOT',
                                value: timeSlot,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Patient details
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailBox(
                                icon: Icons.person_rounded,
                                label: 'PATIENT',
                                value: name + (age.toString().isNotEmpty ? ' ($age yrs, $gender)' : ''),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDetailBox(
                                icon: Icons.payments_rounded,
                                label: 'FEE PAID',
                                value: '₹ $amount',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Dynamic Barcode / QR Simulation
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CustomPaint(
                                size: const Size(50, 50),
                                painter: _QrCodePainter(bookingId),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'BOOKING REF ID',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      bookingId.toString().toUpperCase(),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Show QR at reception desk',
                                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ACTION BUTTONS: SHARE & DOWNLOAD PDF
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _shareTicket(
                                  serial: serialStr,
                                  doctorName: doctorName,
                                  speciality: speciality,
                                  clinicName: clinicName,
                                  displayDate: displayDate,
                                  timeSlot: timeSlot,
                                  patientName: name,
                                  bookingId: bookingId,
                                ),
                                icon: const Icon(Icons.share_rounded, size: 18, color: AppTheme.primaryBright),
                                label: const Text(
                                  'Share Ticket',
                                  style: TextStyle(color: AppTheme.primaryBright, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: AppTheme.primaryBright),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _downloadPdfTicket(
                                  serial: serialStr,
                                  doctorName: doctorName,
                                  speciality: speciality,
                                  qualification: qualification,
                                  clinicName: clinicName,
                                  clinicAddress: clinicAddress,
                                  displayDate: displayDate,
                                  timeSlot: timeSlot,
                                  patientName: name,
                                  patientAge: age.toString(),
                                  patientGender: gender.toString(),
                                  patientPhone: phone.toString(),
                                  amount: amount.toString(),
                                  bookingId: bookingId.toString(),
                                  status: status,
                                ),
                                icon: const Icon(Icons.download_rounded, size: 18, color: Colors.black),
                                label: const Text(
                                  'Download PDF',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBright,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
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

  Widget _buildDetailBox({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppTheme.primaryBright),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Share Ticket summary via system share intent / WhatsApp
  static void _shareTicket({
    required String serial,
    required String doctorName,
    required String speciality,
    required String clinicName,
    required String displayDate,
    required String timeSlot,
    required String patientName,
    required String bookingId,
  }) {
    final text = '''
🏥 *SERIAL DOCTOR APPOINTMENT PASS*
━━━━━━━━━━━━━━━━━━━━━━━━━
🎟️ *TOKEN NUMBER:* #$serial
👤 *Patient:* $patientName
👨‍⚕️ *Doctor:* $doctorName ($speciality)
📍 *Clinic:* $clinicName
📅 *Date:* $displayDate
⏰ *Time:* $timeSlot
🆔 *Booking Ref:* $bookingId
━━━━━━━━━━━━━━━━━━━━━━━━━
_Booked via Serial Doctor Token Booking App_
''';
    Share.share(text, subject: 'Doctor Appointment Pass #$serial - $doctorName');
  }

  // Generate & Download / Print PDF Pass
  static Future<void> _downloadPdfTicket({
    required String serial,
    required String doctorName,
    required String speciality,
    required String qualification,
    required String clinicName,
    required String clinicAddress,
    required String displayDate,
    required String timeSlot,
    required String patientName,
    required String patientAge,
    required String patientGender,
    required String patientPhone,
    required String amount,
    required String bookingId,
    required String status,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.teal, width: 2),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SERIAL DOCTOR APP', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                        pw.Text('Official Token Appointment Pass', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.teal50,
                        border: pw.Border.all(color: PdfColors.teal),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text('TOKEN #$serial', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 10),

                // Doctor Section
                pw.Text(doctorName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                if (speciality.isNotEmpty)
                  pw.Text('$speciality ${qualification.isNotEmpty ? '($qualification)' : ''}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                pw.SizedBox(height: 6),
                pw.Text('Clinic: $clinicName', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                if (clinicAddress.isNotEmpty)
                  pw.Text(clinicAddress, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                pw.SizedBox(height: 14),

                // Grid Info
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Date: $displayDate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                          pw.Text('Time: $timeSlot', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Patient: $patientName ${patientAge.isNotEmpty ? '($patientAge yrs)' : ''}', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('Phone: $patientPhone', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Fee Paid: Rs. $amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.green800)),
                          pw.Text('Status: $status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.teal)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),

                // Footer Reference
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Booking Ref ID:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                        pw.Text(bookingId, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Text('Please arrive 10 minutes prior to time slot.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Appointment_Token_Pass_$serial.pdf',
    );
  }
}

// Custom Painter for dynamic QR code graphic look
class _QrCodePainter extends CustomPainter {
  final String text;

  _QrCodePainter(this.text);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final cellW = size.width / 7;
    final cellH = size.height / 7;

    // Corner positioning blocks
    _drawCornerBlock(canvas, paint, 0, 0, cellW, cellH);
    _drawCornerBlock(canvas, paint, 4 * cellW, 0, cellW, cellH);
    _drawCornerBlock(canvas, paint, 0, 4 * cellH, cellW, cellH);

    // Random-looking deterministic data bits from hash code
    final hash = text.hashCode;
    for (int r = 0; r < 7; r++) {
      for (int c = 0; c < 7; c++) {
        // Skip corner markers
        if ((r < 3 && c < 3) || (r < 3 && c >= 4) || (r >= 4 && c < 3)) continue;
        if (((hash >> (r * 7 + c)) & 1) == 1) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellW + 1, r * cellH + 1, cellW - 2, cellH - 2),
            paint,
          );
        }
      }
    }
  }

  void _drawCornerBlock(Canvas canvas, Paint paint, double x, double y, double cw, double ch) {
    canvas.drawRect(Rect.fromLTWH(x, y, cw * 3, ch * 3), paint);
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(x + cw, y + ch, cw, ch), whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
