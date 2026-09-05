class Session {
  final String id;
  final String doctorId;
  final String date;
  final String displayDate;
  final String startTime;
  final String endTime;
  final int maxPatients;

  Session({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.displayDate,
    required this.startTime,
    required this.endTime,
    required this.maxPatients,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['_id'] ?? json['id'] ?? '',
      doctorId: json['doctorId'] is Map ? json['doctorId']['_id'] : (json['doctorId'] ?? ''),
      date: json['date'] ?? '',
      displayDate: json['displayDate'] ?? '',
      startTime: json['startTime'] ?? '10:00 AM',
      endTime: json['endTime'] ?? '01:00 PM',
      maxPatients: json['maxPatients'] ?? 30,
    );
  }
}

class SerialToken {
  final int serialNumber;
  final String status; // AVAILABLE, HELD, BOOKED
  final String? patientName;
  final int? expiresInSeconds;

  SerialToken({
    required this.serialNumber,
    required this.status,
    this.patientName,
    this.expiresInSeconds,
  });

  factory SerialToken.fromJson(Map<String, dynamic> json) {
    return SerialToken(
      serialNumber: json['serialNumber'],
      status: json['status'],
      patientName: json['patientName'],
      expiresInSeconds: json['expiresInSeconds'],
    );
  }
}
