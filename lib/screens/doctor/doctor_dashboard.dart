import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../models/appointment.dart';
import '../../models/user_model.dart' as model;
import '../../services/firestore_service.dart';
import '../auth/login_screen.dart';

// New Widgets
import 'widgets/analytics_cards.dart';
import 'widgets/patient_queue_sidebar.dart';
import 'widgets/schedule_canvas.dart';
import 'widgets/interactive_patient_modal.dart';
import '../../widgets/health_advisory_carousel.dart';
import '../../models/health_advisory.dart';

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
              title: Text(provider.doctorName),
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
            final pendingReview = appointments.where((a) => a.status == AppointmentStatus.inProgress).length;
            final emergencyFlags = appointments.where((a) {
              final reason = a.reason.toLowerCase();
              return reason.contains('emergency') || reason.contains('urgent') || reason.contains('pain') || reason.contains('chest');
            }).length;
            final avgWaitTime = waitingQueue.isEmpty ? 0 : (waitingQueue.length * 12); // Estimated 12 mins per waiting patient

            return Scaffold(
              appBar: AppBar(
                title: Text(provider.doctorName),
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
          body: LayoutBuilder(
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: AnalyticsCards(
                        totalAppointments: appointments.length,
                        completedAppointments: completed,
                        pendingReview: pendingReview, 
                        emergencyFlags: emergencyFlags, 
                        avgWaitTime: avgWaitTime, 
                      ),
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
          drawer: MediaQuery.of(context).size.width <= 800
              ? Drawer(
                  child: PatientQueueSidebar(
                    queue: waitingQueue,
                    onPatientTap: (apt) {
                      Navigator.pop(context); // Close drawer
                      _openPatientModal(apt);
                    },
                  ),
                )
              : null,
            );
          }
        );
      }
    );
  }
}
