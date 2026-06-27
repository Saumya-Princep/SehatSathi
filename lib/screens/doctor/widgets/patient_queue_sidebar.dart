import 'package:flutter/material.dart';
import '../../../models/appointment.dart';

class PatientQueueSidebar extends StatefulWidget {
  final List<Appointment> queue;
  final Function(Appointment) onPatientTap;

  const PatientQueueSidebar({
    Key? key,
    required this.queue,
    required this.onPatientTap,
  }) : super(key: key);

  @override
  _PatientQueueSidebarState createState() => _PatientQueueSidebarState();
}

class _PatientQueueSidebarState extends State<PatientQueueSidebar> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredQueue = widget.queue.where((apt) {
      return apt.patientName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search waiting patients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            width: double.infinity,
            child: Text(
              'WAITING LOBBY (${filteredQueue.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: filteredQueue.isEmpty
                ? const Center(child: Text('No patients in queue.', style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    itemCount: filteredQueue.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final apt = filteredQueue[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          child: Text(apt.patientName.substring(0, 1).toUpperCase()),
                        ),
                        title: Text(apt.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Reason: ${apt.reason}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => widget.onPatientTap(apt),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
