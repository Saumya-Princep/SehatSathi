import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { patient, doctor, pharmacist, admin }

class UserModel {
  final String uid;
  final String name;
  final UserRole role;
  final String? assignedPhcId;
  final String? contact;
  final String? doctorRegistrationId;
  final String? hospitalRegistrationNumber;
  final String? pharmacistRegistrationNumber;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.role,
    this.assignedPhcId,
    this.contact,
    this.doctorRegistrationId,
    this.hospitalRegistrationNumber,
    this.pharmacistRegistrationNumber,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      name: data['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.patient,
      ),
      assignedPhcId: data['assignedPhcId'],
      contact: data['contact'],
      doctorRegistrationId: data['doctorRegistrationId'],
      hospitalRegistrationNumber: data['hospitalRegistrationNumber'],
      pharmacistRegistrationNumber: data['pharmacistRegistrationNumber'],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role.name,
      'assignedPhcId': assignedPhcId,
      'contact': contact,
      'doctorRegistrationId': doctorRegistrationId,
      'hospitalRegistrationNumber': hospitalRegistrationNumber,
      'pharmacistRegistrationNumber': pharmacistRegistrationNumber,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
