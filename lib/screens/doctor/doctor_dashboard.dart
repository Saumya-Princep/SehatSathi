import 'package:flutter/material.dart';
import '../../utils/image_utils.dart';

import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../models/appointment.dart';
import '../../models/user_model.dart' as model;
import '../../services/firestore_service.dart';
import '../auth/login_screen.dart';
import '../../l10n/app_localizations.dart';

// New Widgets
import 'widgets/analytics_cards.dart';
import 'widgets/patient_queue_sidebar.dart';
import 'widgets/schedule_canvas.dart';
import 'widgets/interactive_patient_modal.dart';
import '../../widgets/health_advisory_carousel.dart';
import '../../models/health_advisory.dart';
import '../../models/lab_report.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/language_selector.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/profile_screen.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Error: Not logged in')));
    }

    return ChangeNotifierProvider(
      create: (_) => DoctorProvider(
        doctorId: user.uid,
        doctorName: user.name,
        phcId: user.assignedPhcId ?? 'phc_1',
      ),
      child: _DoctorDashboardView(uid: user.uid),
    );
  }
}

class _DoctorDashboardView extends StatefulWidget {
  final String uid;
  const _DoctorDashboardView({Key? key, required this.uid}) : super(key: key);

  @override
  _DoctorDashboardViewState createState() => _DoctorDashboardViewState();
}

