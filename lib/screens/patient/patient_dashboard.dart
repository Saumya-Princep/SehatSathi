import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/image_utils.dart';

import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firestore_service.dart';
import '../../models/medical_record.dart';
import '../../models/lab_report.dart';
import '../../models/user_model.dart';

import '../../models/health_advisory.dart';
import '../../models/ambulance.dart';
import '../../models/appointment.dart';
import 'medical_records_screen.dart';
import '../../widgets/record_card.dart';
import '../../widgets/health_advisory_carousel.dart';
import '../../widgets/ambulance_tracking_card.dart';
import '../../widgets/vitals_summary_widget.dart';
import '../auth/login_screen.dart';
import '../../widgets/language_selector.dart';
import '../../models/vitals.dart';
import 'package:geolocator/geolocator.dart';
import 'widgets/add_dependent_dialog.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/profile_screen.dart';
class PatientDashboard extends StatelessWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final activePatient = authProvider.activePatient;
        final patientId = activePatient?.uid ?? 'mock_patient_id';
        final phcId = activePatient?.assignedPhcId ?? 'phc_1';

        return ChangeNotifierProvider(
          key: ValueKey(patientId),
          create: (_) => PatientProvider(patientId: patientId, phcId: phcId),
          child: Scaffold(
        appBar: AppBar(
          title: FittedBox(fit: BoxFit.scaleDown, child: Text(AppLocalizations.of(context)!.myEhrDashboard)),
          actions: [],
        ),
        drawer: Drawer(
                    child: SafeArea(
            top: false,
            child: Column(
            children: [
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final user = authProvider.userModel;
                  final activeUser = authProvider.activePatient;
                  return GestureDetector(
                    onTap: () {
                      final u = authProvider.activePatient;
                      if (u != null) {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileScreen(user: u)),
                        );
                      }
                    },
                    child: UserAccountsDrawerHeader(
                      accountName: Text(activeUser?.name ?? 'Patient'),
                      accountEmail: Text(activeUser?.contact ?? 'Patient Portal'),
                      currentAccountPicture: InkWell(
                        onTap: () => authProvider.uploadProfilePicture(),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: activeUser?.profilePicUrl != null ? getProfileImageProvider(activeUser!.profilePicUrl!) : null,
                          child: activeUser?.profilePicUrl == null ? const Icon(Icons.person, size: 40, color: Colors.blue) : null,
                        ),
                      ),
                    ),
                  );
                }
              ),
              const Divider(),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final mainUser = auth.userModel;
                  if (mainUser == null) return const SizedBox.shrink();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text('Family Members', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text('${mainUser.name} (Me)'),
                        trailing: auth.activePatient?.uid == mainUser.uid ? const Icon(Icons.check, color: Colors.green) : null,
                        onTap: () {
                          auth.switchActivePatient(mainUser);
                          Navigator.pop(context);
                        },
                      ),
                      StreamBuilder<List<UserModel>>(
                        stream: FirestoreService().getDependentsStream(mainUser.uid),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          final dependents = snapshot.data!;
                          return Column(
                            children: dependents.map((dep) {
                              return ListTile(
                                leading: const Icon(Icons.child_care),
                                title: Text(dep.name),
                                trailing: auth.activePatient?.uid == dep.uid ? const Icon(Icons.check, color: Colors.green) : null,
                                onTap: () {
                                  auth.switchActivePatient(dep);
                                  Navigator.pop(context);
                                },
                              );
                            }).toList(),
                          );
                        }
                      ),
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('Add Family Member'),
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (_) => AddDependentDialog(parentId: mainUser.uid),
                          );
                        },
                      ),
                      const Divider(),
                    ],
                  );
                }
              ),
              Consumer<PatientProvider>(
                builder: (context, provider, _) {
                  return SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.offlineView),
                    value: provider.isOffline,
                    onChanged: (_) => provider.toggleOfflineMode(),
                    secondary: const Icon(Icons.cloud_off),
                  );
                }
              ),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final isDark = auth.themeMode == ThemeMode.dark;
                  return SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.darkMode),
                    value: isDark,
                    onChanged: (val) => auth.setThemeMode(val),
                    secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  );
                },
              ),
              Consumer<PatientProvider>(
                builder: (context, provider, _) {
                  return ListTile(
                    leading: const Icon(Icons.folder_shared),
                    title: Text(AppLocalizations.of(context)!.allMedicalRecords),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MedicalRecordsScreen(provider: provider),
                        ),
                      );
                    },
                  );
                }
              ),
                            ListTile(
                leading: const Icon(Icons.language),
                title: Text(AppLocalizations.of(context)?.language ?? 'Language'),
                trailing: const LanguageSelector(),
              ),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(AppLocalizations.of(context)!.logout, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  authProvider.signOut();
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              ),
              const SizedBox(height: 16),
            ],
          )
          ),
        ),
        floatingActionButton: Consumer<PatientProvider>(
          builder: (context, provider, _) {
            return FloatingActionButton.extended(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.emergency),
              label: const Text('Ambulance Track'),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Ambulance Track'),
                    content: const Text('Call an ambulance to your current location?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(context, true), 
                        child: const Text('Confirm')
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  try {
                    LocationPermission permission = await Geolocator.checkPermission();
                    if (permission == LocationPermission.denied) {
                      permission = await Geolocator.requestPermission();
                      if (permission == LocationPermission.denied) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied')));
                        return;
                      }
                    }
                    
                    if (permission == LocationPermission.deniedForever) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission permanently denied')));
                      return;
                    }
                    
                    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                    await provider.requestEmergencyAmbulance(position.latitude, position.longitude);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ambulance requested successfully!')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              },
            );
          },
        ),
        body: SafeArea(
          bottom: true,
          child: Consumer<PatientProvider>(
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
                        title: Text(AppLocalizations.of(context)!.joinDoctorQueue, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(AppLocalizations.of(context)!.requestConsultation),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => JoinQueueDialog(
                              provider: provider,
                              patientName: authProvider.activePatient?.name ?? 'Unknown Patient',
                              patientAge: authProvider.activePatient?.age ?? 0,
                            ),
                          );
                        },
                      ),
                    ),
                  ),





                  StreamBuilder<List<Vitals>>(
                    stream: provider.vitalsStream,
                    builder: (context, snapshot) {
                      final vitals = snapshot.data ?? [];
                      if (vitals.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context)!.myRecentVitals, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                VitalsSummaryWidget(vitalsList: vitals),
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
                        Text(
                          AppLocalizations.of(context)!.myMedicalRecords,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          child: Text(AppLocalizations.of(context)!.more),
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
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  AppLocalizations.of(context)!.noMedicalRecords,
                                  style: const TextStyle(color: Colors.grey, fontSize: 16),
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
        ),
      ),
    );
  },
);
  }


}

