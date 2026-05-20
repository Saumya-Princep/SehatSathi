import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'role_auth_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  void _selectRole(BuildContext context, UserRole role) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoleAuthScreen(role: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.health_and_safety,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'SehatSathi',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text('Please select your portal to continue'),
                const SizedBox(height: 48),
                _buildRoleCard(
                  context,
                  title: 'Patient Portal',
                  icon: Icons.personal_injury,
                  role: UserRole.patient,
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  context,
                  title: 'Doctor Portal',
                  icon: Icons.medical_services,
                  role: UserRole.doctor,
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  context,
                  title: 'Admin Portal',
                  icon: Icons.admin_panel_settings,
                  role: UserRole.admin,
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  context,
                  title: 'Pharmacist Portal',
                  icon: Icons.local_pharmacy,
                  role: UserRole.pharmacist,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {required String title, required IconData icon, required UserRole role}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _selectRole(context, role),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 24),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
