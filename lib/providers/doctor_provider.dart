import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/medical_record.dart';
import '../models/attendance.dart';
import '../models/inventory_item.dart';
import 'package:uuid/uuid.dart';

class DoctorProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final String doctorId;
  final String doctorName;
  final String phcId;
  
  bool _isCheckedIn = false;
  bool get isCheckedIn => _isCheckedIn;
  String? _attendanceId;

  DoctorProvider({required this.doctorId, required this.doctorName, required this.phcId});

  Stream<List<MedicalRecord>> get doctorRecordsStream {
    return _firestoreService.getDoctorRecords(doctorId);
  }

  Future<List<Map<String, dynamic>>> getPatientsList() async {
    return await _firestoreService.getAllPatients();
  }

  Stream<List<InventoryItem>> get inventoryStream {
    return _firestoreService.getInventory();
  }

  Future<void> addRecord(String patientId, String diagnosis, String notes, List<PrescriptionItem> prescriptions) async {
    final record = MedicalRecord(
      id: const Uuid().v4(),
      patientId: patientId,
      doctorId: doctorId,
      doctorName: doctorName,
      diagnosis: diagnosis,
      notes: notes,
      prescriptions: prescriptions,
    );
    await _firestoreService.addMedicalRecord(record);
  }
  
  Future<void> toggleAttendance() async {
    if (_isCheckedIn && _attendanceId != null) {
      await _firestoreService.checkOut(_attendanceId!);
      _isCheckedIn = false;
      _attendanceId = null;
    } else {
      _attendanceId = const Uuid().v4();
      final attendance = Attendance(
        id: _attendanceId!,
        userId: doctorId,
        userName: doctorName,
        role: 'doctor',
        phcId: phcId,
        checkIn: DateTime.now(),
      );
      await _firestoreService.checkIn(attendance);
      _isCheckedIn = true;
    }
    notifyListeners();
  }
}
