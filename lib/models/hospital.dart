import 'doctor.dart';

/// A "hospital" is a group of doctors that share the same clinicName.
/// Built by the backend /api/hospitals endpoint.
class Hospital {
  final String clinicName;
  final String address;
  final String city;
  final String photo;
  final double latitude;
  final double longitude;
  final int doctorCount;
  final List<String> specialities;
  final double minFee;
  final double avgRating;
  final int reviewsTotal;
  final double? distanceKm; // null when we don't have the user's location
  final List<Doctor> doctors;

  Hospital({
    required this.clinicName,
    required this.address,
    required this.city,
    required this.photo,
    required this.latitude,
    required this.longitude,
    required this.doctorCount,
    required this.specialities,
    required this.minFee,
    required this.avgRating,
    required this.reviewsTotal,
    required this.distanceKm,
    required this.doctors,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    final rawDoctors = (json['doctors'] as List?) ?? [];
    final rawSpecs = (json['specialities'] as List?) ?? [];
    return Hospital(
      clinicName: json['clinicName'] ?? 'Clinic',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      photo: json['photo'] ?? '',
      latitude: (json['latitude'] ?? 22.5726).toDouble(),
      longitude: (json['longitude'] ?? 88.3639).toDouble(),
      doctorCount: json['doctorCount'] ?? rawDoctors.length,
      specialities: rawSpecs.map((e) => e.toString()).toList(),
      minFee: (json['minFee'] ?? 0).toDouble(),
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      reviewsTotal: json['reviewsTotal'] ?? 0,
      distanceKm: json['distanceKm'] != null ? (json['distanceKm']).toDouble() : null,
      doctors: rawDoctors.map((e) => Doctor.fromJson(e)).toList(),
    );
  }

  String get distanceLabel {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) return '${(distanceKm! * 1000).round()} m away';
    return '${distanceKm!.toStringAsFixed(1)} km away';
  }
}
