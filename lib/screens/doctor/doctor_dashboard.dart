import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../models/medical_record.dart';
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
  
  String? _selectedPatientId;
  List<Map<String, dynamic>> _patientsList = [];
  bool _isLoadingPatients = true;
  bool _isLoading = false;

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New EHR'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isLoadingPatients
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
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
                decoration: const InputDecoration(labelText: 'Diagnosis'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes & Prescription'),
                maxLines: 3,
              ),
            ],
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
                      );
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        )
      ],
    );
  }
}
