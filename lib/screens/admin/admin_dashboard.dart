import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/ambulance.dart';
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('District Dashboard'),
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
        body: Consumer<AdminProvider>(
          builder: (context, provider, child) {
            return ListView(
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Active Staff Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _buildStaffList(provider),
              ],
            );
          },
        ),
      ),
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
            const Text('High-Level Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StreamBuilder<int>(
                  stream: provider.activeDoctorsCountStream,
                  builder: (context, snapshot) => _buildStatItem(context, 'Active Doctors', snapshot.data?.toString() ?? '...', Icons.medical_services),
                ),
                StreamBuilder<List<Ambulance>>(
                  stream: provider.ambulancesStream,
                  builder: (context, snapshot) {
                    final ambulances = snapshot.data ?? [];
                    final total = ambulances.length;
                    final available = ambulances.where((a) => a.status == AmbulanceStatus.available).length;
                    return _buildStatItem(context, 'Ambulances', '$available/$total', Icons.airport_shuttle);
                  },
                ),
                StreamBuilder<int>(
                  stream: provider.patientsTodayCountStream,
                  builder: (context, snapshot) => _buildStatItem(context, 'Patients Today', snapshot.data?.toString() ?? '...', Icons.people),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStaffList(AdminProvider provider) {
    return StreamBuilder(
      stream: provider.todayAttendanceStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final staff = snapshot.data ?? [];
        if (staff.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No staff checked in today.'),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: staff.length,
          itemBuilder: (context, index) {
            final s = staff[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(s.userName),
              subtitle: Text(s.role.toUpperCase()),
              trailing: s.checkOut == null 
                  ? const Chip(label: Text('Active'), backgroundColor: Colors.greenAccent)
                  : const Chip(label: Text('Checked Out')),
            );
          },
        );
      },
    );
  }
}
