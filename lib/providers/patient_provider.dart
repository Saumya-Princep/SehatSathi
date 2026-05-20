import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/medical_record.dart';

class PatientProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final String patientId;
  final String phcId;

  PatientProvider({required this.patientId, required this.phcId});

  Stream<List<MedicalRecord>> get medicalRecordsStream {
    return _firestoreService.getPatientRecords(patientId);
  }

  Future<void> requestEmergencyAmbulance(double lat, double lng) async {
    await _firestoreService.dispatchEmergencyAmbulance(phcId, lat, lng);
  }
}
