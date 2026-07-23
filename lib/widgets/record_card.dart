import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/medical_record.dart';
import 'package:intl/intl.dart';
import '../../models/lab_report.dart';
import '../../services/firestore_service.dart';
import '../../l10n/app_localizations.dart';

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
            Text('${AppLocalizations.of(context)!.diagnosis}: ${record.diagnosis}', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)),
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${AppLocalizations.of(context)!.notes}: ${record.notes}', style: const TextStyle(fontSize: 14)),
            ],
            if (record.prescriptions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('${AppLocalizations.of(context)!.prescriptions}:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                        p.isDispensed ? AppLocalizations.of(context)!.dispensed : AppLocalizations.of(context)!.pending,
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
                  Text(AppLocalizations.of(context)!.clinicalEncounterDetails, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  _buildSectionTitle(context, AppLocalizations.of(context)!.doctor),
                  Text(record.doctorName.startsWith('Dr.') ? record.doctorName : 'Dr. ${record.doctorName}', style: const TextStyle(fontSize: 16)),
                  if (record.date != null) ...[
                    const SizedBox(height: 4),
                    Text('${AppLocalizations.of(context)!.date}: ${DateFormat('MMMM dd, yyyy - hh:mm a').format(record.date!)}', style: const TextStyle(color: Colors.grey)),
                  ],
                  const Divider(height: 32),

                  _buildSectionTitle(context, AppLocalizations.of(context)!.diagnosisImpression),
                  Text(record.diagnosis, style: const TextStyle(fontSize: 16)),
                  const Divider(height: 32),

                  if (record.allergies.isNotEmpty) ...[
                    _buildSectionTitle(context, AppLocalizations.of(context)!.allergies),
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

                  _buildSectionTitle(context, AppLocalizations.of(context)!.progressNotesTreatmentPlan),
                  Text(record.notes.isEmpty ? AppLocalizations.of(context)!.noClinicalNotes : record.notes, style: const TextStyle(fontSize: 16, height: 1.5)),
                  const Divider(height: 32),

                  _buildSectionTitle(context, AppLocalizations.of(context)!.prescribedMedications),
                  if (record.prescriptions.isEmpty)
                    Text(AppLocalizations.of(context)!.noMedications, style: TextStyle(fontStyle: FontStyle.italic))
                  else
                    ...record.prescriptions.map((p) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: const Icon(Icons.medication),
                      ),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${AppLocalizations.of(context)!.dosage}: ${p.dosage}\n${AppLocalizations.of(context)!.quantity}: ${p.quantity}'),
                      trailing: Chip(
                        label: Text(p.isDispensed ? AppLocalizations.of(context)!.dispensed : AppLocalizations.of(context)!.pending, style: const TextStyle(fontSize: 12)),
                        backgroundColor: p.isDispensed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        labelStyle: TextStyle(color: p.isDispensed ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    )),
                  const Divider(height: 32),
                  _buildSectionTitle(context, AppLocalizations.of(context)!.laboratoryReports),
                  StreamBuilder<List<LabReport>>(
                    stream: FirestoreService().getLabReportsForRecord(record.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final reports = snapshot.data ?? [];
                      if (reports.isEmpty) {
                        return Text(AppLocalizations.of(context)!.noLabReports, style: TextStyle(fontStyle: FontStyle.italic));
                      }
                      return Column(
                        children: reports.map((r) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.withOpacity(0.2),
                                child: const Icon(Icons.science, color: Colors.green),
                              ),
                              title: Text(r.testName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                r.timestamp != null 
                                  ? '${AppLocalizations.of(context)!.completedOn} ${DateFormat('MMM dd, yyyy - hh:mm a').format(r.timestamp!)}' 
                                  : AppLocalizations.of(context)!.completed
                              ),
                              trailing: const Icon(Icons.check_circle, color: Colors.green),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (r.imageUrl != null && r.imageUrl!.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 16),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).push(MaterialPageRoute(
                                                  builder: (context) => Scaffold(
                                                    backgroundColor: Colors.black,
                                                    appBar: AppBar(
                                                      backgroundColor: Colors.black,
                                                      iconTheme: const IconThemeData(color: Colors.white),
                                                      title: Text(r.testName, style: const TextStyle(color: Colors.white)),
                                                    ),
                                                    body: Center(
                                                      child: InteractiveViewer(
                                                        minScale: 0.5,
                                                        maxScale: 4.0,
                                                        child: r.imageUrl!.startsWith('data:image')
                                                            ? Image.memory(base64Decode(r.imageUrl!.split(',').last))
                                                            : Image.network(r.imageUrl!),
                                                      ),
                                                    ),
                                                  ),
                                                ));
                                              },
                                              child: r.imageUrl!.startsWith('data:image')
                                                  ? Image.memory(
                                                      base64Decode(r.imageUrl!.split(',').last),
                                                      fit: BoxFit.contain,
                                                    )
                                                  : Image.network(
                                                      r.imageUrl!,
                                                      fit: BoxFit.contain,
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return const Center(
                                                          child: Padding(
                                                            padding: EdgeInsets.all(32.0),
                                                            child: CircularProgressIndicator(),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                            ),
                                          ),
                                        ),
                                      if (r.resultText != null && r.resultText!.isNotEmpty) ...[
                                        Text('${AppLocalizations.of(context)!.notes}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(r.resultText!),
                                      ]
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
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
