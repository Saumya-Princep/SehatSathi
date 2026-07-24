import 'package:cloud_firestore/cloud_firestore.dart';

class HealthAdvisory {
  final String id;
  final String title;
  final String description;
  final String severity; // 'info', 'warning', 'critical'
  final String phcId;
  final DateTime date;

  HealthAdvisory({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.phcId,
    required this.date,
  });

  factory HealthAdvisory.fromMap(Map<String, dynamic> data, String id) {
    return HealthAdvisory(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      severity: data['severity'] ?? 'info',
      phcId: data['phcId'] ?? 'phc_1',
      date: data['date'] != null ? (data['date'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'severity': severity,
      'phcId': phcId,
      'date': Timestamp.fromDate(date),
    };
  }
}
