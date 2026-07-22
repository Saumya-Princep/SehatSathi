import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _emergencyContactCtrl;
  late TextEditingController _specialtyCtrl;
  
  String? _selectedGender;
  String? _selectedBloodGroup;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _contactCtrl = TextEditingController(text: widget.user.contact);
    _ageCtrl = TextEditingController(text: widget.user.age?.toString() ?? '');
    _addressCtrl = TextEditingController(text: widget.user.address);
    _emergencyContactCtrl = TextEditingController(text: widget.user.emergencyContact);
    _specialtyCtrl = TextEditingController(text: widget.user.specialty);
    _selectedGender = widget.user.gender;
    _selectedBloodGroup = widget.user.bloodGroup;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _ageCtrl.dispose();
    _addressCtrl.dispose();
    _emergencyContactCtrl.dispose();
    _specialtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isPatient = widget.user.role == UserRole.patient;
    final isDoctor = widget.user.role == UserRole.doctor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        bottom: true,
        child: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactCtrl,
                      decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    if (isDoctor) ...[
                      TextFormField(
                        controller: _specialtyCtrl,
                        decoration: const InputDecoration(labelText: 'Specialty', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (isPatient) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageCtrl,
                              decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                              value: _selectedGender,
                              items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (val) => setState(() => _selectedGender = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Blood Group', border: OutlineInputBorder()),
                        value: _selectedBloodGroup,
                        items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
                        onChanged: (val) => setState(() => _selectedBloodGroup = val),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emergencyContactCtrl,
                        decoration: const InputDecoration(labelText: 'Emergency Contact', border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final updatedUser = UserModel(
                              uid: widget.user.uid,
                              name: _nameCtrl.text.trim(),
                              role: widget.user.role,
                              assignedPhcId: widget.user.assignedPhcId,
                              contact: _contactCtrl.text.trim(),
                              doctorRegistrationId: widget.user.doctorRegistrationId,
                              hospitalRegistrationNumber: widget.user.hospitalRegistrationNumber,
                              pharmacistRegistrationNumber: widget.user.pharmacistRegistrationNumber,
                              specialty: isDoctor ? _specialtyCtrl.text.trim() : widget.user.specialty,
                              isPresent: widget.user.isPresent,
                              createdAt: widget.user.createdAt,
                              age: _ageCtrl.text.isNotEmpty ? int.tryParse(_ageCtrl.text) : widget.user.age,
                              gender: _selectedGender,
                              bloodGroup: _selectedBloodGroup,
                              address: _addressCtrl.text.trim(),
                              emergencyContact: _emergencyContactCtrl.text.trim(),
                              profilePicUrl: widget.user.profilePicUrl,
                              parentId: widget.user.parentId,
                            );
                            final success = await authProvider.updateProfile(updatedUser);
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
                              Navigator.pop(context);
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
                            }
                          }
                        },
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