class JoinQueueDialog extends StatefulWidget {
  final PatientProvider provider;
  final String patientName;
  final int patientAge;
  const JoinQueueDialog({Key? key, required this.provider, required this.patientName, required this.patientAge}) : super(key: key);

  @override
  _JoinQueueDialogState createState() => _JoinQueueDialogState();
}

class _JoinQueueDialogState extends State<JoinQueueDialog> {
  final _reasonCtrl = TextEditingController();
  bool _isLoading = false;
  String? _selectedPhcId;
  List<Map<String, dynamic>> _phcs = [];

  @override
  void initState() {
    super.initState();
    _loadPhcs();
  }

  Future<void> _loadPhcs() async {
    List<Map<String, dynamic>> phcs = [];
    bool usedFallback = false;
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        
        // Try Overpass API (OpenStreetMap) to get real hospitals for free
        try {
          final query = '[out:json];node(around:5000,${position.latitude},${position.longitude})[amenity=hospital];out;';
          final url = 'https://overpass-api.de/api/interpreter?data=${Uri.encodeQueryComponent(query)}';
          final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['elements'] != null) {
              final elements = data['elements'] as List;
              for (var element in elements) {
                if (element['tags'] != null && element['tags']['name'] != null) {
                  phcs.add({
                    'id': element['id'].toString(),
                    'name': element['tags']['name'],
                    'latitude': element['lat'],
                    'longitude': element['lon']
                  });
                }
              }
            }
          }
          
          if (phcs.isEmpty) {
            usedFallback = true;
          }
        } catch (e) {
          usedFallback = true;
        }

        if (usedFallback || phcs.isEmpty) {
          phcs = await FirestoreService().getAllPhcs();
        }
        
        for (var phc in phcs) {
          double lat = (phc['latitude'] ?? 37.422) as double;
          double lng = (phc['longitude'] ?? -122.084) as double;
          double distanceInMeters = Geolocator.distanceBetween(position.latitude, position.longitude, lat, lng);
          phc['distance'] = distanceInMeters;
          phc['displayName'] = '${phc['name']}';
        }
        
        phcs.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      } else {
        phcs = await FirestoreService().getAllPhcs();
        for (var phc in phcs) {
          phc['displayName'] = phc['name'];
        }
      }
    } catch (e) {
      phcs = await FirestoreService().getAllPhcs();
      for (var phc in phcs) {
        phc['displayName'] = phc['name'];
      }
    }

    if (mounted) {
      setState(() {
        _phcs = phcs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join Doctor Queue'),
      content: _isLoading 
        ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.blue)))
        : SingleChildScrollView(
          child: Column(
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
            const SizedBox(height: 16),
            const Text('Which hospital are you at?', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _phcs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : DropdownMenu<String>(
                    width: MediaQuery.of(context).size.width * 0.7,
                    hintText: 'Search Hospital',
                    enableFilter: true,
                    dropdownMenuEntries: _phcs.map((phc) {
                      return DropdownMenuEntry<String>(
                        value: phc['id'],
                        label: phc['displayName'] ?? phc['name'],
                      );
                    }).toList(),
                    onSelected: (val) {
                      setState(() {
                        _selectedPhcId = val;
                      });
                    },
                  ),
            ],
          ),
        ),
      actions: [
        if (!_isLoading) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (!_isLoading) ElevatedButton(
          onPressed: () async {
            if (_reasonCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your symptoms.')));
              return;
            }
            if (_selectedPhcId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a hospital.')));
              return;
            }
            setState(() => _isLoading = true);
            try {
              final result = await widget.provider.joinDoctorQueue(widget.patientName, widget.patientAge, _reasonCtrl.text.trim(), _selectedPhcId!);
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



