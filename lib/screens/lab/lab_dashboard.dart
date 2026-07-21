import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/lab_report.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../auth/login_screen.dart';
import '../../widgets/language_selector.dart';
import '../../l10n/app_localizations.dart';

class LabDashboard extends StatefulWidget {
  const LabDashboard({Key? key}) : super(key: key);

  @override
  _LabDashboardState createState() => _LabDashboardState();
}

class _LabDashboardState extends State<LabDashboard> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final phcId = user?.assignedPhcId ?? 'phc_1'; // fallback

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratory Dashboard'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: LanguageSelector(),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final user = authProvider.userModel;
                return UserAccountsDrawerHeader(
                  accountName: Text(user?.name ?? 'Lab Technician'),
                  accountEmail: Text(user?.contact ?? 'Lab Portal'),
                  currentAccountPicture: InkWell(
                    onTap: () => authProvider.uploadProfilePicture(),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: user?.profilePicUrl != null ? NetworkImage(user!.profilePicUrl!) : null,
                      child: user?.profilePicUrl == null ? const Icon(Icons.science, size: 40, color: Colors.blue) : null,
                    ),
                  ),
                );
              }
            ),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final isDark = auth.themeMode == ThemeMode.dark;
                return SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: isDark,
                  onChanged: (val) => auth.toggleTheme(val),
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                );
              },
            ),
                          ListTile(
                leading: const Icon(Icons.language),
                title: Text(AppLocalizations.of(context)?.language ?? 'Language'),
                trailing: const LanguageSelector(),
              ),
              const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Provider.of<AuthProvider>(context, listen: false).signOut();
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: StreamBuilder<List<LabReport>>(
        stream: _firestoreService.getPendingLabReportsForPhc(phcId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return const Center(child: Text('No pending lab tests.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            report.testName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Pending', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Patient: ${report.patientName}'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showUploadResultDialog(report),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Result'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showUploadResultDialog(LabReport report) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UploadResultDialog(report: report, firestoreService: _firestoreService),
    );
  }
}

class _UploadResultDialog extends StatefulWidget {
  final LabReport report;
  final FirestoreService firestoreService;

  const _UploadResultDialog({Key? key, required this.report, required this.firestoreService}) : super(key: key);

  @override
  _UploadResultDialogState createState() => _UploadResultDialogState();
}

class _UploadResultDialogState extends State<_UploadResultDialog> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isSaving = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _submitResult() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image first.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final imageUrl = await widget.firestoreService.uploadLabReportFile(_selectedImage!, widget.report.id);
      
      await widget.firestoreService.uploadLabResult(
        widget.report.id, 
        imageUrl: imageUrl,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Result Uploaded Successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Upload Result: ${widget.report.testName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 16),
            if (_selectedImage != null)
              Container(
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: const Center(child: Text('No Image Selected', style: TextStyle(color: Colors.grey))),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submitResult,
                  child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Upload'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
