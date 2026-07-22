import 'package:flutter/material.dart';
import '../../utils/image_utils.dart';

import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final currentUser = authProvider.activePatient?.uid == user.uid 
            ? authProvider.activePatient! 
            : user;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(user: currentUser)),
                  );
                },
              )
            ],
          ),
          body: SafeArea(
            bottom: true,
            child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: currentUser.profilePicUrl != null ? getProfileImageProvider(currentUser.profilePicUrl!) : null,
                      child: currentUser.profilePicUrl == null ? const Icon(Icons.person, size: 60, color: Colors.blue) : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          onPressed: () => authProvider.uploadProfilePicture(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoTile('Name', currentUser.name),
              const Divider(),
              _buildInfoTile('Role', currentUser.role.name.toUpperCase()),
              const Divider(),
              _buildInfoTile('Contact', currentUser.contact ?? 'Not specified'),
              const Divider(),
              
              if (currentUser.role == UserRole.patient) ...[
                _buildInfoTile('Age', currentUser.age?.toString() ?? 'Not specified'),
                const Divider(),
                _buildInfoTile('Gender', currentUser.gender ?? 'Not specified'),
                const Divider(),
                _buildInfoTile('Blood Group', currentUser.bloodGroup ?? 'Not specified'),
                const Divider(),
                _buildInfoTile('Emergency Contact', currentUser.emergencyContact ?? 'Not specified'),
                const Divider(),
                _buildInfoTile('Address', currentUser.address ?? 'Not specified'),
              ] else if (currentUser.role == UserRole.doctor) ...[
                _buildInfoTile('Specialty', currentUser.specialty ?? 'Not specified'),
                const Divider(),
                _buildInfoTile('Registration ID', currentUser.doctorRegistrationId ?? 'Not specified'),
              ] else if (currentUser.role == UserRole.pharmacist) ...[
                _buildInfoTile('Registration Number', currentUser.pharmacistRegistrationNumber ?? 'Not specified'),
              ] else if (currentUser.role == UserRole.admin) ...[
                _buildInfoTile('Assigned PHC ID', currentUser.assignedPhcId ?? 'Not specified'),
              ],
            ],
          ),
          ),
        );
      }
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
