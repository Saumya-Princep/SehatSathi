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
              const SizedBox(height: 12),
              const Text('Prescriptions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              ...record.prescriptions.map((p) => Padding(
                padding: const EdgeInsets.only(left: 4.0, top: 4.0, bottom: 4.0),
                child: Row(
                  children: [
                    Icon(
                      p.isDispensed ? Icons.check_circle_outline : Icons.schedule,
                      size: 16,
                      color: p.isDispensed ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${p.name} — ${p.dosage} (Qty: ${p.quantity})',
                        style: TextStyle(
                          fontSize: 13,
                          decoration: p.isDispensed ? TextDecoration.lineThrough : null,
                          color: p.isDispensed ? Colors.grey : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.isDispensed ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.isDispensed ? 'Dispensed' : 'Pending',
                        style: TextStyle(
                          fontSize: 10,
                          color: p.isDispensed ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ]
          ],
        ),
      ),
    );
  }
}
