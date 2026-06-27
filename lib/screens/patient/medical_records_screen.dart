import 'package:flutter/material.dart';
import '../../providers/patient_provider.dart';
import '../../models/medical_record.dart';
import '../../widgets/record_card.dart';

class MedicalRecordsScreen extends StatelessWidget {
  final PatientProvider provider;

  const MedicalRecordsScreen({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Medical Records'),
      ),
      body: StreamBuilder<List<MedicalRecord>>(
        stream: provider.medicalRecordsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No medical records found.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              return RecordCard(record: records[index]);
            },
          );
        },
      ),
    );
  }
}
