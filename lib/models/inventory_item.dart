import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name;
  final String batchNumber;
  final String phcId;
  final int currentStock;
  final int thresholdLimit;
  final DateTime? lastUpdated;

  InventoryItem({
    required this.id,
    required this.name,
    required this.batchNumber,
    required this.phcId,
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
      phcId: data['phcId'] ?? 'phc_1',
      currentStock: data['currentStock']?.toInt() ?? 0,
      thresholdLimit: data['thresholdLimit']?.toInt() ?? 0,
      lastUpdated: data['lastUpdated'] != null ? (data['lastUpdated'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'batchNumber': batchNumber,
      'phcId': phcId,
      'currentStock': currentStock,
      'thresholdLimit': thresholdLimit,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : FieldValue.serverTimestamp(),
    };
  }
}
