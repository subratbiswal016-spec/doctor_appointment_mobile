class Doctor {
  final String id;
  final String name;
  final String photo;
  final String qualification;
  final String speciality;
  final int experienceYears;
  final String registrationNumber;
  final double fee;
  final String clinicName;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewsCount;
  final String about;
  final String email;
  final List<String> languages;
  final bool isVerified;
  final double? distanceKm;

  Doctor({
    required this.id,
    required this.name,
    required this.photo,
    required this.qualification,
    required this.speciality,
    required this.experienceYears,
    required this.registrationNumber,
    required this.fee,
    required this.clinicName,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewsCount,
    this.about = '',
    this.email = '',
    this.languages = const [],
    this.isVerified = true,
    this.distanceKm,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      photo: json['photo'] ?? 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=400&q=80',
      qualification: json['qualification'] ?? '',
      speciality: json['speciality'] ?? '',
      experienceYears: json['experienceYears'] ?? 10,
      registrationNumber: json['registrationNumber'] ?? '',
      fee: (json['fee'] ?? 500).toDouble(),
      clinicName: json['clinicName'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? 'Kolkata',
      latitude: (json['latitude'] ?? 22.5726).toDouble(),
      longitude: (json['longitude'] ?? 88.3639).toDouble(),
      rating: (json['rating'] ?? 4.9).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 100,
      about: json['about'] ?? '',
      email: json['email'] ?? '',
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      isVerified: json['isVerified'] ?? true,
      distanceKm: json['distanceKm'] != null ? (json['distanceKm']).toDouble() : null,
    );
  }

  String get distanceLabel {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) return '${(distanceKm! * 1000).round()} m';
    return '${distanceKm!.toStringAsFixed(1)} km';
  }
}
