class Appointment {
  final String id;
  final int serialNumber;
  final String doctorName;
  final String doctorSpeciality;
  final String clinicName;
  final String address;
  final String sessionDisplayDate;
  final String sessionTime;
  final String patientName;
  final String patientPhone;
  final String status;
  final double amount;
  final String paymentId;
  final String? pdfUrl;

  Appointment({
    required this.id,
    required this.serialNumber,
    required this.doctorName,
    required this.doctorSpeciality,
    required this.clinicName,
    required this.address,
    required this.sessionDisplayDate,
    required this.sessionTime,
    required this.patientName,
    required this.patientPhone,
    required this.status,
    required this.amount,
    required this.paymentId,
    this.pdfUrl,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final doc = json['doctorId'] is Map ? json['doctorId'] : {};
    final sess = json['sessionId'] is Map ? json['sessionId'] : {};

    return Appointment(
      id: json['_id'] ?? json['id'] ?? '',
      serialNumber: json['serialNumber'] ?? 1,
      doctorName: doc['name'] ?? json['doctorName'] ?? 'Dr. Doctor',
      doctorSpeciality: doc['speciality'] ?? 'Specialist',
      clinicName: doc['clinicName'] ?? json['clinicName'] ?? 'Clinic',
      address: doc['address'] ?? json['address'] ?? '',
      sessionDisplayDate: sess['displayDate'] ?? json['sessionDisplayDate'] ?? 'Today',
      sessionTime: sess['startTime'] != null ? '${sess['startTime']} - ${sess['endTime']}' : (json['sessionTime'] ?? '10:00 AM'),
      patientName: json['patientName'] ?? 'Patient',
      patientPhone: json['patientPhone'] ?? '',
      status: json['status'] ?? 'CONFIRMED',
      amount: (json['amount'] ?? 500).toDouble(),
      paymentId: json['paymentId'] ?? json['razorpayPaymentId'] ?? 'pay_sample',
      pdfUrl: json['pdfUrl'],
    );
  }
}
