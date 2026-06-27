import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/attendance.dart';
import '../models/ambulance.dart';
import '../models/medical_record.dart';
import '../models/health_advisory.dart';
import '../models/user_model.dart';
import 'package:uuid/uuid.dart';

class AdminProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final String phcId;

  AdminProvider({required this.phcId});

  Stream<List<Attendance>> get todayAttendanceStream {
    return _firestoreService.getTodayAttendance(phcId);
  }
  
  Stream<List<Ambulance>> get ambulancesStream {
    return _firestoreService.getAmbulances(phcId);
  }
  
  Stream<int> get activeDoctorsCountStream {
    return todayAttendanceStream.map((attendances) {
      return attendances.where((a) => a.role == 'doctor' && a.checkOut == null).length;
    });
  }

  Stream<int> get patientsTodayCountStream {
    return _firestoreService.getPatientsTodayCount(phcId);
  }

  // Early Warning System Logic
  Stream<bool> get diseaseAlertStream {
    return _firestoreService.getRecentMedicalRecords().map((snapshot) {
      int malariaCases = 0;
      int dengueCases = 0;
      
      for (var doc in snapshot.docs) {
        final record = MedicalRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (record.diagnosis.toLowerCase().contains('malaria')) {
          malariaCases++;
        }
        if (record.diagnosis.toLowerCase().contains('dengue')) {
          dengueCases++;
        }
      }
      
      // Alert if > 5 cases of Malaria or Dengue in last 48 hours
      return (malariaCases > 5 || dengueCases > 5);
    });
  }

  // Epidemiology stats aggregator
  Stream<Map<String, int>> get diagnosisStatsStream {
    return _firestoreService.getRecentMedicalRecords().map((snapshot) {
      final Map<String, int> stats = {
        'Malaria': 0,
        'Dengue': 0,
        'Flu/Fever': 0,
        'Typhoid': 0,
        'Other': 0,
      };
      
      for (var doc in snapshot.docs) {
        final record = MedicalRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        final diag = record.diagnosis.toLowerCase();
        
        if (diag.contains('malaria')) {
          stats['Malaria'] = (stats['Malaria'] ?? 0) + 1;
        } else if (diag.contains('dengue')) {
          stats['Dengue'] = (stats['Dengue'] ?? 0) + 1;
        } else if (diag.contains('flu') || diag.contains('fever') || diag.contains('cold')) {
          stats['Flu/Fever'] = (stats['Flu/Fever'] ?? 0) + 1;
        } else if (diag.contains('typhoid')) {
          stats['Typhoid'] = (stats['Typhoid'] ?? 0) + 1;
        } else {
          stats['Other'] = (stats['Other'] ?? 0) + 1;
        }
      }
      return stats;
    });
  }

  // Ambulance Fleet Management
  Future<void> createAmbulance(String vehicleNumber) async {
    final ambulance = Ambulance(
      id: const Uuid().v4(),
      vehicleNumber: vehicleNumber,
      status: AmbulanceStatus.available,
      latitude: 18.5204, // Default center lat
      longitude: 73.8567, // Default center lng
      assignedPhcId: phcId,
    );
    await _firestoreService.addAmbulance(ambulance);
  }

  Future<void> removeAmbulance(String ambulanceId) async {
    await _firestoreService.deleteAmbulance(ambulanceId);
  }

  Future<void> resetAmbulance(String ambulanceId) async {
    await _firestoreService.cancelEmergencyAmbulance(ambulanceId);
  }

  // Health Advisories
  Future<void> broadcastAdvisory(String title, String description, String severity) async {
    final advisory = HealthAdvisory(
      id: const Uuid().v4(),
      title: title,
      description: description,
      severity: severity,
      date: DateTime.now(),
    );
    await _firestoreService.postHealthAdvisory(advisory);
  }

  // Doctors
  Stream<List<UserModel>> get doctorsStream {
    return _firestoreService.getDoctorsStream();
  }

  Future<void> toggleDoctorPresence(String uid, bool isPresent) async {
    await _firestoreService.toggleDoctorPresence(uid, isPresent);
  }
}
