import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/appointment.dart';
import '../../../models/vitals.dart';
import '../../../models/medical_record.dart';
import '../../../models/inventory_item.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../providers/doctor_provider.dart';
import '../../../services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

class InteractivePatientModal extends StatefulWidget {
  final DoctorProvider provider;
  final Appointment appointment;

  const InteractivePatientModal({
    Key? key,
    required this.provider,
    required this.appointment,
  }) : super(key: key);

  @override
  _InteractivePatientModalState createState() => _InteractivePatientModalState();
}

class _InteractivePatientModalState extends State<InteractivePatientModal> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isListening = false;
  final stt.SpeechToText _speech = stt.SpeechToText();

  late List<Vitals> _historicalVitals;
  List<MedicalRecord> _patientRecords = [];
  bool _isNewProblem = true;
  String? _selectedRecordId;
  final List<PrescriptionItem> _prescriptions = [];

  @override
  void initState() {
    super.initState();
    _fetchPatientRecords();
    _historicalVitals = List.generate(5, (index) {
      return Vitals(
        id: 'v_$index',
        patientId: widget.appointment.patientId,
        date: DateTime.now().subtract(Duration(days: (5 - index) * 30)),
        bloodPressureSystolic: 110 + (index * 2) + (index % 2 == 0 ? 5 : -5),
        bloodPressureDiastolic: 70 + index + (index % 2 == 0 ? 2 : -2),
        heartRate: 65 + (index * 3),
        weight: 70.0 + (index * 0.5),
      );
    });
  }

  Future<void> _fetchPatientRecords() async {
    FirestoreService().getPatientRecords(widget.appointment.patientId).listen((records) {
      if (mounted) {
        setState(() {
          _patientRecords = records;
          if (records.isNotEmpty && _selectedRecordId == null) {
            _selectedRecordId = records.first.id;
          }
        });
      }
    });
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vitals Tracking (Last 5 Visits)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: _historicalVitals.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.bloodPressureSystolic.toDouble())).toList(),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                ),
                LineChartBarData(
                  spots: _historicalVitals.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.heartRate.toDouble())).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                ),
              ],
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.2))),
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(Icons.circle, color: Colors.red, size: 12), SizedBox(width: 4), Text('BP (Systolic)'),
            SizedBox(width: 16),
            Icon(Icons.circle, color: Colors.blue, size: 12), SizedBox(width: 4), Text('Heart Rate'),
          ],
        ),
        const SizedBox(height: 24),
        _buildAIPanel(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.science),
            label: const Text('View Lab Reports'),
            onPressed: () => _showLabResultsDialog(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text('Message via WhatsApp'),
            onPressed: () async {
              final url = Uri.parse('https://wa.me/15551234567?text=Hello,%20this%20is%20Dr.%20${Uri.encodeComponent(widget.appointment.doctorName)}%20regarding%20your%20teleconsultation.');
              try {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp or Browser')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ),
      ],
    );
  }

  void _simulateVoiceToText() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listening... Speak now.'), duration: Duration(seconds: 2)));
        _speech.listen(
          onResult: (val) => setState(() {
            _notesController.text = val.recognizedWords;
          }),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission denied or speech recognition unavailable.')));
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Widget _buildAIPanel() {
    // Simple mock logic: if last BP systolic > 120, flag hypertension risk
    final latestVitals = _historicalVitals.last;
    final isHighBP = latestVitals.bloodPressureSystolic > 120;
    
    if (isHighBP) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.3))),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('AI Insight: Hypertension Risk', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              Text('Systolic BP is ${latestVitals.bloodPressureSystolic} mmHg. Consider reviewing cardiovascular health.', style: const TextStyle(fontSize: 12, color: Colors.red)),
            ]))
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('AI Insight: Vitals are stable and within normal ranges.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
          ],
        ),
      );
    }
  }

  void _showLabResultsDialog() {
    showDialog(context: context, builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Expanded(child: Text('Comprehensive Metabolic Panel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
            ]),
            const Divider(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  _buildLabRow('Glucose', '95 mg/dL', '70-99', false),
                  const Divider(),
                  _buildLabRow('Cholesterol (Total)', '240 mg/dL', '<200', true),
                  const Divider(),
                  _buildLabRow('Triglycerides', '180 mg/dL', '<150', true),
                  const Divider(),
                  _buildLabRow('Calcium', '9.4 mg/dL', '8.6-10.2', false),
                ],
              ),
            )
          ]
        )
      )
    ));
  }

  Widget _buildLabRow(String test, String result, String ref, bool isAbnormal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: Text(test, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text(result, style: TextStyle(color: isAbnormal ? Colors.red : Colors.black, fontWeight: isAbnormal ? FontWeight.bold : FontWeight.normal))),
          Expanded(flex: 1, child: Text(ref, style: const TextStyle(color: Colors.grey))),
          if (isAbnormal) const Icon(Icons.warning, color: Colors.red, size: 16) else const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildRightColumn() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Clinical Encounter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          
          if (_patientRecords.isNotEmpty) ...[
            SwitchListTile(
              title: const Text('Create New Problem / Diagnosis', style: TextStyle(fontSize: 14)),
              value: _isNewProblem,
              onChanged: (val) => setState(() => _isNewProblem = val),
              contentPadding: EdgeInsets.zero,
            ),
            if (!_isNewProblem) ...[
              DropdownButtonFormField<String>(
                value: _selectedRecordId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Select Existing Problem',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _patientRecords.map((r) => DropdownMenuItem(
                  value: r.id,
                  child: Text(r.diagnosis, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (val) => setState(() => _selectedRecordId = val),
              ),
              const SizedBox(height: 16),
            ]
          ],

          if (_isNewProblem || _patientRecords.isEmpty)
            TextFormField(
              controller: _diagnosisController,
              decoration: InputDecoration(
                labelText: 'Diagnosis / Impression',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Progress Notes & Treatment Plan',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : Colors.grey),
                onPressed: _simulateVoiceToText,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPrescriptionsSection(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _isLoading = true);
                        try {
                          if (_isNewProblem || _patientRecords.isEmpty) {
                            await widget.provider.addRecord(
                              widget.appointment.patientId,
                              _diagnosisController.text.trim(),
                              _notesController.text.trim(),
                              _prescriptions,
                            );
                          } else {
                            if (_selectedRecordId != null) {
                              await widget.provider.updateRecord(
                                _selectedRecordId!,
                                _notesController.text.trim(),
                                _prescriptions,
                              );
                            }
                          }
                          // Mark appointment as completed
                          await widget.provider.updateAppointmentStatus(widget.appointment.id, AppointmentStatus.completed);
                          
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
              icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
              label: Text(_isLoading ? 'Saving...' : 'Save Encounter'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPrescriptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Prescriptions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (_prescriptions.isNotEmpty)
          ..._prescriptions.map((p) => ListTile(
            dense: true,
            leading: const Icon(Icons.medication, color: Colors.teal),
            title: Text(p.name),
            subtitle: Text('${p.dosage} - Qty: ${p.quantity}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => setState(() => _prescriptions.remove(p)),
            ),
          )).toList(),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _showAddPrescriptionDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Medicine'),
        )
      ],
    );
  }

  void _showAddPrescriptionDialog() {
    String? selectedMedicineId;
    String? selectedMedicineName;
    final dosageController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Medicine to Prescription'),
              content: StreamBuilder<List<InventoryItem>>(
                stream: widget.provider.inventoryStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                  final inventory = snapshot.data ?? [];
                  
                  // Clean up selection if item disappears from DB
                  if (selectedMedicineId != null && !inventory.any((i) => i.id == selectedMedicineId)) {
                    selectedMedicineId = null;
                    selectedMedicineName = null;
                  }

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Select Medicine'),
                          value: selectedMedicineId,
                          items: inventory.map((item) {
                            final isOutOfStock = item.currentStock == 0;
                            return DropdownMenuItem<String>(
                              value: item.id,
                              enabled: !isOutOfStock, // STRICT DISABLED BLOCKING
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.name,
                                      style: TextStyle(color: isOutOfStock ? Colors.red : null),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isOutOfStock)
                                    const Text('Out of Stock', style: TextStyle(color: Colors.red, fontSize: 12))
                                  else
                                    Text('In Stock: ${item.currentStock}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedMedicineId = val;
                                selectedMedicineName = inventory.firstWhere((i) => i.id == val).name;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: dosageController,
                          decoration: const InputDecoration(labelText: 'Dosage (e.g. 1 pill twice a day)'),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Quantity'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final dosage = dosageController.text.trim();
                    final qty = int.tryParse(quantityController.text) ?? 0;
                    if (selectedMedicineId != null && selectedMedicineName != null && dosage.isNotEmpty && qty > 0) {
                      setState(() {
                        _prescriptions.add(
                          PrescriptionItem(
                            id: selectedMedicineId!,
                            name: selectedMedicineName!,
                            dosage: dosage,
                            quantity: qty,
                          )
                        );
                      });
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Add'),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800, // Max width, will shrink on mobile
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${widget.appointment.patientName} - Health Summary',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLeftColumn(),
                          const SizedBox(height: 24),
                          _buildRightColumn(),
                        ],
                      );
                    } else {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: _buildLeftColumn()),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: _buildRightColumn()),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
