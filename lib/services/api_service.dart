import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/doctor.dart';
import '../models/session.dart';
import '../models/hospital.dart';

class ApiService {
  static String? _activeBaseUrl;
  static String? _authToken;

  // Currently logged-in user (set at login, used by the Profile screen)
  static Map<String, dynamic>? currentUser;

  // Candidate host URLs for Android Emulator, LAN IP, and Desktop/Web
  static List<String> get candidateBaseUrls {
    return [
      'https://doctor-appointment-backend-rype.onrender.com/api',
      'http://127.0.0.1:5000/api',
      'http://localhost:5000/api',
      'http://192.168.0.220:5000/api',
      'http://10.0.2.2:5000/api',
    ];
  }

  static String get baseUrl => _activeBaseUrl ?? candidateBaseUrls.first;

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  static void setToken(String token) {
    _authToken = token;
  }

  static Future<void> saveSession({
    required String token,
    required String role,
    required Map<String, dynamic> user,
    String? doctorId,
    String? doctorName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_role', role);
    await prefs.setString('auth_user', json.encode(user));
    if (doctorId != null) await prefs.setString('auth_doctorId', doctorId);
    if (doctorName != null) await prefs.setString('auth_doctorName', doctorName);
    _authToken = token;
    currentUser = user;
  }

  static Future<Map<String, dynamic>?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final role = prefs.getString('auth_role');
    final userStr = prefs.getString('auth_user');
    if (token == null || role == null || userStr == null) return null;

    _authToken = token;
    final user = json.decode(userStr) as Map<String, dynamic>;
    currentUser = user;
    return {
      'token': token,
      'role': role,
      'user': user,
      'doctorId': prefs.getString('auth_doctorId') ?? user['doctorId'] ?? '',
      'doctorName': prefs.getString('auth_doctorName') ?? user['name'] ?? '',
      'profileComplete': user['profileComplete'] ?? false,
    };
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_role');
    await prefs.remove('auth_user');
    await prefs.remove('auth_doctorId');
    await prefs.remove('auth_doctorName');
    _authToken = null;
    currentUser = null;
  }

