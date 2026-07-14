import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { patient, doctor, pharmacist, admin, lab_technician }

class UserModel {
  final String uid;
  final String name;
  final UserRole role;
  final String? assignedPhcId;
  final String? contact;
  final String? doctorRegistrationId;
  final String? hospitalRegistrationNumber;
  final String? pharmacistRegistrationNumber;
  final String? specialty; // e.g. General Physician, Cardiologist
  final bool isPresent; // Toggle by admin for doctors
  final DateTime? createdAt;
  
  // Additional Patient Fields
  final int? age;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? emergencyContact;
  final String? profilePicUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.role,
    this.assignedPhcId,
    this.contact,
    this.doctorRegistrationId,
    this.hospitalRegistrationNumber,
    this.pharmacistRegistrationNumber,
    this.specialty,
    this.isPresent = false,
    this.createdAt,
    this.age,
    this.gender,
    this.bloodGroup,
    this.address,
    this.emergencyContact,
    this.profilePicUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    String rawName = data['name'] ?? '';
    UserRole parsedRole = UserRole.values.firstWhere(
      (e) => e.name == data['role'],
      orElse: () => UserRole.patient,
    );

    if (parsedRole == UserRole.doctor && rawName.isNotEmpty && !rawName.trim().startsWith('Dr.')) {
      rawName = 'Dr. ${rawName.trim()}';
    }

    return UserModel(
      uid: documentId,
      name: rawName,
      role: parsedRole,
      assignedPhcId: data['assignedPhcId'],
      contact: data['contact'],
      doctorRegistrationId: data['doctorRegistrationId'],
      hospitalRegistrationNumber: data['hospitalRegistrationNumber'],
      pharmacistRegistrationNumber: data['pharmacistRegistrationNumber'],
      specialty: data['specialty'],
      isPresent: data['isPresent'] ?? false,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      age: data['age'],
      gender: data['gender'],
      bloodGroup: data['bloodGroup'],
      address: data['address'],
      emergencyContact: data['emergencyContact'],
      profilePicUrl: data['profilePicUrl'],
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
      'specialty': specialty,
      'isPresent': isPresent,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'age': age,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'address': address,
      'emergencyContact': emergencyContact,
      'profilePicUrl': profilePicUrl,
    };
  }
}
