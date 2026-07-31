import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/inventory_item.dart';
import '../models/inventory_item.dart';
import '../models/medical_record.dart';
import '../models/health_advisory.dart';

class PharmacistProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  Stream<List<InventoryItem>> get inventoryStream {
    return _firestoreService.getInventory();
  }

  Stream<List<HealthAdvisory>> get activeAdvisoriesStream {
    return _firestoreService.getHealthAdvisories();
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    await _firestoreService.addInventoryItem(item);
  }

  Future<void> updateStock(String itemId, int newStock) async {
    await _firestoreService.updateInventoryStock(itemId, newStock);
  }

  Stream<List<MedicalRecord>> get pendingPrescriptionsStream {
    return _firestoreService.getPendingPrescriptions();
  }

  Future<void> dispenseMedicines(String recordId, List<Map<String, dynamic>> items) async {
    await _firestoreService.dispensePrescription(recordId, items);
  }
}