class _DoctorDashboardViewState extends State<_DoctorDashboardView> {
  void _openPatientModal(Appointment appointment) {
    final provider = Provider.of<DoctorProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => InteractivePatientModal(
        provider: provider,
        appointment: appointment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DoctorProvider>(context);

    return StreamBuilder<model.UserModel?>(
      stream: FirestoreService().getDoctorStream(widget.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final docModel = userSnapshot.data;
        final isPresent = docModel?.isPresent ?? false;

        if (!isPresent) {
          return Scaffold(
            appBar: AppBar(
              title: FittedBox(fit: BoxFit.scaleDown, child: Text(provider.doctorName)),

            ),
            drawer: Drawer(
                            child: SafeArea(
                top: false,
                child: Column(
                children: [
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final docModel = authProvider.userModel;
                      return GestureDetector(
                      onTap: () {
                        final u = authProvider.userModel;
                        if (u != null) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProfileScreen(user: u)),
                          );
                        }
                      },
                      child: UserAccountsDrawerHeader(
                        accountName: Text(docModel?.name ?? 'Doctor'),
                        accountEmail: Text(docModel?.contact ?? 'Doctor Portal'),
                        currentAccountPicture: InkWell(
                          onTap: () => authProvider.uploadProfilePicture(),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            backgroundImage: docModel?.profilePicUrl != null ? getProfileImageProvider(docModel!.profilePicUrl!) : null,
                            child: docModel?.profilePicUrl == null ? const Icon(Icons.medical_services, size: 40, color: Colors.blue) : null,
                          ),
                        ),
                      ),
                    );
                    }
                  ),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final isDark = auth.themeMode == ThemeMode.dark;
                      return SwitchListTile(
                        title: const Text('Dark Mode'),
                        value: isDark,
                        onChanged: (val) => auth.setThemeMode(val),
                        secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                      );
                    },
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
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Provider.of<AuthProvider>(context, listen: false).signOut();
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              )
              ),
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.do_not_disturb_alt, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'You are currently marked as not present at the hospital.\n\nPlease contact the administrator to begin your shift and view patient records.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return StreamBuilder<List<Appointment>>(
          stream: provider.liveAppointmentsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            
            final appointments = snapshot.data ?? [];
            final waitingQueue = appointments.where((a) => a.status == AppointmentStatus.scheduled || a.status == AppointmentStatus.checkedIn).toList();
            final completed = appointments.where((a) => a.status == AppointmentStatus.completed).length;
            
            // Dynamic calculations for analytics
            // pendingReview will be calculated by the nested StreamBuilder below
            final emergencyFlags = appointments.where((a) {
              final reason = a.reason.toLowerCase();
              return reason.contains('emergency') || reason.contains('urgent') || reason.contains('pain') || reason.contains('chest');
            }).length;
            final avgWaitTime = waitingQueue.isEmpty ? 0 : (waitingQueue.length * 12); // Estimated 12 mins per waiting patient

            return Scaffold(
              appBar: AppBar(
                title: FittedBox(fit: BoxFit.scaleDown, child: Text(provider.doctorName)),

              ),
          body: SafeArea(
            bottom: true,
            child: LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScreen = constraints.maxWidth > 800;

              Widget mainContent = SingleChildScrollView(
                child: Column(
                  children: [
                    StreamBuilder<List<HealthAdvisory>>(
                      stream: provider.activeAdvisoriesStream,
                      builder: (context, snapshot) {
                        final advisories = snapshot.data ?? [];
                        if (advisories.isEmpty) return const SizedBox.shrink();
                        return HealthAdvisoryCarousel(advisories: advisories);
                      },
                    ),
                    StreamBuilder<List<LabReport>>(
                      stream: provider.pendingLabReportsStream,
                      builder: (context, labSnapshot) {
                        final pendingLabCount = labSnapshot.data?.length ?? 0;
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              AnalyticsCards(
                                totalAppointments: appointments.length,
                                completedAppointments: completed,
                                pendingReview: pendingLabCount, 
                                emergencyFlags: emergencyFlags, 
                                avgWaitTime: avgWaitTime, 
                              ),
                            ],
                          ),
                        );
                      }
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Today\'s Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          ScheduleCanvas(
                            appointments: appointments,
                            onAppointmentTap: _openPatientModal,
                            onStatusChange: (apt, status) {
                              provider.updateAppointmentStatus(apt.id, status);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              if (isLargeScreen) {
                return Row(
                  children: [
                    Expanded(child: mainContent),
                    PatientQueueSidebar(
                      queue: waitingQueue,
                      onPatientTap: _openPatientModal,
                    ),
                  ],
                );
              } else {
                return mainContent;
              }
            },
          ),
          ),
              drawer: Drawer(
                                child: SafeArea(
                  top: false,
                  child: Column(
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        final docModel = authProvider.userModel;
                        return GestureDetector(
                      onTap: () {
                        final u = authProvider.userModel;
                        if (u != null) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProfileScreen(user: u)),
                          );
                        }
                      },
                      child: UserAccountsDrawerHeader(
                          accountName: Text(docModel?.name ?? 'Doctor'),
                          accountEmail: Text(docModel?.contact ?? 'Doctor Portal'),
                          currentAccountPicture: InkWell(
                            onTap: () => authProvider.uploadProfilePicture(),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage: docModel?.profilePicUrl != null ? getProfileImageProvider(docModel!.profilePicUrl!) : null,
                              child: docModel?.profilePicUrl == null ? const Icon(Icons.medical_services, size: 40, color: Colors.blue) : null,
                            ),
                          ),
                        ),
                    );
                      }
                    ),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final isDark = auth.themeMode == ThemeMode.dark;
                        return SwitchListTile(
                          title: const Text('Dark Mode'),
                          value: isDark,
                          onChanged: (val) => auth.setThemeMode(val),
                          secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                        );
                      },
                    ),
                    if (MediaQuery.of(context).size.width <= 800)
                      Expanded(
                        child: PatientQueueSidebar(
                          queue: waitingQueue,
                          onPatientTap: (apt) {
                            Navigator.pop(context);
                            _openPatientModal(apt);
                          },
                        ),
                      )
                    else
                      const Spacer(),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Logout', style: TextStyle(color: Colors.red)),
                      onTap: () {
                        Provider.of<AuthProvider>(context, listen: false).signOut();
                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                )
                ),
              ),
            );
          }
        );
      }
    );
  }
}
