import 'package:flutter/material.dart';

class AnalyticsCards extends StatelessWidget {
  final int totalAppointments;
  final int completedAppointments;
  final int pendingReview;
  final int emergencyFlags;
  final int avgWaitTime;

  const AnalyticsCards({
    Key? key,
    required this.totalAppointments,
    required this.completedAppointments,
    required this.pendingReview,
    required this.emergencyFlags,
    required this.avgWaitTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 400 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildCard(
              context, 
              title: 'Total Appointments', 
              value: '$totalAppointments', 
              subValue: '$completedAppointments Completed',
              icon: Icons.calendar_today,
              color: Colors.blue,
            ),
            _buildCard(
              context, 
              title: 'Pending Review', 
              value: '$pendingReview', 
              subValue: 'Labs/Signatures',
              icon: Icons.pending_actions,
              color: Colors.orange,
            ),
            _buildCard(
              context, 
              title: 'Emergency Flags', 
              value: '$emergencyFlags', 
              subValue: 'Immediate Attention',
              icon: Icons.warning,
              color: Colors.red,
            ),
            _buildCard(
              context, 
              title: 'Average Wait Time', 
              value: '${avgWaitTime}m', 
              subValue: 'Across patients',
              icon: Icons.timer,
              color: Colors.teal,
            ),
          ],
        );
      }
    );
  }

  Widget _buildCard(BuildContext context, {required String title, required String value, required String subValue, required IconData icon, required Color color}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(subValue, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
