import 'package:cloud_firestore/cloud_firestore.dart';

class Vitals {
  final String id;
  final String patientId;
  final DateTime date;
  final int bloodPressureSystolic;
  final int bloodPressureDiastolic;
  final int heartRate;
  final double weight;

  Vitals({
    required this.id,
    required this.patientId,
    required this.date,
    required this.bloodPressureSystolic,
    required this.bloodPressureDiastolic,
    required this.heartRate,
    required this.weight,
  });

  factory Vitals.fromMap(Map<String, dynamic> data, String documentId) {
    return Vitals(
      id: documentId,
      patientId: data['patientId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      bloodPressureSystolic: data['bloodPressureSystolic']?.toInt() ?? 120,
      bloodPressureDiastolic: data['bloodPressureDiastolic']?.toInt() ?? 80,
      heartRate: data['heartRate']?.toInt() ?? 70,
      weight: data['weight']?.toDouble() ?? 70.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'date': Timestamp.fromDate(date),
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'heartRate': heartRate,
      'weight': weight,
    };
  }
}
