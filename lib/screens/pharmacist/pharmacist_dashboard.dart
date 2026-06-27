import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pharmacist_provider.dart';
import '../../models/inventory_item.dart';
import '../../models/medical_record.dart';
import '../auth/login_screen.dart';
import 'package:uuid/uuid.dart';

class PharmacistDashboard extends StatelessWidget {
  const PharmacistDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PharmacistProvider(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Pharmacy Portal'),
            bottom: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
                Tab(icon: Icon(Icons.receipt_long), text: 'Prescriptions'),
              ],
            ),
            actions: [
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final isDark = auth.themeMode == ThemeMode.dark;
                  return IconButton(
                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                    onPressed: () => auth.toggleTheme(!isDark),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).signOut();
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              ),
            ],
          ),
          body: Consumer<PharmacistProvider>(
            builder: (context, provider, child) {
              return TabBarView(
                children: [
                  _buildInventoryTab(context, provider),
                  _buildPrescriptionsTab(context, provider),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryTab(BuildContext context, PharmacistProvider provider) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => _AddMedicineDialog(provider: provider),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
      body: StreamBuilder<List<InventoryItem>>(
        stream: provider.inventoryStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No inventory items found.'));
          }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              color: item.isLowStock ? Theme.of(context).colorScheme.errorContainer : null,
              child: ListTile(
                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Batch: ${item.batchNumber} | Threshold: ${item.thresholdLimit}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${item.currentStock}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: item.isLowStock ? Theme.of(context).colorScheme.error : null,
                      ),
                    ),
                    const Text('Stock', style: TextStyle(fontSize: 10)),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => _UpdateStockDialog(
                      item: item,
                      provider: provider,
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    ),
  );
}

  Widget _buildPrescriptionsTab(BuildContext context, PharmacistProvider provider) {
    return StreamBuilder<List<MedicalRecord>>(
      stream: provider.pendingPrescriptionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No pending prescriptions found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final pendingMeds = record.prescriptions.where((p) => !p.isDispensed).toList();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: const Icon(Icons.assignment),
                title: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(record.patientId).get(),
                  builder: (context, userSnap) {
                    final name = (userSnap.data?.data() as Map<String, dynamic>?)?['name'] ?? 'Patient';
                    return Text(
                      'Patient: $name',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  },
                ),
                subtitle: Text('Diagnosis: ${record.diagnosis}\nDoc: ${record.doctorName}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prescribed Medications:',
                          style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                        const SizedBox(height: 8),
                        ...pendingMeds.map((med) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.medication, size: 18, color: Colors.teal),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${med.name} — ${med.dosage}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                'Qty: ${med.quantity}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        )).toList(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final dispenseItems = pendingMeds.map((m) => {
                                    'id': m.id,
                                    'quantity': m.quantity,
                                  }).toList();
                                  
                                  await provider.dispenseMedicines(record.id, dispenseItems);
                                  
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Prescription dispensed and stock updated successfully!')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Dispense & Fulfill'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _UpdateStockDialog extends StatefulWidget {
  final InventoryItem item;
  final PharmacistProvider provider;

  const _UpdateStockDialog({Key? key, required this.item, required this.provider}) : super(key: key);

  @override
  _UpdateStockDialogState createState() => _UpdateStockDialogState();
}

class _UpdateStockDialogState extends State<_UpdateStockDialog> {
  late TextEditingController _stockController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(text: widget.item.currentStock.toString());
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update ${widget.item.name}'),
      content: TextField(
        controller: _stockController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'New Stock Quantity'),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  final newStock = int.tryParse(_stockController.text);
                  if (newStock != null && newStock >= 0) {
                    setState(() => _isLoading = true);
                    try {
                      await widget.provider.updateStock(widget.item.id, newStock);
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid non-negative number')));
                  }
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}

class _AddMedicineDialog extends StatefulWidget {
  final PharmacistProvider provider;
  const _AddMedicineDialog({Key? key, required this.provider}) : super(key: key);
  @override
  _AddMedicineDialogState createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<_AddMedicineDialog> {
  final _nameController = TextEditingController();
  final _batchController = TextEditingController();
  final _stockController = TextEditingController();
  final _thresholdController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Medicine'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Medicine Name')),
            TextField(controller: _batchController, decoration: const InputDecoration(labelText: 'Batch Number')),
            TextField(controller: _stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial Stock Quantity')),
            TextField(controller: _thresholdController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low Stock Threshold')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            final name = _nameController.text.trim();
            final batch = _batchController.text.trim();
            final stock = int.tryParse(_stockController.text) ?? 0;
            final threshold = int.tryParse(_thresholdController.text) ?? 0;
            
            if (name.isNotEmpty && batch.isNotEmpty && stock >= 0) {
              setState(() => _isLoading = true);
              try {
                final item = InventoryItem(
                  id: const Uuid().v4(),
                  name: name,
                  batchNumber: batch,
                  currentStock: stock,
                  thresholdLimit: threshold,
                  lastUpdated: DateTime.now(),
                );
                await widget.provider.addInventoryItem(item);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields correctly')));
            }
          },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add Item'),
        ),
      ],
    );
  }
}
