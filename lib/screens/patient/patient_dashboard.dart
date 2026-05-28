import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../models/medical_record.dart';
import '../../models/health_advisory.dart';
import '../../models/ambulance.dart';
import '../../widgets/record_card.dart';
import '../../widgets/health_advisory_carousel.dart';
import '../../widgets/ambulance_tracking_card.dart';
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
                authProvider.signOut();
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ],
        ),
        body: Consumer<PatientProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                // Health advisories from district admin
                StreamBuilder<List<HealthAdvisory>>(
                  stream: provider.activeAdvisoriesStream,
                  builder: (context, snapshot) {
                    final advisories = snapshot.data ?? [];
                    if (advisories.isEmpty) return const SizedBox.shrink();
                    return HealthAdvisoryCarousel(advisories: advisories);
                  },
                ),

                // Active Emergency Ambulance Request
                StreamBuilder<Ambulance?>(
                  stream: provider.activeAmbulanceStream,
                  builder: (context, snapshot) {
                    final ambulance = snapshot.data;
                    if (ambulance == null) return const SizedBox.shrink();
                    return AmbulanceTrackingCard(
                      ambulance: ambulance,
                      onCancel: () => provider.cancelAmbulanceRequest(ambulance.id),
                    );
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'My Medical Records',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: StreamBuilder<List<MedicalRecord>>(
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          return RecordCard(record: records[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final provider = Provider.of<PatientProvider>(context, listen: false);
            try {
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

              Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
              );

              await provider.requestEmergencyAmbulance(position.latitude, position.longitude);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emergency Ambulance Requested! Dispatching vehicle...')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
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
