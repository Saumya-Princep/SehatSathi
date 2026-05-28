import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/medical_record.dart';
import '../models/ambulance.dart';
import '../models/health_advisory.dart';

class PatientProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final String patientId;
  final String phcId;

  PatientProvider({required this.patientId, required this.phcId});

  Stream<List<MedicalRecord>> get medicalRecordsStream {
    return _firestoreService.getPatientRecords(patientId);
  }

  Stream<Ambulance?> get activeAmbulanceStream {
    return _firestoreService.getPatientActiveAmbulanceRequest(patientId);
  }

  Stream<List<HealthAdvisory>> get activeAdvisoriesStream {
    return _firestoreService.getHealthAdvisories();
  }

  Future<void> requestEmergencyAmbulance(double lat, double lng) async {
    await _firestoreService.dispatchEmergencyAmbulance(phcId, patientId, lat, lng);
  }

  Future<void> cancelAmbulanceRequest(String ambulanceId) async {
    await _firestoreService.cancelEmergencyAmbulance(ambulanceId);
  }
}
