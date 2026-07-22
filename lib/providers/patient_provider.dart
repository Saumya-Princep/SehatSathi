import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/triage_service.dart';
import '../models/medical_record.dart';
import '../models/ambulance.dart';
import '../models/health_advisory.dart';
import '../models/appointment.dart';
import '../models/vitals.dart';
import 'package:uuid/uuid.dart';
import '../services/sync_manager.dart';

class PatientProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final String patientId;
  final String phcId;

  PatientProvider({required this.patientId, required this.phcId});

  bool get isOffline => FirestoreService.isOfflineSimulated;

  void toggleOfflineMode() async {
    FirestoreService.isOfflineSimulated = !FirestoreService.isOfflineSimulated;
    notifyListeners();
    
    if (!FirestoreService.isOfflineSimulated) {
      await SyncManager.instance.syncPendingData();
    }
  }

  Stream<List<MedicalRecord>> get medicalRecordsStream {
    return _firestoreService.getPatientRecords(patientId);
  }

  Stream<List<Vitals>> get vitalsStream {
    return _firestoreService.getPatientVitals(patientId);
  }

  Stream<Ambulance?> get activeAmbulanceStream {
    return _firestoreService.getPatientActiveAmbulanceRequest(patientId);
  }

  Stream<List<HealthAdvisory>> get activeAdvisoriesStream {
    return _firestoreService.getHealthAdvisories();
  }

  Stream<List<Appointment>> get activeAppointmentsStream {
    return _firestoreService.getPatientActiveAppointments(patientId);
  }

  Future<void> requestEmergencyAmbulance(double lat, double lng) async {
    await _firestoreService.dispatchEmergencyAmbulance(phcId, patientId, lat, lng);
  }

  Future<void> cancelAmbulanceRequest(String ambulanceId) async {
    await _firestoreService.cancelEmergencyAmbulance(ambulanceId);
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _firestoreService.cancelAppointment(appointmentId);
  }

  Future<Map<String, dynamic>> joinDoctorQueue(String patientName, String reason, String phcId) async {
    // Check if patient is already in the queue for the exact same reason
    final activeAptsSnapshot = await _firestoreService.getPatientActiveAppointmentsOnce(patientId);
    for (var apt in activeAptsSnapshot) {
      if (apt.reason.toLowerCase() == reason.toLowerCase()) {
        throw Exception('You have already joined the queue for this problem. Your token is #${apt.queueNumber}.');
      }
    }

    final specialty = TriageService.determineSpecialty(reason);
    final doctor = await _firestoreService.assignDoctor(patientId, specialty, phcId);
    if (doctor == null) {
      throw Exception('No doctors available at this time in the selected hospital.');
    }

    final queueCount = await _firestoreService.getDoctorQueueCount(doctor['id']);
    final tokenNumber = queueCount + 1;

    String docName = doctor['name'] ?? 'Unknown Doctor';
    if (!docName.startsWith('Dr.')) {
      docName = 'Dr. $docName';
    }

    final appointment = Appointment(
      id: const Uuid().v4(),
      patientId: patientId,
      patientName: patientName,
      patientAge: 30, // Mocked age for now
      doctorId: doctor['id'],
      doctorName: docName,
      time: DateTime.now(),
      reason: reason,
      queueNumber: tokenNumber,
      status: AppointmentStatus.scheduled,
    );
    await _firestoreService.requestAppointment(appointment);

    return {
      'doctorName': docName,
      'specialty': doctor['specialty'] ?? specialty,
      'tokenNumber': tokenNumber,
    };
  }

  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    return await _firestoreService.getAllDoctors();
  }
}
