import 'package:cloud_firestore/cloud_firestore.dart';

enum AmbulanceStatus { available, dispatched, onBreak }

class Ambulance {
  final String id;
  final String vehicleNumber;
  final AmbulanceStatus status;
  final double latitude;
  final double longitude;
  final String assignedPhcId;
  final String? patientId;
  final DateTime? lastUpdated;

  Ambulance({
    required this.id,
    required this.vehicleNumber,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.assignedPhcId,
    this.patientId,
    this.lastUpdated,
  });

  factory Ambulance.fromMap(Map<String, dynamic> data, String documentId) {
    return Ambulance(
      id: documentId,
      vehicleNumber: data['vehicleNumber'] ?? '',
      status: AmbulanceStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AmbulanceStatus.available,
      ),
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      assignedPhcId: data['assignedPhcId'] ?? '',
      patientId: data['patientId'],
      lastUpdated: data['lastUpdated'] != null ? (data['lastUpdated'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleNumber': vehicleNumber,
      'status': status.name,
      'latitude': latitude,
      'longitude': longitude,
      'assignedPhcId': assignedPhcId,
      'patientId': patientId,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : FieldValue.serverTimestamp(),
    };
  }
}
