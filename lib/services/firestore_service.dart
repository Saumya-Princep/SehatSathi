import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medical_record.dart';
import '../models/inventory_item.dart';
import '../models/ambulance.dart';
import '../models/attendance.dart';
import '../models/health_advisory.dart';
import '../models/appointment.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // PHCs list for registration dropdown
  Future<List<Map<String, dynamic>>> getAllPhcs() async {
    final query = await _db.collection('phcs').get();
    if (query.docs.isEmpty) {
      // If collection is empty, create defaults to populate UI
      final defaults = [
        {'id': 'phc_1', 'name': 'City Primary Health Center'},
        {'id': 'phc_2', 'name': 'Sub-District Health Center'},
        {'id': 'phc_3', 'name': 'Rural Health Clinic'},
      ];
      for (var d in defaults) {
        await _db.collection('phcs').doc(d['id']).set({'name': d['name']});
      }
      return defaults;
    }
    return query.docs.map((doc) => {
      'id': doc.id,
      'name': doc.data()['name'] ?? 'Unknown PHC',
    }).toList();
  }

  // Patients list for doctor dropdown
  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final query = await _db.collection('users').where('role', isEqualTo: 'patient').get();
    return query.docs.map((doc) => {
      'id': doc.id,
      'name': doc.data()['name'] ?? 'Unknown Patient',
    }).toList();
  }

  // Doctors list for patient dropdown
  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    final query = await _db.collection('users').where('role', isEqualTo: 'doctor').get();
    return query.docs.map((doc) => {
      'id': doc.id,
      'name': doc.data()['name'] ?? 'Unknown Doctor',
    }).toList();
  }

  Future<Map<String, dynamic>?> getDoctorBySpecialty(String specialty) async {
    final query = await _db.collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('specialty', isEqualTo: specialty)
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) {
      // Fallback to any doctor if specialist not found
      final fallback = await _db.collection('users').where('role', isEqualTo: 'doctor').limit(1).get();
      if (fallback.docs.isEmpty) return null;
      return {'id': fallback.docs.first.id, 'name': fallback.docs.first.data()['name'] ?? 'Doctor', 'specialty': fallback.docs.first.data()['specialty'] ?? 'General Physician'};
    }
    return {'id': query.docs.first.id, 'name': query.docs.first.data()['name'] ?? 'Doctor', 'specialty': query.docs.first.data()['specialty'] ?? specialty};
  }

  // EHR Records
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

  // Structured Prescriptions & Pharmacy Dispensation
  Stream<List<MedicalRecord>> getPendingPrescriptions() {
    return _db
        .collection('medical_records')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => MedicalRecord.fromMap(doc.data(), doc.id))
              .where((rec) => rec.prescriptions.any((p) => !p.isDispensed))
              .toList();
          list.sort((a, b) {
            final dateA = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
            final dateB = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
            return dateB.compareTo(dateA);
          });
          return list;
        });
  }

  Future<void> dispensePrescription(String recordId, List<Map<String, dynamic>> itemsToDispense) async {
    final recordRef = _db.collection('medical_records').doc(recordId);

    await _db.runTransaction((transaction) async {
      final recordDoc = await transaction.get(recordRef);
      if (!recordDoc.exists) throw Exception("Medical record not found.");

      final record = MedicalRecord.fromMap(recordDoc.data()!, recordDoc.id);

      // Verify and decrement stock for each medicine in inventory
      for (var item in itemsToDispense) {
        final String medId = item['id'];
        final int qty = item['quantity'];

        final medRef = _db.collection('inventory').doc(medId);
        final medDoc = await transaction.get(medRef);

        if (medDoc.exists) {
          final currentStock = medDoc.data()?['currentStock']?.toInt() ?? 0;
          if (currentStock < qty) {
            throw Exception("Insufficient stock for ${medDoc.data()?['name'] ?? medId}. Available: $currentStock, Required: $qty");
          }
          transaction.update(medRef, {
            'currentStock': currentStock - qty,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          throw Exception("Medicine not found in inventory: $medId");
        }
      }

      // Update the prescription item status to dispensed
      final updatedPrescriptions = record.prescriptions.map((item) {
        final dispenseInfo = itemsToDispense.firstWhere(
          (element) => element['id'] == item.id,
          orElse: () => {},
        );
        if (dispenseInfo.isNotEmpty) {
          return item.copyWith(isDispensed: true);
        }
        return item;
      }).toList();

      // Update record prescriptions list in database
      transaction.update(recordRef, {
        'prescriptions': updatedPrescriptions.map((p) => p.toMap()).toList(),
      });
    });
  }

  // Inventory Management
  Stream<List<InventoryItem>> getInventory() {
    return _db.collection('inventory').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => InventoryItem.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    await _db.collection('inventory').doc(item.id).set(item.toMap());
  }

  Future<void> updateInventoryStock(String itemId, int newStock) async {
    await _db.collection('inventory').doc(itemId).update({
      'currentStock': newStock,
      'lastUpdated': FieldValue.serverTimestamp()
    });
  }

  // Users / Doctors
  Stream<List<UserModel>> getDoctorsStream() {
    return _db.collection('users')
        .where('role', isEqualTo: 'doctor')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> toggleDoctorPresence(String uid, bool isPresent) async {
    await _db.collection('users').doc(uid).update({'isPresent': isPresent});
  }

  Stream<UserModel?> getDoctorStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Attendance Shifts
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

  // Ambulance Fleet
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

  Future<void> addAmbulance(Ambulance ambulance) async {
    await _db.collection('ambulances').doc(ambulance.id).set(ambulance.toMap());
  }

  Future<void> deleteAmbulance(String id) async {
    await _db.collection('ambulances').doc(id).delete();
  }

  Stream<Ambulance?> getPatientActiveAmbulanceRequest(String patientId) {
    return _db.collection('ambulances')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return Ambulance.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
        });
  }
  
  Future<void> dispatchEmergencyAmbulance(String phcId, String patientId, double lat, double lng) async {
    final query = await _db.collection('ambulances')
      .where('assignedPhcId', isEqualTo: phcId)
      .where('status', isEqualTo: AmbulanceStatus.available.name)
      .limit(1)
      .get();
      
    if (query.docs.isNotEmpty) {
      final docId = query.docs.first.id;
      await _db.collection('ambulances').doc(docId).update({
        'status': AmbulanceStatus.dispatched.name,
        'patientId': patientId,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } else {
      // Create a mock ambulance for demo purposes
      final newAmbulanceRef = _db.collection('ambulances').doc();
      await newAmbulanceRef.set({
        'vehicleNumber': 'DL-1C-9999',
        'status': AmbulanceStatus.dispatched.name,
        'latitude': 25.2450, // Bhagalpur Sadar Hospital
        'longitude': 86.9746,
        'assignedPhcId': phcId,
        'patientId': patientId,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> cancelEmergencyAmbulance(String ambulanceId) async {
    await _db.collection('ambulances').doc(ambulanceId).update({
      'status': AmbulanceStatus.available.name,
      'patientId': null,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Analytics & Epidemiological Outbreak Warning System
  Stream<QuerySnapshot> getRecentMedicalRecords() {
    final last48Hours = DateTime.now().subtract(const Duration(hours: 48));
    return _db.collection('medical_records')
        .where('date', isGreaterThanOrEqualTo: last48Hours)
        .snapshots();
  }

  Stream<int> getPatientsTodayCount(String phcId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.day == today.day ? today.month : today.month, today.day);
    return _db.collection('medical_records')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // District Health Advisories
  Stream<List<HealthAdvisory>> getHealthAdvisories() {
    return _db.collection('advisories')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => HealthAdvisory.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> postHealthAdvisory(HealthAdvisory advisory) async {
    await _db.collection('advisories').doc(advisory.id).set(advisory.toMap());
  }

  // Appointments / Digital Queue
  Stream<List<Appointment>> getDoctorAppointments(String doctorId) {
    return _db.collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Appointment.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<Appointment>> getPatientActiveAppointments(String patientId) {
    return _db.collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromMap(doc.data(), doc.id))
            .where((apt) => apt.status != AppointmentStatus.completed)
            .toList());
  }

  Future<List<Appointment>> getPatientActiveAppointmentsOnce(String patientId) async {
    final query = await _db.collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .get();
    return query.docs
        .map((doc) => Appointment.fromMap(doc.data(), doc.id))
        .where((apt) => apt.status != AppointmentStatus.completed)
        .toList();
  }

  Future<int> getDoctorQueueCount(String doctorId) async {
    final query = await _db.collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .get();
    int count = 0;
    for (var doc in query.docs) {
      if (doc.data()['status'] != 'completed') {
        count++;
      }
    }
    return count;
  }

  Future<void> requestAppointment(Appointment appointment) async {
    await _db.collection('appointments').doc(appointment.id).set(appointment.toMap());
  }

  Future<void> cancelAppointment(String id) async {
    await _db.collection('appointments').doc(id).delete();
  }

  Future<void> updateAppointmentStatus(String id, AppointmentStatus status) async {
    String statusStr = status.toString().split('.').last;
    await _db.collection('appointments').doc(id).update({
      'status': statusStr,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMedicalRecord(String recordId, String newNotes, List<PrescriptionItem> newPrescriptions) async {
    final recordRef = _db.collection('medical_records').doc(recordId);
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(recordRef);
      if (!doc.exists) return;
      
      final record = MedicalRecord.fromMap(doc.data()!, doc.id);
      
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      final updatedNotes = record.notes.trim().isEmpty 
          ? newNotes 
          : record.notes + '\n\n--- ' + dateStr + ' ---\n' + newNotes;
          
      final updatedPrescriptions = List<PrescriptionItem>.from(record.prescriptions)..addAll(newPrescriptions);
      
      transaction.update(recordRef, {
        'notes': updatedNotes,
        'prescriptions': updatedPrescriptions.map((p) => p.toMap()).toList(),
        'date': FieldValue.serverTimestamp(),
      });
    });
  }
}
