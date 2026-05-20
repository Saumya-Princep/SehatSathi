import 'package:flutter/material.dart';
import '../../models/medical_record.dart';
import 'package:intl/intl.dart';

class RecordCard extends StatelessWidget {
  final MedicalRecord record;

  const RecordCard({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record.doctorName.startsWith('Dr.') 
                      ? record.doctorName 
                      : 'Dr. ${record.doctorName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (record.date != null)
                  Text(
                    DateFormat('MMM dd, yyyy').format(record.date!),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Diagnosis: ${record.diagnosis}', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)),
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${record.notes}', style: const TextStyle(fontSize: 14)),
            ],
            if (record.prescriptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Prescriptions:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...record.prescriptions.map((p) => Text('- $p')).toList(),
            ]
          ],
        ),
      ),
    );
  }
}
