import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/attendance.dart';
import '../models/ambulance.dart';
import '../models/medical_record.dart';

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
}
