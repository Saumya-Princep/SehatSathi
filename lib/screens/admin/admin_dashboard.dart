import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/ambulance.dart';
import '../../models/attendance.dart';
import '../../models/user_model.dart';
import '../../widgets/alert_banner.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    return ChangeNotifierProvider(
      create: (_) => AdminProvider(phcId: user?.assignedPhcId ?? 'phc_1'),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('District Health Control'),
            bottom: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(icon: Icon(Icons.analytics), text: 'Epidemiology'),
                Tab(icon: Icon(Icons.people_alt), text: 'Staff & Alerts'),
                Tab(icon: Icon(Icons.airport_shuttle), text: 'Ambulance'),
              ],
            ),
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
          body: Consumer<AdminProvider>(
            builder: (context, provider, child) {
              return TabBarView(
                children: [
                  _buildEpidemiologyTab(context, provider),
                  _buildStaffAlertsTab(context, provider),
                  _buildAmbulanceTab(context, provider),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 1: EPIDEMIOLOGY & PUBLIC HEALTH ANALYTICS
  // ----------------------------------------------------
  Widget _buildEpidemiologyTab(BuildContext context, AdminProvider provider) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        StreamBuilder<bool>(
          stream: provider.diseaseAlertStream,
          builder: (context, snapshot) {
            final isAlert = snapshot.data ?? false;
            if (isAlert) {
              return const DiseaseAlertBanner();
            }
            return const SizedBox.shrink();
          },
        ),
        _buildAnalyticsCard(context, provider),
        _buildEpidemiologyChartCard(context, provider),
      ],
    );
  }

  Widget _buildAnalyticsCard(BuildContext context, AdminProvider provider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('District Clinic Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StreamBuilder<int>(
                  stream: provider.activeDoctorsCountStream,
                  builder: (context, snapshot) => _buildStatItem(context, 'Active Doctors', snapshot.data?.toString() ?? '...', Icons.medical_services, Colors.teal),
                ),
                StreamBuilder<List<Ambulance>>(
                  stream: provider.ambulancesStream,
                  builder: (context, snapshot) {
                    final ambulances = snapshot.data ?? [];
                    final total = ambulances.length;
                    final available = ambulances.where((a) => a.status == AmbulanceStatus.available).length;
                    return _buildStatItem(context, 'Ambulance Free', '$available/$total', Icons.airport_shuttle, Colors.redAccent);
                  },
                ),
                StreamBuilder<int>(
                  stream: provider.patientsTodayCountStream,
                  builder: (context, snapshot) => _buildStatItem(context, 'Patients Today', snapshot.data?.toString() ?? '...', Icons.people, Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEpidemiologyChartCard(BuildContext context, AdminProvider provider) {
    return StreamBuilder<Map<String, int>>(
      stream: provider.diagnosisStatsStream,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final total = stats.values.fold(0, (sum, val) => sum + val);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Outbreak Diagnosis Distribution (48h)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (stats.isEmpty || total == 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'No medical records logged recently.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...stats.entries.map((entry) {
                    final label = entry.key;
                    final count = entry.value;
                    final ratio = total == 0 ? 0.0 : count / total;

                    Color progressColor = Colors.blueAccent;
                    if (label == 'Malaria' || label == 'Dengue') {
                      progressColor = Colors.redAccent;
                    } else if (label == 'Flu/Fever') {
                      progressColor = Colors.orangeAccent;
                    } else if (label == 'Typhoid') {
                      progressColor = Colors.amber;
                    } else {
                      progressColor = Colors.teal;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('$count case${count == 1 ? "" : "s"} (${(ratio * 100).toStringAsFixed(0)}%)'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: ratio,
                            backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                            color: progressColor,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // TAB 2: STAFF SHIFTS & HEALTH ADVISORY BROADCASTS
  // ----------------------------------------------------
  Widget _buildStaffAlertsTab(BuildContext context, AdminProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Doctor Presence Control',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.campaign, color: Colors.blue),
              tooltip: 'Broadcast Health Alert',
              onPressed: () => _showBroadcastDialog(context, provider),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildDoctorsList(provider),
        const SizedBox(height: 24),
        const Text(
          'Other Staff Rosters Today',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildStaffList(provider),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showBroadcastDialog(context, provider),
          icon: const Icon(Icons.add_alert),
          label: const Text('Post District Health Advisory'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
        )
      ],
    );
  }

  Widget _buildDoctorsList(AdminProvider provider) {
    return StreamBuilder<List<UserModel>>(
      stream: provider.doctorsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final doctors = snapshot.data ?? [];
        if (doctors.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text('No registered doctors found.', style: TextStyle(color: Colors.grey)),
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doc = doctors[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: SwitchListTile(
                secondary: CircleAvatar(
                  backgroundColor: doc.isPresent ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  child: Icon(Icons.medical_services, color: doc.isPresent ? Colors.blue : Colors.grey),
                ),
                title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(doc.specialty ?? 'General'),
                value: doc.isPresent,
                onChanged: (bool value) {
                  provider.toggleDoctorPresence(doc.uid, value);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStaffList(AdminProvider provider) {
    return StreamBuilder<List<Attendance>>(
      stream: provider.todayAttendanceStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final staff = snapshot.data ?? [];
        if (staff.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text('No staff checked in today.', style: TextStyle(color: Colors.grey)),
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: staff.length,
          itemBuilder: (context, index) {
            final s = staff[index];
            final isActive = s.checkOut == null;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  child: Icon(Icons.person, color: isActive ? Colors.green : Colors.grey),
                ),
                title: Text(s.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Role: ${s.role.toUpperCase()}'),
                trailing: Chip(
                  label: Text(
                    isActive ? 'Active Shift' : 'Checked Out', 
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? Colors.green[800] : null,
                    ),
                  ),
                  backgroundColor: isActive ? Colors.greenAccent.withOpacity(0.2) : null,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBroadcastDialog(BuildContext context, AdminProvider provider) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String severity = 'info';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Post Health Advisory'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Alert Headline'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Instruction Details'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: severity,
                decoration: const InputDecoration(labelText: 'Severity Level'),
                items: const [
                  DropdownMenuItem(value: 'info', child: Text('Information (Blue)')),
                  DropdownMenuItem(value: 'warning', child: Text('Warning Alert (Orange)')),
                  DropdownMenuItem(value: 'critical', child: Text('Critical Threat (Red)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => severity = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields required.')));
                        return;
                      }
                      setState(() => isSaving = true);
                      try {
                        await provider.broadcastAdvisory(titleCtrl.text.trim(), descCtrl.text.trim(), severity);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
              child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Post Alert'),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 3: AMBULANCE FLEET CONTROL
  // ----------------------------------------------------
  Widget _buildAmbulanceTab(BuildContext context, AdminProvider provider) {
    return Scaffold(
      body: StreamBuilder<List<Ambulance>>(
        stream: provider.ambulancesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final ambulances = snapshot.data ?? [];
          if (ambulances.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_filled, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No registered ambulances in fleet.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ambulances.length,
            itemBuilder: (context, index) {
              final a = ambulances[index];
              Color statusColor = Colors.green;
              if (a.status == AmbulanceStatus.dispatched) {
                statusColor = Colors.orange;
              } else if (a.status == AmbulanceStatus.onBreak) {
                statusColor = Colors.red;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(Icons.airport_shuttle, size: 36, color: statusColor),
                  title: Text(a.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Status: ${a.status.name.toUpperCase()}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (a.status == AmbulanceStatus.dispatched)
                        IconButton(
                          icon: const Icon(Icons.settings_backup_restore, color: Colors.blue),
                          tooltip: 'Reset to Available',
                          onPressed: () => provider.resetAmbulance(a.id),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Retire Vehicle',
                        onPressed: () => provider.removeAmbulance(a.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAmbulanceDialog(context, provider),
        tooltip: 'Add Ambulance',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAmbulanceDialog(BuildContext context, AdminProvider provider) {
    final vehicleCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Fleet Ambulance'),
          content: TextField(
            controller: vehicleCtrl,
            decoration: const InputDecoration(
              labelText: 'Vehicle Number (e.g. MH-12-AB-1234)',
              prefixIcon: Icon(Icons.directions_car),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (vehicleCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle number required.')));
                        return;
                      }
                      setState(() => isSaving = true);
                      try {
                        await provider.createAmbulance(vehicleCtrl.text.trim().toUpperCase());
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
              child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add Vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}
