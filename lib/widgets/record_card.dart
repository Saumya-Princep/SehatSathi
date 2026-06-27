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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRecordDetails(context),
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
      ),
    );
  }

  void _showRecordDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Clinical Encounter Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  _buildSectionTitle(context, 'Doctor'),
                  Text(record.doctorName.startsWith('Dr.') ? record.doctorName : 'Dr. ${record.doctorName}', style: const TextStyle(fontSize: 16)),
                  if (record.date != null) ...[
                    const SizedBox(height: 4),
                    Text('Date: ${DateFormat('MMMM dd, yyyy - hh:mm a').format(record.date!)}', style: const TextStyle(color: Colors.grey)),
                  ],
                  const Divider(height: 32),

                  _buildSectionTitle(context, 'Diagnosis / Impression'),
                  Text(record.diagnosis, style: const TextStyle(fontSize: 16)),
                  const Divider(height: 32),

                  if (record.allergies.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Allergies'),
                    Wrap(
                      spacing: 8,
                      children: record.allergies.map((a) => Chip(
                        label: Text(a),
                        backgroundColor: Colors.red.withOpacity(0.1),
                        labelStyle: const TextStyle(color: Colors.red),
                      )).toList(),
                    ),
                    const Divider(height: 32),
                  ],

                  _buildSectionTitle(context, 'Progress Notes & Treatment Plan'),
                  Text(record.notes.isEmpty ? 'No clinical notes provided.' : record.notes, style: const TextStyle(fontSize: 16, height: 1.5)),
                  const Divider(height: 32),

                  _buildSectionTitle(context, 'Prescribed Medications'),
                  if (record.prescriptions.isEmpty)
                    const Text('No medications prescribed during this visit.', style: TextStyle(fontStyle: FontStyle.italic))
                  else
                    ...record.prescriptions.map((p) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: const Icon(Icons.medication),
                      ),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Dosage: ${p.dosage}\nQuantity: ${p.quantity}'),
                      trailing: Chip(
                        label: Text(p.isDispensed ? 'Dispensed' : 'Pending', style: const TextStyle(fontSize: 12)),
                        backgroundColor: p.isDispensed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        labelStyle: TextStyle(color: p.isDispensed ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    )),
                  
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
