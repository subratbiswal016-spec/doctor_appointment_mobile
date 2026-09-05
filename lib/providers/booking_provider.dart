import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../models/session.dart';
import '../services/api_service.dart';

class BookingProvider extends ChangeNotifier {
  List<Doctor> _doctors = [];
  bool _isLoading = false;
  Doctor? _selectedDoctor;
  Session? _selectedSession;
  SerialToken? _selectedToken;

  List<Doctor> get doctors => _doctors;
  bool get isLoading => _isLoading;
  Doctor? get selectedDoctor => _selectedDoctor;
  Session? get selectedSession => _selectedSession;
  SerialToken? get selectedToken => _selectedToken;

  Future<void> fetchDoctors({String search = '', String speciality = 'All'}) async {
    _isLoading = true;
    notifyListeners();
    _doctors = await ApiService.getDoctors(search: search, speciality: speciality);
    _isLoading = false;
    notifyListeners();
  }

  void selectDoctor(Doctor doctor) {
    _selectedDoctor = doctor;
    _selectedSession = null;
    _selectedToken = null;
    notifyListeners();
  }

  void selectSession(Session session) {
    _selectedSession = session;
    _selectedToken = null;
    notifyListeners();
  }

  void selectToken(SerialToken token) {
    _selectedToken = token;
    notifyListeners();
  }
}
