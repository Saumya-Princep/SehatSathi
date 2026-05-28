import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_sathi/models/medical_record.dart';

void main() {
  group('PrescriptionItem Model Tests', () {
    test('Should convert map to PrescriptionItem', () {
      final map = {
        'id': 'med_1',
        'name': 'Paracetamol',
        'dosage': '1-0-1',
        'quantity': 10,
        'isDispensed': false,
      };

      final item = PrescriptionItem.fromMap(map);

      expect(item.id, 'med_1');
      expect(item.name, 'Paracetamol');
      expect(item.dosage, '1-0-1');
      expect(item.quantity, 10);
      expect(item.isDispensed, false);
    });

    test('Should convert PrescriptionItem to Map', () {
      final item = PrescriptionItem(
        id: 'med_2',
        name: 'Amoxicillin',
        dosage: '1-1-1',
        quantity: 15,
        isDispensed: true,
      );

      final map = item.toMap();

      expect(map['id'], 'med_2');
      expect(map['name'], 'Amoxicillin');
      expect(map['dosage'], '1-1-1');
      expect(map['quantity'], 15);
      expect(map['isDispensed'], true);
    });

    test('copyWith works correctly', () {
      final item = PrescriptionItem(
        id: 'med_2',
        name: 'Amoxicillin',
        dosage: '1-1-1',
        quantity: 15,
        isDispensed: false,
      );

      final updated = item.copyWith(isDispensed: true);

      expect(updated.id, 'med_2');
      expect(updated.name, 'Amoxicillin');
      expect(updated.isDispensed, true);
    });
  });
}
