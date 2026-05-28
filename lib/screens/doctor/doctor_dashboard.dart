import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../models/medical_record.dart';
import '../../models/inventory_item.dart';
import '../../widgets/record_card.dart';
import '../auth/login_screen.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    return ChangeNotifierProvider(
      create: (_) => DoctorProvider(
        doctorId: user?.uid ?? 'mock_doc_id',
        doctorName: user?.name ?? 'Doctor',
        phcId: user?.assignedPhcId ?? 'phc_1',
      ),
      child: const _DoctorDashboardView(),
    );
  }
}

class _DoctorDashboardView extends StatelessWidget {
  const _DoctorDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DoctorProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final isDark = auth.themeMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => auth.toggleTheme(!isDark),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily Attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Switch(
                  value: provider.isCheckedIn,
                  onChanged: (val) => provider.toggleAttendance(),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MedicalRecord>>(
              stream: provider.doctorRecordsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = snapshot.data ?? [];
                if (records.isEmpty) {
                  return const Center(child: Text('No records created yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    return RecordCard(record: records[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => _NewRecordDialog(provider: provider),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NewRecordDialog extends StatefulWidget {
  final DoctorProvider provider;

  const _NewRecordDialog({Key? key, required this.provider}) : super(key: key);

  @override
  _NewRecordDialogState createState() => _NewRecordDialogState();
}

class _NewRecordDialogState extends State<_NewRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  final _dosageController = TextEditingController();
  final _qtyController = TextEditingController(text: '10');
  
  String? _selectedPatientId;
  List<Map<String, dynamic>> _patientsList = [];
  bool _isLoadingPatients = true;
  bool _isLoading = false;

  // Prescriptions state
  List<PrescriptionItem> _prescriptions = [];
  InventoryItem? _selectedMedicine;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      final list = await widget.provider.getPatientsList();
      if (mounted) {
        setState(() {
          _patientsList = list;
          _isLoadingPatients = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPatients = false);
    }
  }

  void _addPrescriptionItem() {
    if (_selectedMedicine == null || _dosageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a medicine and specify dosage.')),
      );
      return;
    }
    final qty = int.tryParse(_qtyController.text) ?? 1;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity.')),
      );
      return;
    }

    setState(() {
      _prescriptions.add(
        PrescriptionItem(
          id: _selectedMedicine!.id,
          name: _selectedMedicine!.name,
          dosage: _dosageController.text.trim(),
          quantity: qty,
          isDispensed: false,
        ),
      );
      // Reset inputs
      _dosageController.clear();
      _qtyController.text = '10';
      _selectedMedicine = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Medical EHR'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isLoadingPatients
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedPatientId,
                        decoration: const InputDecoration(labelText: 'Select Patient'),
                        isExpanded: true,
                        items: _patientsList.map((p) {
                          return DropdownMenuItem<String>(
                            value: p['id'],
                            child: Text(p['name']),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedPatientId = val);
                        },
                        validator: (val) => val == null ? 'Please select a patient' : null,
                      ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _diagnosisController,
                  decoration: const InputDecoration(labelText: 'Diagnosis (e.g. Malaria, Flu)'),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Clinical Notes'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Prescribe Medications',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                
                // Medicines Stream Dropdown
                StreamBuilder<List<InventoryItem>>(
                  stream: widget.provider.inventoryStream,
                  builder: (context, snapshot) {
                    final meds = snapshot.data ?? [];
                    if (meds.isEmpty) {
                      return const Text('No medicines in pharmacy inventory.', style: TextStyle(color: Colors.grey, fontSize: 12));
                    }
                    return DropdownButtonFormField<InventoryItem>(
                      value: _selectedMedicine,
                      decoration: const InputDecoration(labelText: 'Choose Medicine'),
                      isExpanded: true,
                      items: meds.map((m) {
                        return DropdownMenuItem<InventoryItem>(
                          value: m,
                          child: Text('${m.name} (In stock: ${m.currentStock})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedMedicine = val);
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _dosageController,
                        decoration: const InputDecoration(labelText: 'Dosage (e.g., 1-0-1 after food)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Qty'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _addPrescriptionItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add to Prescription'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
                
                // Added prescriptions list
                if (_prescriptions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Prescribed Meds:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _prescriptions.length,
                      itemBuilder: (context, index) {
                        final p = _prescriptions[index];
                        return ListTile(
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${p.dosage} | Qty: ${p.quantity}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _prescriptions.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    try {
                      await widget.provider.addRecord(
                        _selectedPatientId!,
                        _diagnosisController.text.trim(),
                        _notesController.text.trim(),
                        _prescriptions,
                      );
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save EHR'),
        )
      ],
    );
  }
}
