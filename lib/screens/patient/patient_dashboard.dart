import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../models/medical_record.dart';
import '../../widgets/record_card.dart';
import '../auth/login_screen.dart';
import 'package:geolocator/geolocator.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    final patientId = user?.uid ?? 'mock_patient_id';
    final phcId = user?.assignedPhcId ?? 'phc_1';

    return ChangeNotifierProvider(
      create: (_) => PatientProvider(patientId: patientId, phcId: phcId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My EHR Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                authProvider.signOut();
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ],
        ),
        body: Consumer<PatientProvider>(
          builder: (context, provider, child) {
            return StreamBuilder<List<MedicalRecord>>(
              stream: provider.medicalRecordsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = snapshot.data ?? [];
                if (records.isEmpty) {
                  return const Center(child: Text('No medical records found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    return RecordCard(record: records[index]);
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final provider = Provider.of<PatientProvider>(context, listen: false);
            try {
              // Check permissions
              LocationPermission permission = await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
                if (permission == LocationPermission.denied) {
                  throw Exception('Location permissions are denied');
                }
              }
              if (permission == LocationPermission.deniedForever) {
                throw Exception('Location permissions are permanently denied.');
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fetching current location...')),
                );
              }

              // Get current GPS position
              Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
              );

              await provider.requestEmergencyAmbulance(position.latitude, position.longitude);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emergency Ambulance Requested! Tracking started.')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            }
          },
          backgroundColor: Theme.of(context).colorScheme.error,
          icon: const Icon(Icons.emergency, color: Colors.white),
          label: const Text('Request Ambulance', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
