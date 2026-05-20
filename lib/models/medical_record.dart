import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecord {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String diagnosis;
  final List<String> prescriptions;
  final List<String> allergies;
  final String notes;
  final DateTime? date;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.diagnosis,
    this.prescriptions = const [],
    this.allergies = const [],
    this.notes = '',
    this.date,
  });

  factory MedicalRecord.fromMap(Map<String, dynamic> data, String documentId) {
    return MedicalRecord(
      id: documentId,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      diagnosis: data['diagnosis'] ?? '',
      prescriptions: List<String>.from(data['prescriptions'] ?? []),
      allergies: List<String>.from(data['allergies'] ?? []),
      notes: data['notes'] ?? '',
      date: data['date'] != null ? (data['date'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'diagnosis': diagnosis,
      'prescriptions': prescriptions,
      'allergies': allergies,
      'notes': notes,
      'date': date != null ? Timestamp.fromDate(date!) : FieldValue.serverTimestamp(),
    };
  }
}
