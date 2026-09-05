import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/doctor.dart';
import '../../models/session.dart';
import '../../services/api_service.dart';
import 'booking_success_screen.dart';

class SerialPickerScreen extends StatefulWidget {
  final Doctor doctor;
  const SerialPickerScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  State<SerialPickerScreen> createState() => _SerialPickerScreenState();
}

class _SerialPickerScreenState extends State<SerialPickerScreen> {
  List<Session> _sessions = [];
  Session? _selectedSession;
  List<SerialToken> _grid = [];
  Map<String, dynamic> _summary = {'total': 30, 'booked': 0, 'held': 0, 'available': 30};
  int? _selectedSerial;
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  Timer? _autoRefreshTimer;

  final _nameController = TextEditingController(text: 'Rahul Das');
  final _ageController = TextEditingController(text: '34');
  final _phoneController = TextEditingController(text: '9830123456');

  @override
  void initState() {
    super.initState();
    _loadSessionData();
    // Live Seat Map Auto-Refresh every 3 seconds (Movie-Ticket Style Live Updates)
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_selectedSession != null && !_isProcessingPayment && mounted) {
        _loadGrid(_selectedSession!.id, silent: true);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionData() async {
    setState(() => _isLoading = true);
    final sessions = await ApiService.getSessions(widget.doctor.id);
    if (sessions.isNotEmpty) {
      _sessions = sessions;
    } else {
      final todayStr = DateTime.now().toString().split(' ')[0];
      _sessions = [
        Session(
          id: 'default_sess_${widget.doctor.id}',
          doctorId: widget.doctor.id,
          date: todayStr,
          displayDate: 'Today',
          startTime: '10:00 AM',
          endTime: '01:00 PM',
          maxPatients: 30,
        )
      ];
    }
    _selectedSession = _sessions.first;
    await _loadGrid(_selectedSession!.id);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadGrid(String sessionId, {bool silent = false}) async {
    final result = await ApiService.getSessionGrid(sessionId);
    if (mounted) {
      setState(() {
        _summary = result['summary'] ?? _summary;
        _grid = result['grid'] ?? [];
      });
    }
  }

  void _handlePayAndConfirm() async {
    if (_selectedSerial == null || _selectedSession == null) return;

    setState(() => _isProcessingPayment = true);

    // Step 1: Request atomic serial reservation (10-min lock)
    final reserveRes = await ApiService.reserveSerial(
      sessionId: _selectedSession!.id,
      serialNumber: _selectedSerial!,
      patientName: _nameController.text,
      patientAge: int.tryParse(_ageController.text) ?? 28,
      patientGender: 'Male',
      patientPhone: _phoneController.text,
    );

    if (!reserveRes['success']) {
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ ${reserveRes['message']}'),
          backgroundColor: AppTheme.colorBooked,
        ),
      );
      _loadGrid(_selectedSession!.id);
      return;
    }

    final appointmentData = reserveRes['data']['appointment'];
    final generatedPaymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';

    // Step 2: Confirm Payment & Lock Token
    await Future.delayed(const Duration(milliseconds: 500));

    final verifySuccess = await ApiService.verifyPayment(
      appointmentId: appointmentData['id'],
      paymentId: generatedPaymentId,
    );

    setState(() => _isProcessingPayment = false);

    if (verifySuccess) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(
            doctor: widget.doctor,
            session: _selectedSession!,
            serialNumber: _selectedSerial!,
            patientName: _nameController.text,
            amount: widget.doctor.fee,
            paymentId: generatedPaymentId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Serial Token · ${widget.doctor.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBright))
          : Column(
              children: [
                // Date & Session Selector Bar
                Container(
                  color: AppTheme.surfaceDark,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _sessions.map((sess) {
                        final isSel = _selectedSession?.id == sess.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedSession = sess;
                                _selectedSerial = null;
                              });
                              _loadGrid(sess.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSel ? AppTheme.primary : AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel ? AppTheme.primaryBright : AppTheme.borderDark,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sess.displayDate,
                                    style: TextStyle(
                                      color: isSel ? Colors.white : Colors.grey[300],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${sess.startTime} - ${sess.endTime}',
                                    style: TextStyle(
                                      color: isSel ? Colors.white70 : Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Real-time Summary Counters
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryBadge('${_summary['available']} Free', AppTheme.colorAvailable),
                      _buildSummaryBadge('${_summary['held']} Held', AppTheme.colorHeld),
                      _buildSummaryBadge('${_summary['booked']} Booked', AppTheme.colorBooked),
                    ],
                  ),
                ),

                // 30-Serial Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _grid.length,
                    itemBuilder: (context, index) {
                      final token = _grid[index];
                      final isSelected = _selectedSerial == token.serialNumber;
                      return _buildSerialCell(token, isSelected);
                    },
                  ),
                ),

                // Selected Serial Action Card & Payment Confirmation Button
                if (_selectedSerial != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceDark,
                      border: Border(top: BorderSide(color: AppTheme.borderDark)),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryWash,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.primaryBright),
                              ),
                              child: Center(
                                child: Text(
                                  '#$_selectedSerial',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBright,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Serial Token #$_selectedSerial Selected',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    'Held for 10 minutes upon tapping pay',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹ ${widget.doctor.fee.toInt()}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryBright,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessingPayment ? null : _handlePayAndConfirm,
                            icon: const Icon(Icons.payment, color: Colors.black),
                            label: _isProcessingPayment
                                ? const CircularProgressIndicator(color: Colors.black)
                                : Text(
                                    'Confirm & Pay ₹ ${widget.doctor.fee.toInt()} (UPI / Card / Cash)',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBright,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSummaryBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSerialCell(SerialToken token, bool isSelected) {
    Color bg = AppTheme.cardDark;
    Color border = AppTheme.borderDark;
    Color textColor = Colors.white;

    if (token.status == 'AVAILABLE') {
      bg = AppTheme.colorAvailable.withOpacity(0.12);
      border = AppTheme.colorAvailable.withOpacity(0.4);
      textColor = AppTheme.colorAvailable;
    } else if (token.status == 'HELD') {
      bg = AppTheme.colorHeld.withOpacity(0.12);
      border = AppTheme.colorHeld.withOpacity(0.4);
      textColor = AppTheme.colorHeld;
    } else if (token.status == 'BOOKED') {
      bg = AppTheme.colorBooked.withOpacity(0.12);
      border = AppTheme.colorBooked.withOpacity(0.3);
      textColor = AppTheme.colorBooked;
    }

    if (isSelected) {
      border = AppTheme.primaryBright;
      bg = AppTheme.primaryWash;
      textColor = Colors.white;
    }

    return InkWell(
      onTap: token.status == 'AVAILABLE'
          ? () {
              setState(() {
                _selectedSerial = token.serialNumber;
              });
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: isSelected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${token.serialNumber}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              token.status == 'AVAILABLE'
                  ? 'Free'
                  : (token.status == 'HELD' ? 'Held' : 'Booked'),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
