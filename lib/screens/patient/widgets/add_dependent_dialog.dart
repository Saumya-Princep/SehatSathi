import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';

class AddDependentDialog extends StatefulWidget {
  final String parentId;

  const AddDependentDialog({Key? key, required this.parentId}) : super(key: key);

  @override
  State<AddDependentDialog> createState() => _AddDependentDialogState();
}

class _AddDependentDialogState extends State<AddDependentDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  int? _age;
  String _gender = 'Male';
  String _bloodGroup = 'A+';
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      
      try {
        final dependent = UserModel(
          uid: const Uuid().v4(),
          name: _name,
          role: UserRole.patient,
          age: _age,
          gender: _gender,
          bloodGroup: _bloodGroup,
          parentId: widget.parentId,
        );
        
        await FirestoreService().addDependent(dependent);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding dependent: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Family Member'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _name = val!,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _age = int.tryParse(val!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _gender = val!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _bloodGroup,
                decoration: const InputDecoration(labelText: 'Blood Group'),
                items: _bloodGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _bloodGroup = val!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
            : const Text('Add'),
        ),
      ],
    );
  }
}
