import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  scheduled,
  checkedIn,
  inProgress,
  completed
}

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final int patientAge;
  final String doctorId;
  final String doctorName;
  final DateTime time;
  final String reason;
  final int queueNumber; // Token number
  final AppointmentStatus status;

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.doctorId,
    this.doctorName = 'Unknown Doctor',
    required this.time,
    required this.reason,
    required this.queueNumber,
    this.status = AppointmentStatus.scheduled,
  });

  factory Appointment.fromMap(Map<String, dynamic> data, String documentId) {
    return Appointment(
      id: documentId,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? 'Unknown Patient',
      patientAge: data['patientAge']?.toInt() ?? 0,
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? 'Unknown Doctor',
      time: (data['time'] as Timestamp).toDate(),
      reason: data['reason'] ?? '',
      queueNumber: data['queueNumber']?.toInt() ?? 1,
      status: _statusFromString(data['status']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'patientAge': patientAge,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'time': Timestamp.fromDate(time),
      'reason': reason,
      'queueNumber': queueNumber,
      'status': _stringFromStatus(status),
    };
  }

  static AppointmentStatus _statusFromString(String? status) {
    switch (status) {
      case 'checkedIn': return AppointmentStatus.checkedIn;
      case 'inProgress': return AppointmentStatus.inProgress;
      case 'completed': return AppointmentStatus.completed;
      default: return AppointmentStatus.scheduled;
    }
  }

  static String _stringFromStatus(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.checkedIn: return 'checkedIn';
      case AppointmentStatus.inProgress: return 'inProgress';
      case AppointmentStatus.completed: return 'completed';
      default: return 'scheduled';
    }
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? patientName,
    int? patientAge,
    String? doctorId,
    String? doctorName,
    DateTime? time,
    String? reason,
    int? queueNumber,
    AppointmentStatus? status,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      time: time ?? this.time,
      reason: reason ?? this.reason,
      queueNumber: queueNumber ?? this.queueNumber,
      status: status ?? this.status,
    );
  }
}
