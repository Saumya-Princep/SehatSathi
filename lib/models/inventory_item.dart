import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name;
  final String batchNumber;
  final int currentStock;
  final int thresholdLimit;
  final DateTime? lastUpdated;

  InventoryItem({
    required this.id,
    required this.name,
    required this.batchNumber,
    required this.currentStock,
    required this.thresholdLimit,
    this.lastUpdated,
  });

  bool get isLowStock => currentStock <= thresholdLimit;

  factory InventoryItem.fromMap(Map<String, dynamic> data, String documentId) {
    return InventoryItem(
      id: documentId,
      name: data['name'] ?? '',
      batchNumber: data['batchNumber'] ?? '',
      currentStock: data['currentStock']?.toInt() ?? 0,
      thresholdLimit: data['thresholdLimit']?.toInt() ?? 0,
      lastUpdated: data['lastUpdated'] != null ? (data['lastUpdated'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'batchNumber': batchNumber,
      'currentStock': currentStock,
      'thresholdLimit': thresholdLimit,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : FieldValue.serverTimestamp(),
    };
  }
}
