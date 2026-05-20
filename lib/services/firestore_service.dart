import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medical_record.dart';
import '../models/inventory_item.dart';
import '../models/ambulance.dart';
import '../models/attendance.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Patients list for doctor dropdown
  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final query = await _db.collection('users').where('role', isEqualTo: 'patient').get();
    return query.docs.map((doc) => {
      'id': doc.id,
      'name': doc.data()['name'] ?? 'Unknown Patient',
    }).toList();
  }

  // EHR
  Stream<List<MedicalRecord>> getPatientRecords(String patientId) {
    return _db
        .collection('medical_records')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => MedicalRecord.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) {
            final dateA = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
            final dateB = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
            return dateB.compareTo(dateA);
          });
          return list;
        });
  }
  
  Stream<List<MedicalRecord>> getDoctorRecords(String doctorId) {
    return _db
        .collection('medical_records')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => MedicalRecord.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) {
            final dateA = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
            final dateB = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
            return dateB.compareTo(dateA);
          });
          return list;
        });
  }

  Future<void> addMedicalRecord(MedicalRecord record) async {
    await _db.collection('medical_records').doc(record.id).set(record.toMap());
  }

  // Inventory
  Stream<List<InventoryItem>> getInventory() {
    return _db.collection('inventory').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => InventoryItem.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> updateInventoryStock(String itemId, int newStock) async {
    await _db.collection('inventory').doc(itemId).update({'currentStock': newStock, 'lastUpdated': FieldValue.serverTimestamp()});
  }

  // Attendance
  Future<void> checkIn(Attendance attendance) async {
    await _db.collection('attendance').doc(attendance.id).set(attendance.toMap());
  }

  Future<void> checkOut(String attendanceId) async {
    await _db.collection('attendance').doc(attendanceId).update({'checkOut': FieldValue.serverTimestamp()});
  }
  
  Stream<List<Attendance>> getTodayAttendance(String phcId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _db.collection('attendance')
        .where('phcId', isEqualTo: phcId)
        .where('checkIn', isGreaterThanOrEqualTo: startOfDay)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Attendance.fromMap(doc.data(), doc.id)).toList());
  }

  // Ambulance
  Stream<List<Ambulance>> getAmbulances(String phcId) {
    return _db.collection('ambulances')
        .where('assignedPhcId', isEqualTo: phcId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Ambulance.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> updateAmbulanceStatus(String ambulanceId, AmbulanceStatus status, double lat, double lng) async {
    await _db.collection('ambulances').doc(ambulanceId).update({
      'status': status.name,
      'latitude': lat,
      'longitude': lng,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
  
  // Analytics
  Stream<QuerySnapshot> getRecentMedicalRecords() {
    final last48Hours = DateTime.now().subtract(const Duration(hours: 48));
    return _db.collection('medical_records')
        .where('date', isGreaterThanOrEqualTo: last48Hours)
        .snapshots();
  }

  Stream<int> getPatientsTodayCount(String phcId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    // Ideally, medical_records would have a phcId field. Assuming we count all today's records for now
    // or we filter by doctor's phc. Let's just query records created today for simplicity.
    return _db.collection('medical_records')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> dispatchEmergencyAmbulance(String phcId, double lat, double lng) async {
    final query = await _db.collection('ambulances')
      .where('assignedPhcId', isEqualTo: phcId)
      .where('status', isEqualTo: AmbulanceStatus.available.name)
      .limit(1)
      .get();
      
    if (query.docs.isNotEmpty) {
      final docId = query.docs.first.id;
      await updateAmbulanceStatus(docId, AmbulanceStatus.dispatched, lat, lng);
    } else {
      throw Exception('No available ambulance at the moment.');
    }
  }
}
