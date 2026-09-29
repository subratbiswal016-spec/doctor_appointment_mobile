import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/session.dart';
import '../../services/api_service.dart';

class ManageAvailabilityScreen extends StatefulWidget {
  final String doctorId;
  const ManageAvailabilityScreen({super.key, required this.doctorId});

  @override
  State<ManageAvailabilityScreen> createState() => _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  // Mode: 0 = Weekly, 1 = Monthly, 2 = Specific date
  int _mode = 0;

  // Weekly
  final Set<int> _weekdays = {1, 3, 5}; // Mon, Wed, Fri (0=Sun..6=Sat)
  int _weeksAhead = 4;

  // Monthly
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  // Specific
  DateTime _specificDate = DateTime.now();

  // Time window
  TimeOfDay _start = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 13, minute: 0);
  int _maxPatients = 30;

  bool _saving = false;
  bool _loadingSessions = true;
  List<Session> _sessions = [];

  final _weekLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _loadingSessions = true);
    final s = await ApiService.getSessions(widget.doctorId);
    if (mounted) setState(() { _sessions = s; _loadingSessions = false; });
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '${h.toString().padLeft(2, '0')}:$m $period';
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked != null) setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _pickDate(String which) async {
    final initial = which == 'start' ? _startDate : which == 'end' ? _endDate : _specificDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (which == 'start') {
          _startDate = picked;
        } else if (which == 'end') {
          _endDate = picked;
        } else {
          _specificDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    // Basic validation
    if (_mode == 0 && _weekdays.isEmpty) {
      _snack('Pick at least one weekday');
      return;
    }
    setState(() => _saving = true);
    final df = DateFormat('yyyy-MM-dd');
    final result = await ApiService.setAvailability(
      doctorId: widget.doctorId,
      mode: _mode == 0 ? 'WEEKLY' : _mode == 1 ? 'MONTHLY' : 'SPECIFIC',
      weekdays: _mode == 0 ? _weekdays.toList() : [],
      weeksAhead: _weeksAhead,
      startDate: _mode == 1 ? df.format(_startDate) : null,
      endDate: _mode == 1 ? df.format(_endDate) : null,
      date: _mode == 2 ? df.format(_specificDate) : null,
      startTime: _fmtTime(_start),
      endTime: _fmtTime(_end),
      maxPatients: _maxPatients,
    );
    setState(() => _saving = false);
    if (!mounted) return;
    _snack(result['message'] ?? (result['success'] == true ? 'Saved' : 'Failed'),
        ok: result['success'] == true);
    if (result['success'] == true) _loadSessions();
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? AppTheme.colorAvailable : Colors.redAccent,
    ));
  }

  Future<void> _deleteSession(Session s) async {
    final ok = await ApiService.deleteSession(s.id);
    if (!mounted) return;
    _snack(ok ? 'Removed ${s.displayDate}' : 'Could not remove', ok: ok);
    if (ok) _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Manage Availability', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Repeat pattern'),
          const SizedBox(height: 8),
          _modeSelector(),
          const SizedBox(height: 18),
          if (_mode == 0) _weeklyControls(),
          if (_mode == 1) _monthlyControls(),
          if (_mode == 2) _specificControls(),
          const SizedBox(height: 18),
          _sectionTitle('Time window'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _timeBox('Start', _fmtTime(_start), () => _pickTime(true))),
              const SizedBox(width: 12),
              Expanded(child: _timeBox('End', _fmtTime(_end), () => _pickTime(false))),
            ],
          ),
          const SizedBox(height: 14),
          _sectionTitle('Max patients per day'),
          const SizedBox(height: 8),
          _maxPatientsRow(),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.save_rounded, color: Colors.black),
              label: Text(_saving ? 'Saving…' : 'Save Availability',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBright,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              _sectionTitle('Your upcoming available days'),
              const Spacer(),
              if (!_loadingSessions)
                Text('${_sessions.length}', style: const TextStyle(color: AppTheme.primaryBright, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          if (_loadingSessions)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.primaryBright)))
          else if (_sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text('No availability set yet. Add one above.', style: TextStyle(color: Colors.grey[500]))),
            )
          else
            ..._sessions.map(_sessionTile),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 1.2),
      );

  Widget _modeSelector() {
    final modes = ['Weekly', 'Monthly', 'Specific date'];
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(modes.length, (i) {
          final sel = _mode == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mode = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(modes[i],
                    style: TextStyle(
                      color: sel ? Colors.white : Colors.grey[400],
                      fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    )),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _weeklyControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Days of week'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: List.generate(7, (i) {
            final sel = _weekdays.contains(i);
            return GestureDetector(
              onTap: () => setState(() => sel ? _weekdays.remove(i) : _weekdays.add(i)),
              child: Container(
                width: 44, height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : AppTheme.cardDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: sel ? AppTheme.primaryBright : AppTheme.borderDark),
                ),
                child: Text(_weekLabels[i],
                    style: TextStyle(color: sel ? Colors.white : Colors.grey[400], fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Generate for the next'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [2, 4, 8, 12].map((w) {
            final sel = _weeksAhead == w;
            return ChoiceChip(
              label: Text('$w weeks'),
              selected: sel,
              onSelected: (_) => setState(() => _weeksAhead = w),
              selectedColor: AppTheme.primary,
              backgroundColor: AppTheme.cardDark,
              labelStyle: TextStyle(color: sel ? Colors.white : Colors.grey[300], fontWeight: FontWeight.w600),
              side: BorderSide(color: sel ? AppTheme.primaryBright : AppTheme.borderDark),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _monthlyControls() {
    final df = DateFormat('EEE, dd MMM yyyy');
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _dateBox('From', df.format(_startDate), () => _pickDate('start'))),
            const SizedBox(width: 12),
            Expanded(child: _dateBox('To', df.format(_endDate), () => _pickDate('end'))),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: _sectionTitle('Optional: only these weekdays'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: List.generate(7, (i) {
            final sel = _weekdays.contains(i);
            return GestureDetector(
              onTap: () => setState(() => sel ? _weekdays.remove(i) : _weekdays.add(i)),
              child: Container(
                width: 40, height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : AppTheme.cardDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: sel ? AppTheme.primaryBright : AppTheme.borderDark),
                ),
                child: Text(_weekLabels[i],
                    style: TextStyle(color: sel ? Colors.white : Colors.grey[400], fontWeight: FontWeight.w700, fontSize: 11)),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Leave all unselected to include every day in the range.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ),
      ],
    );
  }

  Widget _specificControls() {
    final df = DateFormat('EEE, dd MMM yyyy');
    return _dateBox('Date', df.format(_specificDate), () => _pickDate('specific'));
  }

  Widget _dateBox(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.primaryBright),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  Text(value, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeBox(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, size: 18, color: AppTheme.primaryBright),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _maxPatientsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt_rounded, size: 18, color: AppTheme.primaryBright),
          const SizedBox(width: 10),
          Text('$_maxPatients patients',
              style: GoogleFonts.jetBrainsMono(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
            onPressed: () => setState(() => _maxPatients = (_maxPatients - 5).clamp(5, 100)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryBright),
            onPressed: () => setState(() => _maxPatients = (_maxPatients + 5).clamp(5, 100)),
          ),
        ],
      ),
    );
  }

  Widget _sessionTile(Session s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded, color: AppTheme.colorAvailable, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.displayDate.isNotEmpty ? s.displayDate : s.date,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text('${s.startTime} - ${s.endTime} · ${s.maxPatients} slots',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            onPressed: () => _deleteSession(s),
          ),
        ],
      ),
    );
  }
}
