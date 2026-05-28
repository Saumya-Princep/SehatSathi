import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionItem {
  final String id;
  final String name;
  final String dosage;
  final int quantity;
  final bool isDispensed;

  PrescriptionItem({
    required this.id,
    required this.name,
    required this.dosage,
    required this.quantity,
    this.isDispensed = false,
  });

  factory PrescriptionItem.fromMap(Map<String, dynamic> map) {
    return PrescriptionItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      isDispensed: map['isDispensed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'quantity': quantity,
      'isDispensed': isDispensed,
    };
  }

  PrescriptionItem copyWith({
    String? id,
    String? name,
    String? dosage,
    int? quantity,
    bool? isDispensed,
  }) {
    return PrescriptionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      quantity: quantity ?? this.quantity,
      isDispensed: isDispensed ?? this.isDispensed,
    );
  }
}

class MedicalRecord {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String diagnosis;
  final List<PrescriptionItem> prescriptions;
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
      prescriptions: (data['prescriptions'] as List?)?.map((p) {
            if (p is Map) {
              return PrescriptionItem.fromMap(Map<String, dynamic>.from(p));
            } else {
              return PrescriptionItem(
                id: p.toString(),
                name: p.toString(),
                dosage: 'As prescribed',
                quantity: 1,
                isDispensed: true,
              );
            }
          }).toList() ??
          [],
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
      'prescriptions': prescriptions.map((p) => p.toMap()).toList(),
      'allergies': allergies,
      'notes': notes,
      'date': date != null ? Timestamp.fromDate(date!) : FieldValue.serverTimestamp(),
    };
  }
}
