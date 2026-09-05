import 'package:geolocator/geolocator.dart';

/// Wraps GPS access with graceful fallback.
/// If permission is denied or GPS is off, returns null and callers fall back
/// to the manual area/city selection.
class LocationService {
  /// Default fallback location (Kolkata city center) used when GPS is unavailable.
  static const double fallbackLat = 22.5726;
  static const double fallbackLng = 88.3639;

  /// Tries to get the current device position.
  /// Returns null if location services are disabled or permission is denied.
  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
