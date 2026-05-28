import 'package:cloud_firestore/cloud_firestore.dart';

class HealthAdvisory {
  final String id;
  final String title;
  final String description;
  final String severity; // 'info', 'warning', 'critical'
  final DateTime date;

  HealthAdvisory({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.date,
  });

  factory HealthAdvisory.fromMap(Map<String, dynamic> data, String id) {
    return HealthAdvisory(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      severity: data['severity'] ?? 'info',
      date: data['date'] != null ? (data['date'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'severity': severity,
      'date': Timestamp.fromDate(date),
    };
  }
}