  // Helper for resilient GET requests with working IP caching
  static Future<http.Response?> safeGet(String endpointPath, {int timeoutSeconds = 3}) async {
    if (_activeBaseUrl != null) {
      try {
        final uri = Uri.parse('$_activeBaseUrl$endpointPath');
        final response = await http.get(uri, headers: headers).timeout(Duration(seconds: timeoutSeconds));
        return response;
      } catch (_) {
        _activeBaseUrl = null;
      }
    }

    for (final base in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$base$endpointPath');
        final response = await http.get(uri, headers: headers).timeout(Duration(seconds: timeoutSeconds));
        _activeBaseUrl = base;
        return response;
      } catch (_) {}
    }
    return null;
  }

  // Helper for resilient POST requests with working IP caching
  static Future<http.Response?> safePost(String endpointPath, String body, {int timeoutSeconds = 3}) async {
    if (_activeBaseUrl != null) {
      try {
        final uri = Uri.parse('$_activeBaseUrl$endpointPath');
        final response = await http.post(uri, headers: headers, body: body).timeout(Duration(seconds: timeoutSeconds));
        return response;
      } catch (_) {
        _activeBaseUrl = null;
      }
    }

    for (final base in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$base$endpointPath');
        final response = await http.post(uri, headers: headers, body: body).timeout(Duration(seconds: timeoutSeconds));
        _activeBaseUrl = base;
        return response;
      } catch (_) {}
    }
    return null;
  }

  // Helper for resilient PATCH requests
  static Future<http.Response?> safePatch(String endpointPath, String body, {int timeoutSeconds = 4}) async {
    if (_activeBaseUrl != null) {
      try {
        final uri = Uri.parse('$_activeBaseUrl$endpointPath');
        final response = await http.patch(uri, headers: headers, body: body).timeout(Duration(seconds: timeoutSeconds));
        return response;
      } catch (_) {
        _activeBaseUrl = null;
      }
    }

    for (final base in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$base$endpointPath');
        final response = await http.patch(uri, headers: headers, body: body).timeout(Duration(seconds: timeoutSeconds));
        _activeBaseUrl = base;
        return response;
      } catch (_) {}
    }
    return null;
  }

  // Helper for resilient DELETE requests
  static Future<http.Response?> safeDelete(String endpointPath, {int timeoutSeconds = 4}) async {
    if (_activeBaseUrl != null) {
      try {
        final uri = Uri.parse('$_activeBaseUrl$endpointPath');
        final response = await http.delete(uri, headers: headers).timeout(Duration(seconds: timeoutSeconds));
        return response;
      } catch (_) {
        _activeBaseUrl = null;
      }
    }

    for (final base in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$base$endpointPath');
        final response = await http.delete(uri, headers: headers).timeout(Duration(seconds: timeoutSeconds));
        _activeBaseUrl = base;
        return response;
      } catch (_) {}
    }
    return null;
  }

  // ────── AUTH ENDPOINTS ──────

  static Future<Map<String, dynamic>> sendOtp({required String phone}) async {
    try {
      final body = json.encode({'phone': phone});
      final response = await safePost('/auth/send-otp', body);
      if (response != null) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] == true,
          'hasPassword': data['hasPassword'] == true,
          'message': data['message'] ?? '',
        };
      }
      return {'success': false, 'hasPassword': false, 'message': 'Cannot connect to server'};
    } catch (e) {
      return {'success': false, 'hasPassword': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
    required String role,
  }) async {
    try {
      final body = json.encode({'phone': phone, 'otp': otp, 'role': role});
      final response = await safePost('/auth/verify-otp', body);
      if (response != null) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _authToken = data['token'];
          currentUser = data['user'];
          return {
            'success': true,
            'role': data['role'] ?? role,
            'token': data['token'],
            'user': data['user'],
            'isNewUser': data['isNewUser'] ?? false,
            'profileComplete': data['profileComplete'] ?? false,
            'doctorId': data['user']?['doctorId'] ?? data['doctorProfile']?['_id'] ?? '',
            'doctorName': data['doctorProfile']?['name'] ?? data['user']?['name'] ?? '',
          };
        }
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
      return {'success': false, 'message': 'Cannot connect to server'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> setPassword({
    required String phone,
    required String password,
  }) async {
    try {
      final body = json.encode({'phone': phone, 'password': password});
      final response = await safePost('/auth/set-password', body);
      if (response != null) {
        final data = json.decode(response.body);
        return {'success': data['success'] == true, 'message': data['message'] ?? ''};
      }
      return {'success': false, 'message': 'Cannot connect to server'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> loginWithPassword({
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      final body = json.encode({'phone': phone, 'password': password, 'role': role});
      final response = await safePost('/auth/login-password', body);
      if (response != null) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _authToken = data['token'];
          currentUser = data['user'];
          final resultRole = data['role'] ?? role;
          final doctorId = data['user']?['doctorId'] ?? data['doctorProfile']?['_id'] ?? '';
          final doctorName = data['doctorProfile']?['name'] ?? data['user']?['name'] ?? '';
          await saveSession(
            token: data['token'],
            role: resultRole,
            user: Map<String, dynamic>.from(data['user'] ?? {}),
            doctorId: doctorId,
            doctorName: doctorName,
          );
          return {
            'success': true,
            'role': resultRole,
            'token': data['token'],
            'user': data['user'],
            'isNewUser': false,
            'profileComplete': data['profileComplete'] ?? false,
            'doctorId': doctorId,
            'doctorName': doctorName,
          };
        }
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
      return {'success': false, 'message': 'Cannot connect to server'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ────── PROFILE UPDATE ──────

  static Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String name,
    required int age,
    required String gender,
    required String role,
    Map<String, dynamic>? doctorData,
  }) async {
    try {
      final body = json.encode({
        'userId': userId,
        'name': name,
        'age': age,
        'gender': gender,
        'role': role,
        if (doctorData != null) 'doctorData': doctorData,
      });
      final response = await safePost('/auth/update-profile', body);
      if (response != null) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          currentUser = data['user'];
          return {
            'success': true,
            'user': data['user'],
            'doctorId': data['user']?['doctorId'] ?? data['doctorProfile']?['_id'] ?? '',
          };
        }
        return {'success': false, 'message': data['message'] ?? 'Update failed'};
      }
      return {'success': false, 'message': 'Cannot connect to server'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await safeGet('/auth/users');
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['users'] ?? [];
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  // ────── DOCTOR ENDPOINTS ──────

  static Future<List<Doctor>> getDoctors({String search = '', String speciality = 'All', String city = '', double? lat, double? lng}) async {
    try {
      var path = '/doctors?search=${Uri.encodeComponent(search)}&speciality=${Uri.encodeComponent(speciality)}';
      if (city.isNotEmpty && city != 'All') {
        path += '&city=${Uri.encodeComponent(city)}';
      } else if (lat != null && lng != null) {
        path += '&lat=$lat&lng=$lng';
      }
      final response = await safeGet(path);
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['doctors'] ?? [];
        return list.map((e) => Doctor.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ────── HOSPITALS (nearby, grouped by clinic) ──────

  static Future<List<Hospital>> getNearbyHospitals({double? lat, double? lng, String search = ''}) async {
    try {
      var path = '/hospitals?search=${Uri.encodeComponent(search)}';
      if (lat != null && lng != null) {
        path += '&lat=$lat&lng=$lng';
      }
      final response = await safeGet(path);
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['hospitals'] ?? [];
        return list.map((e) => Hospital.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // Geocode a typed place -> list of {name, lat, lng}
  static Future<List<Map<String, dynamic>>> geocode(String query) async {
    try {
      final response = await safeGet('/hospitals/geocode?q=${Uri.encodeComponent(query)}', timeoutSeconds: 10);
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['results'] ?? [];
        return list.map((e) => {
          'name': e['name'] ?? '',
          'lat': (e['lat'] ?? 0).toDouble(),
          'lng': (e['lng'] ?? 0).toDouble(),
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  // ────── DOCTOR AVAILABILITY (doctor self-service) ──────

  static Future<Map<String, dynamic>> setAvailability({
    required String doctorId,
    required String mode, // 'WEEKLY' | 'MONTHLY' | 'SPECIFIC'
    List<int> weekdays = const [],
    int weeksAhead = 4,
    String? startDate,
    String? endDate,
    String? date,
    required String startTime,
    required String endTime,
    int maxPatients = 30,
  }) async {
    try {
      final body = json.encode({
        'mode': mode,
        'weekdays': weekdays,
        'weeksAhead': weeksAhead,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (date != null) 'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'maxPatients': maxPatients,
      });
      final response = await safePost('/doctors/$doctorId/availability', body, timeoutSeconds: 8);
      if (response != null) {
        final data = json.decode(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          return {'success': true, 'data': data, 'message': data['message'] ?? 'Availability saved'};
        }
        return {'success': false, 'message': data['message'] ?? 'Failed to save availability'};
      }
      return {'success': false, 'message': 'Cannot connect to server'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<bool> updateDoctor(String doctorId, Map<String, dynamic> data) async {
    try {
      final response = await safePatch('/doctors/$doctorId', json.encode(data));
      return response != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteSession(String sessionId) async {
    try {
      final response = await safeDelete('/doctors/session/$sessionId');
      return response != null;
    } catch (_) {
      return false;
    }
  }

  static Future<List<String>> getSpecialities() async {
    try {
      final response = await safeGet('/doctors/specialities');
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['specialities'] ?? [];
        return list.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return ['All', 'Cardiologist', 'Dermatologist', 'General Physician', 'Pediatrician', 'Neurologist', 'Orthopedic', 'Gynecologist', 'ENT', 'Dentist'];
  }

  static Future<List<Session>> getSessions(String doctorId) async {
    try {
      final response = await safeGet('/doctors/$doctorId/sessions');
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['sessions'] ?? [];
        return list.map((e) => Session.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> getSessionGrid(String sessionId) async {
    try {
      final response = await safeGet('/doctors/session/$sessionId/grid');
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final List rawGrid = data['serialGrid'] ?? [];
        final List<SerialToken> grid = rawGrid.map((e) => SerialToken.fromJson(e)).toList();
        return {
          'summary': data['summary'] ?? {'total': 30, 'booked': 0, 'held': 0, 'available': 30},
          'grid': grid,
        };
      }
    } catch (_) {}

    List<SerialToken> emptyGrid = List.generate(
      30,
      (i) => SerialToken(serialNumber: i + 1, status: 'AVAILABLE'),
    );
    return {
      'summary': {'total': 30, 'booked': 0, 'held': 0, 'available': 30},
      'grid': emptyGrid,
    };
  }

  // ────── BOOKING ENDPOINTS ──────

  static Future<Map<String, dynamic>> reserveSerial({
    required String sessionId,
    required int serialNumber,
    required String patientName,
    required int patientAge,
    required String patientGender,
    required String patientPhone,
  }) async {
    try {
      final user = currentUser ?? {};
      final body = json.encode({
        'sessionId': sessionId,
        'serialNumber': serialNumber,
        'patientName': patientName.isNotEmpty ? patientName : (user['name'] ?? 'Patient'),
        'patientAge': patientAge > 0 ? patientAge : (user['age'] ?? 28),
        'patientGender': patientGender.isNotEmpty ? patientGender : (user['gender'] ?? 'Male'),
        'patientPhone': patientPhone.isNotEmpty ? patientPhone : (user['phone'] ?? ''),
      });
      final response = await safePost('/bookings/reserve', body, timeoutSeconds: 6);
      if (response != null) {
        final data = json.decode(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          return {'success': true, 'data': data};
        } else {
          return {'success': false, 'message': data['message'] ?? 'Serial already held'};
        }
      }
      return {'success': false, 'message': 'Network connection error'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<bool> verifyPayment({
    required String appointmentId,
    String? paymentId,
  }) async {
    try {
      final body = json.encode({
        'appointmentId': appointmentId,
        'paymentId': paymentId ?? 'pay_${DateTime.now().millisecondsSinceEpoch}',
      });
      final response = await safePost('/payments/verify', body);
      return response != null && response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ────── PATIENT APPOINTMENTS ──────

  static Future<List<Map<String, dynamic>>> getMyAppointments() async {
    try {
      final response = await safeGet('/bookings/my-appointments');
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['appointments'] ?? [];
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  // ────── DOCTOR DASHBOARD ──────

  static Future<Map<String, dynamic>> getDoctorDashboard(String doctorId) async {
    try {
      final response = await safeGet('/doctors/$doctorId/dashboard');
      if (response != null && response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return {
      'success': false,
      'stats': {'todayBooked': 0, 'todayMax': 0, 'todayRevenue': 0, 'totalPatients': 0, 'totalRevenue': 0},
      'todaySessions': [],
      'todayQueue': [],
    };
  }

  // ────── ADMIN ENDPOINTS ──────

  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await safeGet('/doctors/admin/stats');
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['stats'] ?? {};
      }
    } catch (_) {}
    return {'activeDoctors': 0, 'totalUsers': 0, 'totalSessions': 0, 'bookedTokens': 0, 'totalRevenue': 0, 'todayBooked': 0, 'todayRevenue': 0};
  }

  static Future<List<Map<String, dynamic>>> getAllAppointments() async {
    try {
      final response = await safeGet('/doctors/admin/appointments');
      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['appointments'] ?? [];
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> createDoctor(Map<String, dynamic> doctorData) async {
    try {
      final response = await safePost('/doctors/admin/create', json.encode(doctorData));
      return response != null && (response.statusCode == 200 || response.statusCode == 201);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> createSession(Map<String, dynamic> sessionData) async {
    try {
      final response = await safePost('/doctors/admin/session', json.encode(sessionData));
      return response != null && (response.statusCode == 200 || response.statusCode == 201);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> adminDeleteDoctor(String doctorId) async {
    try {
      final response = await safeDelete('/doctors/admin/doctor/$doctorId');
      return response != null && response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> adminDeleteUser(String userId) async {
    try {
      final response = await safeDelete('/doctors/admin/user/$userId');
      return response != null && response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> adminUpdateBooking(String bookingId, Map<String, dynamic> updates) async {
    try {
      final response = await safePatch('/doctors/admin/booking/$bookingId', json.encode(updates));
      return response != null && response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> adminDeleteBooking(String bookingId) async {
    try {
      final response = await safeDelete('/doctors/admin/booking/$bookingId');
      return response != null && response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> adminUpdateUser(String userId, Map<String, dynamic> updates) async {
    try {
      final response = await safePatch('/doctors/admin/user/$userId', json.encode(updates));
      return response != null && response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
