import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pharmacist_provider.dart';
import '../../models/inventory_item.dart';
import '../auth/login_screen.dart';

class PharmacistDashboard extends StatelessWidget {
  const PharmacistDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PharmacistProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pharmacy Inventory'),
          actions: [
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
            return StreamBuilder<List<InventoryItem>>(
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
                                color: item.isLowStock ? Theme.of(context).colorScheme.error : Colors.black,
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
            );
          },
        ),
      ),
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
