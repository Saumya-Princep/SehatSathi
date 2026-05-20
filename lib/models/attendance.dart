import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String userId;
  final String userName;
  final String role;
  final String phcId;
  final DateTime? checkIn;
  final DateTime? checkOut;

  Attendance({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    required this.phcId,
    this.checkIn,
    this.checkOut,
  });

  factory Attendance.fromMap(Map<String, dynamic> data, String documentId) {
    return Attendance(
      id: documentId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      role: data['role'] ?? '',
      phcId: data['phcId'] ?? '',
      checkIn: data['checkIn'] != null ? (data['checkIn'] as Timestamp).toDate() : null,
      checkOut: data['checkOut'] != null ? (data['checkOut'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'role': role,
      'phcId': phcId,
      'checkIn': checkIn != null ? Timestamp.fromDate(checkIn!) : FieldValue.serverTimestamp(),
      'checkOut': checkOut != null ? Timestamp.fromDate(checkOut!) : null,
    };
  }
}
