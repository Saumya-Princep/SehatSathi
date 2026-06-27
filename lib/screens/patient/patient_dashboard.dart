import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../models/medical_record.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/health_advisory.dart';
import '../../models/ambulance.dart';
import '../../models/appointment.dart';
import 'medical_records_screen.dart';
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
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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

                  // Active Queue Tokens
                  StreamBuilder<List<Appointment>>(
                    stream: provider.activeAppointmentsStream,
                    builder: (context, snapshot) {
                      final activeAppointments = snapshot.data ?? [];
                      if (activeAppointments.isEmpty) return const SizedBox.shrink();
                      
                      return Column(
                        children: activeAppointments.map((apt) {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          return Card(
                            color: isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.shade50,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Text('#${apt.queueNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              title: Text('Waiting for Doctor (Token #${apt.queueNumber})', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.orange.shade300 : Colors.orange.shade800)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Reason: ${apt.reason}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                                  const SizedBox(height: 2),
                                  Text('Assigned to: ${apt.doctorName}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.video_call, color: Colors.blue),
                                    onPressed: () async {
                                      final url = Uri.parse('https://wa.me/15551234567?text=Hello%20Dr.%20${Uri.encodeComponent(apt.doctorName)},%20I%20am%20ready%20for%20my%20teleconsultation.%20(Appointment%20ID:%20${apt.id})');
                                      try {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp or Browser')));
                                        }
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                    onPressed: () {
                                      provider.cancelAppointment(apt.id);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left the doctor queue.')));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Icon(Icons.queue, size: 36, color: Theme.of(context).colorScheme.primary),
                        title: const Text('Join Doctor Queue', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Request a consultation for a new or existing issue.'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => JoinQueueDialog(
                              provider: provider,
                              patientName: user?.name ?? 'Unknown Patient',
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  StreamBuilder<List<MedicalRecord>>(
                    stream: provider.medicalRecordsStream,
                    builder: (context, snapshot) {
                      final allRecords = snapshot.data ?? [];
                      if (allRecords.isEmpty) return const SizedBox.shrink();
                      
                      final latestRecord = allRecords.first;
                      if (latestRecord.prescriptions == null || latestRecord.prescriptions!.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('My Daily Medications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                ...latestRecord.prescriptions!.map((p) => CheckboxListTile(
                                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(p.dosage),
                                  value: false,
                                  onChanged: (val) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked ${p.name} as taken.')));
                                  },
                                )).toList(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Medical Records',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MedicalRecordsScreen(provider: provider),
                              ),
                            );
                          },
                          child: const Text('More'),
                        ),
                      ],
                    ),
                  ),

                  StreamBuilder<List<MedicalRecord>>(
                    stream: provider.medicalRecordsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final allRecords = snapshot.data ?? [];
                      if (allRecords.isEmpty) {
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
                      
                      // Show only up to 3 recent records on the dashboard
                      final recentRecords = allRecords.take(3).toList();
                      
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: recentRecords.length,
                        itemBuilder: (context, index) {
                          return RecordCard(record: recentRecords[index]);
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: Builder(
          builder: (fabContext) => FloatingActionButton.extended(
            onPressed: () async {
              final provider = Provider.of<PatientProvider>(fabContext, listen: false);
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
      ),
    );
  }


}

class JoinQueueDialog extends StatefulWidget {
  final PatientProvider provider;
  final String patientName;
  const JoinQueueDialog({Key? key, required this.provider, required this.patientName}) : super(key: key);

  @override
  _JoinQueueDialogState createState() => _JoinQueueDialogState();
}

class _JoinQueueDialogState extends State<JoinQueueDialog> {
  final _reasonCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join Doctor Queue'),
      content: _isLoading 
        ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.blue)))
        : Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What is your problem or symptom?', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('We will automatically assign you to the correct specialist.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'E.g. I have severe chest pain and palpitations', 
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      actions: [
        if (!_isLoading) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (!_isLoading) ElevatedButton(
          onPressed: () async {
            if (_reasonCtrl.text.trim().isEmpty) return;
            setState(() => _isLoading = true);
            try {
              final result = await widget.provider.joinDoctorQueue(widget.patientName, _reasonCtrl.text.trim());
              if (mounted) {
                Navigator.pop(context); // Close the entry dialog
                _showSuccessDialog(context, result);
              }
            } catch (e) {
              if (mounted) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
          child: const Text('Join Queue'),
        ),
      ],
    );
  }

  void _showSuccessDialog(BuildContext context, Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Queue Joined!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text('You have been assigned to:', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('${result['doctorName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${result['specialty']}', style: const TextStyle(color: Colors.blue)),
            const SizedBox(height: 24),
            const Text('Your Token Number', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('#${result['tokenNumber']}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.orange)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          )
        ],
      )
    );
  }
}
