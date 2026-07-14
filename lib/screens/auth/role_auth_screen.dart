import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/firestore_service.dart';
import '../patient/patient_dashboard.dart';
import '../doctor/doctor_dashboard.dart';
import '../pharmacist/pharmacist_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../lab/lab_dashboard.dart';

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

  // New Patient Fields
  final _regAgeCtrl = TextEditingController();
  final _regAddressCtrl = TextEditingController();
  final _regEmergencyContactCtrl = TextEditingController();
  String? _selectedGender;
  String? _selectedBloodGroup;
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  String? _selectedPhcId;
  List<Map<String, dynamic>> _phcList = [];
  bool _isLoadingPhcs = true;

  final List<String> _specialties = [
    'General Physician',
    'Cardiologist',
    'Pediatrician',
    'Dermatologist',
    'General Surgeon',
    'Gynecologist',
    'Urologist',
    'Orthopedic'
  ];
  String? _selectedSpecialty;

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regExtraCtrl.dispose();
    _regAgeCtrl.dispose();
    _regAddressCtrl.dispose();
    _regEmergencyContactCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPhcs();
  }

  Future<void> _fetchPhcs() async {
    try {
      final list = await FirestoreService().getAllPhcs();
      if (mounted) {
        setState(() {
          _phcList = list;
          if (_phcList.isNotEmpty) {
            _selectedPhcId = _phcList.first['id'];
          }
          _isLoadingPhcs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPhcs = false);
      }
    }
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
      case UserRole.lab_technician:
        destination = const LabDashboard();
        break;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Future<void> _handleLogin() async {
    final provider = context.read<AuthProvider>();
    try {
      final success = await provider.signIn(_loginEmailCtrl.text.trim(), _loginPassCtrl.text.trim());
      if (success && mounted) {
        if (provider.userModel?.role != widget.role) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Access denied: You are registered as a ${provider.userModel?.role.name.toUpperCase()}. Please use the correct portal.'),
          ));
          provider.signOut();
          return;
        }
        _navigateToDashboard();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login failed. Ensure you have registered your account.')));
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Login failed.';
        final errString = e.toString().toLowerCase();
        if (errString.contains('invalid-credential') || errString.contains('wrong-password') || errString.contains('user-not-found')) {
          errorMsg = 'Invalid email or password. Please try again.';
        } else {
          errorMsg = 'Login failed: ${e.toString().replaceAll(RegExp(r'\\[.*?\\] '), '')}';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
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
        phcId: _selectedPhcId,
        doctorRegId: widget.role == UserRole.doctor ? _regExtraCtrl.text.trim() : null,
        hospitalRegNo: widget.role == UserRole.admin ? _regExtraCtrl.text.trim() : null,
        pharmacistRegNo: widget.role == UserRole.pharmacist ? _regExtraCtrl.text.trim() : null,
        specialty: widget.role == UserRole.doctor ? _selectedSpecialty ?? 'General Physician' : null,
        age: widget.role == UserRole.patient ? int.tryParse(_regAgeCtrl.text) : null,
        gender: widget.role == UserRole.patient ? _selectedGender : null,
        bloodGroup: widget.role == UserRole.patient ? _selectedBloodGroup : null,
        address: widget.role == UserRole.patient ? _regAddressCtrl.text.trim() : null,
        emergencyContact: widget.role == UserRole.patient ? _regEmergencyContactCtrl.text.trim() : null,
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
    try {
      final success = await provider.signInWithGoogle();
      if (success && mounted) {
        if (provider.userModel?.role != widget.role) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Access denied: You are registered as a ${provider.userModel?.role.name.toUpperCase()}. Please use the correct portal.'),
          ));
          provider.signOut();
          return;
        }
        _navigateToDashboard();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Sign-In failed or was canceled.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-In error: ${e.toString().replaceAll(RegExp(r'\\[.*?\\] '), '')}')));
      }
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
      case UserRole.lab_technician:
        return 'Laboratory License Number';
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
                const SizedBox(height: 16),
                
                if (widget.role == UserRole.patient) ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Age',
                          controller: _regAgeCtrl,
                          prefixIcon: Icons.cake,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark 
                                ? Theme.of(context).colorScheme.surface 
                                : Colors.grey[50],
                          ),
                          items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (val) => setState(() => _selectedGender = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedBloodGroup,
                    decoration: InputDecoration(
                      labelText: 'Blood Group',
                      prefixIcon: const Icon(Icons.bloodtype),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark 
                          ? Theme.of(context).colorScheme.surface 
                          : Colors.grey[50],
                    ),
                    items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
                    onChanged: (val) => setState(() => _selectedBloodGroup = val),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'Address', controller: _regAddressCtrl, prefixIcon: Icons.home),
                  const SizedBox(height: 16),
                  CustomTextField(label: 'Emergency Contact', controller: _regEmergencyContactCtrl, prefixIcon: Icons.contact_phone, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                ],

                _isLoadingPhcs
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedPhcId,
                        decoration: InputDecoration(
                          labelText: 'Assigned PHC / Clinic',
                          prefixIcon: const Icon(Icons.local_hospital),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark 
                              ? Theme.of(context).colorScheme.surface 
                              : Colors.grey[50],
                        ),
                        isExpanded: true,
                        items: _phcList.map((phc) {
                          return DropdownMenuItem<String>(
                            value: phc['id'],
                            child: Text(phc['name']),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedPhcId = val);
                        },
                      ),
                if (widget.role != UserRole.patient) ...[
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: _getExtraFieldLabel(),
                    controller: _regExtraCtrl,
                    prefixIcon: Icons.badge,
                  ),
                  if (widget.role == UserRole.doctor) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSpecialty,
                      decoration: InputDecoration(
                        labelText: 'Medical Specialty',
                        prefixIcon: const Icon(Icons.medical_services),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark 
                            ? Theme.of(context).colorScheme.surface 
                            : Colors.grey[50],
                      ),
                      isExpanded: true,
                      items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _selectedSpecialty = val),
                    ),
                  ],
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
