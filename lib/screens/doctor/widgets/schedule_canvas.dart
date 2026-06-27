import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/appointment.dart';

class ScheduleCanvas extends StatelessWidget {
  final List<Appointment> appointments;
  final Function(Appointment) onAppointmentTap;
  final Function(Appointment, AppointmentStatus) onStatusChange;

  const ScheduleCanvas({
    Key? key,
    required this.appointments,
    required this.onAppointmentTap,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return const Center(
        child: Text('No appointments scheduled for today.'),
      );
    }

    // Sort chronologically
    final sortedAppointments = List<Appointment>.from(appointments)
      ..sort((a, b) => a.time.compareTo(b.time));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedAppointments.length,
      itemBuilder: (context, index) {
        final appointment = sortedAppointments[index];
        final timeString = DateFormat('hh:mm a').format(appointment.time);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onAppointmentTap(appointment),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Column
                  SizedBox(
                    width: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(timeString, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        _buildStatusBadge(appointment.status),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Divider Line
                  Container(
                    width: 2,
                    height: 60,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(width: 16),
                  
                  // Details Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${appointment.patientName} (${appointment.patientAge}y)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text('Reason: ${appointment.reason}', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  
                  // Quick Actions
                  PopupMenuButton<AppointmentStatus>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (status) => onStatusChange(appointment, status),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: AppointmentStatus.checkedIn, child: Text('Mark Checked In')),
                      PopupMenuItem(value: AppointmentStatus.inProgress, child: Text('Mark In Progress')),
                      PopupMenuItem(value: AppointmentStatus.completed, child: Text('Mark Completed')),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(AppointmentStatus status) {
    Color color;
    String label;
    switch (status) {
      case AppointmentStatus.scheduled:
        color = Colors.grey;
        label = 'Scheduled';
        break;
      case AppointmentStatus.checkedIn:
        color = Colors.blue;
        label = 'Checked In';
        break;
      case AppointmentStatus.inProgress:
        color = Colors.orange;
        label = 'In Progress';
        break;
      case AppointmentStatus.completed:
        color = Colors.green;
        label = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
