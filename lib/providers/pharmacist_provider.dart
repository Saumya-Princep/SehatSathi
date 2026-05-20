import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/inventory_item.dart';

class PharmacistProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  Stream<List<InventoryItem>> get inventoryStream {
    return _firestoreService.getInventory();
  }

  Future<void> updateStock(String itemId, int newStock) async {
    await _firestoreService.updateInventoryStock(itemId, newStock);
  }
}
