import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medical_record.dart';
import '../models/appointment.dart';
import 'firestore_service.dart';
import 'package:flutter/foundation.dart';

class SyncManager {
  static final SyncManager instance = SyncManager._init();
  static Database? _database;

  SyncManager._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sync_queue.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  payload TEXT NOT NULL,
  timestamp TEXT NOT NULL
)
''');
  }

  Future<void> enqueueMedicalRecord(MedicalRecord record) async {
    final db = await instance.database;
    final map = record.toMap();
    // Convert timestamps or nested objects if necessary for JSON serialization
    // MedicalRecord toMap() returns a Map<String, dynamic> which should be json encodable
    // However, FieldValue.serverTimestamp() from Firestore might be tricky if it's there. 
    // MedicalRecord toMap uses actual strings/ints.
    await db.insert('sync_queue', {
      'type': 'MEDICAL_RECORD',
      'payload': jsonEncode(map),
      'timestamp': DateTime.now().toIso8601String(),
    });
    debugPrint('Queued Medical Record for offline sync.');
  }

  Future<void> enqueueAppointmentStatus(String id, AppointmentStatus status) async {
    final db = await instance.database;
    await db.insert('sync_queue', {
      'type': 'APPOINTMENT_STATUS',
      'payload': jsonEncode({'id': id, 'status': status.toString().split('.').last}),
      'timestamp': DateTime.now().toIso8601String(),
    });
    debugPrint('Queued Appointment Status update for offline sync.');
  }

  Future<void> syncPendingData() async {
    debugPrint('Starting offline sync...');
    final db = await instance.database;
    final List<Map<String, Object?>> queuedItems = await db.query('sync_queue', orderBy: 'timestamp ASC');

    if (queuedItems.isEmpty) {
      debugPrint('No items in sync queue.');
      return;
    }

    final firestore = FirestoreService();

    for (var item in queuedItems) {
      try {
        final type = item['type'] as String;
        final payload = jsonDecode(item['payload'] as String);

        if (type == 'MEDICAL_RECORD') {
          final record = MedicalRecord.fromMap(payload, payload['id']);
          // Using a direct method to bypass offline checks
          await firestore.addMedicalRecordDirect(record);
        } else if (type == 'APPOINTMENT_STATUS') {
          final statusStr = payload['status'] as String;
          AppointmentStatus status = AppointmentStatus.values.firstWhere(
            (e) => e.toString().split('.').last == statusStr,
            orElse: () => AppointmentStatus.scheduled,
          );
          await firestore.updateAppointmentStatusDirect(payload['id'], status);
        }

        // Remove from queue if successful
        await db.delete('sync_queue', where: 'id = ?', whereArgs: [item['id']]);
      } catch (e) {
        debugPrint('Failed to sync item ${item['id']}: $e');
        // Stop syncing to preserve order if an error occurs
        break;
      }
    }
    debugPrint('Offline sync completed.');
  }
}
