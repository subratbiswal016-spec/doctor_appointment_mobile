import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/doctor.dart';
import '../booking/serial_picker_screen.dart';

class DoctorProfileScreen extends StatelessWidget {
  final Doctor doctor;
  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final d = doctor;
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _hero(context, d),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _statsRow(d),
                          const SizedBox(height: 20),
                          if (d.about.isNotEmpty) ...[
                            _sectionLabel('About'),
                            const SizedBox(height: 8),
                            Text(
                              d.about,
                              style: TextStyle(fontSize: 13.5, height: 1.5, color: Colors.grey[300]),
                            ),
                            const SizedBox(height: 20),
                          ],
                          if (d.languages.isNotEmpty) ...[
                            _sectionLabel('Languages'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: d.languages.map((l) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDark,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.borderDark),
                                ),
                                child: Text(l, style: const TextStyle(fontSize: 12, color: Colors.white)),
                              )).toList(),
                            ),
                            const SizedBox(height: 20),
                          ],
                          _sectionLabel('Clinic & Location'),
                          const SizedBox(height: 8),
                          _infoTile(Icons.local_hospital_rounded, d.clinicName, d.address.isNotEmpty ? d.address : d.city),
                          if (d.distanceKm != null)
                            _infoTile(Icons.near_me_rounded, '${d.distanceLabel} away', 'Approx. distance from your selected location'),
                          const SizedBox(height: 16),
                          _sectionLabel('Verification'),
                          const SizedBox(height: 8),
                          _infoTile(Icons.verified_user_rounded, 'Reg. No: ${d.registrationNumber}', 'Verified medical professional'),
                          if (d.email.isNotEmpty)
                            _infoTile(Icons.email_rounded, d.email, 'Contact email'),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _bottomBar(context, d),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, Doctor d) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF091312)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryWash,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryBright.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                    const SizedBox(width: 4),
                    Text('${d.rating}  ·  ${d.reviewsCount} reviews',
                        style: const TextStyle(color: AppTheme.primaryBright, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryBright, width: 2.5),
                  boxShadow: [BoxShadow(color: AppTheme.primaryBright.withValues(alpha: 0.35), blurRadius: 16)],
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: AppTheme.cardDark,
                  backgroundImage: NetworkImage(d.photo),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(d.name,
                              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: AppTheme.primaryBright, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(d.speciality,
                        style: const TextStyle(color: AppTheme.primaryBright, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(d.qualification,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12.5),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsRow(Doctor d) {
    return Row(
      children: [
        Expanded(child: _statCard(Icons.work_history_rounded, '${d.experienceYears}+ yrs', 'Experience')),
        const SizedBox(width: 10),
        Expanded(child: _statCard(Icons.star_rounded, '${d.rating}', 'Rating')),
        const SizedBox(width: 10),
        Expanded(child: _statCard(Icons.currency_rupee_rounded, '${d.fee.toInt()}', 'Fee')),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryBright, size: 20),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t) => Text(
        t,
        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
      );

  Widget _infoTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBright, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context, Doctor d) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(top: BorderSide(color: AppTheme.borderDark)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Consultation Fee', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              Text('₹ ${d.fee.toInt()}',
                  style: GoogleFonts.jetBrainsMono(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryBright)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SerialPickerScreen(doctor: d)));
              },
              icon: const Icon(Icons.confirmation_number_rounded, color: Colors.black, size: 20),
              label: const Text('Book Appointment',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBright,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
