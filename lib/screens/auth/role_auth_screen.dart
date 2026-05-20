import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../patient/patient_dashboard.dart';
import '../doctor/doctor_dashboard.dart';
import '../pharmacist/pharmacist_dashboard.dart';
import '../admin/admin_dashboard.dart';

class RoleAuthScreen extends StatefulWidget {
  final UserRole role;

  const RoleAuthScreen({Key? key, required this.role}) : super(key: key);

  @override
  _RoleAuthScreenState createState() => _RoleAuthScreenState();
}

class _RoleAuthScreenState extends State<RoleAuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regExtraCtrl = TextEditingController(); // Doctor ID, Hospital Reg, etc.

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _navigateToDashboard() {
    Widget destination;
    switch (widget.role) {
      case UserRole.patient:
        destination = const PatientDashboard();
        break;
      case UserRole.doctor:
        destination = const DoctorDashboard();
        break;
      case UserRole.pharmacist:
        destination = const PharmacistDashboard();
        break;
      case UserRole.admin:
        destination = const AdminDashboard();
        break;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Future<void> _handleLogin() async {
    final provider = context.read<AuthProvider>();
    final success = await provider.signIn(_loginEmailCtrl.text.trim(), _loginPassCtrl.text.trim());
    if (success && mounted) {
      _navigateToDashboard();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login failed. Check credentials.')));
    }
  }

  Future<void> _handleRegister() async {
    final provider = context.read<AuthProvider>();
    if (_regEmailCtrl.text.isEmpty || _regPassCtrl.text.isEmpty || _regNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
      return;
    }
    if (widget.role != UserRole.patient && _regExtraCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration ID is required.')));
      return;
    }

    try {
      await provider.register(
        email: _regEmailCtrl.text.trim(),
        password: _regPassCtrl.text.trim(),
        name: _regNameCtrl.text.trim(),
        role: widget.role,
        phcId: 'phc_1', // Default PHC for now
        doctorRegId: widget.role == UserRole.doctor ? _regExtraCtrl.text.trim() : null,
        hospitalRegNo: widget.role == UserRole.admin ? _regExtraCtrl.text.trim() : null,
        pharmacistRegNo: widget.role == UserRole.pharmacist ? _regExtraCtrl.text.trim() : null,
      );

      if (mounted) {
        _navigateToDashboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '').replaceAll('[firebase_auth/email-already-in-use]', '').replaceAll('[firebase_auth/weak-password]', '').trim()}')));
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final provider = context.read<AuthProvider>();
    final success = await provider.signInWithGoogle();
    if (success && mounted) {
      // Note: If a non-patient signs in with Google and it's a new account, they will be registered as a Patient by default.
      _navigateToDashboard();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Sign-In failed or was canceled.')));
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_loginEmailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email address first.')));
      return;
    }
    final provider = context.read<AuthProvider>();
    final success = await provider.sendPasswordResetEmail(_loginEmailCtrl.text.trim());
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent! Check your inbox.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send reset email. Verify your email address.')));
      }
    }
  }

  String _getExtraFieldLabel() {
    switch (widget.role) {
      case UserRole.doctor:
        return 'Doctor ID';
      case UserRole.admin:
        return 'Hospital Registration Number';
      case UserRole.pharmacist:
        return 'Medical Registration Number';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role.name.toUpperCase()} PORTAL'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'LOGIN'),
            Tab(text: 'REGISTER'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // LOGIN TAB
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomTextField(label: 'Email', controller: _loginEmailCtrl, prefixIcon: Icons.email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                CustomTextField(label: 'Password', controller: _loginPassCtrl, prefixIcon: Icons.lock, obscureText: true),
                const SizedBox(height: 24),
                CustomButton(text: 'Login', onPressed: _handleLogin, isLoading: provider.isLoading),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _handleForgotPassword,
                  child: const Text('Forgot Password?'),
                ),
              ],
            ),
          ),
          // REGISTER TAB
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.role == UserRole.patient) ...[
                  ElevatedButton.icon(
                    onPressed: _handleGoogleSignIn,
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text("OR")),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                CustomTextField(label: 'Full Name', controller: _regNameCtrl, prefixIcon: Icons.person),
                const SizedBox(height: 16),
                CustomTextField(label: 'Email', controller: _regEmailCtrl, prefixIcon: Icons.email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                CustomTextField(label: 'Password', controller: _regPassCtrl, prefixIcon: Icons.lock, obscureText: true),
                if (widget.role != UserRole.patient) ...[
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: _getExtraFieldLabel(),
                    controller: _regExtraCtrl,
                    prefixIcon: Icons.badge,
                  ),
                ],
                const SizedBox(height: 24),
                CustomButton(text: 'Register', onPressed: _handleRegister, isLoading: provider.isLoading),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
