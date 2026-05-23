export 'supplier_list.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/main_drawer.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  late Future<List<dynamic>> _suppliers;

  @override
  void initState() {
    super.initState();
    _suppliers = ApiService.getSuppliers();
  }

  void _refresh() {
    setState(() {
      _suppliers = ApiService.getSuppliers();
    });
  }

  Future<void> _showSupplierDialog({Map<String, dynamic>? supplier}) async {
    final nameController = TextEditingController(
      text: supplier?['name']?.toString() ?? '',
    );
    final contactController = TextEditingController(
      text: supplier?['contact']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: supplier?['email']?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(supplier == null ? 'Add Supplier' : 'Edit Supplier'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(labelText: 'Contact'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': nameController.text,
                  'contact': contactController.text,
                  'email': emailController.text,
                };

                try {
                  if (supplier == null) {
                    await ApiService.addSupplier(data);
                  } else {
                    await ApiService.updateSupplier(
                      supplier['id'] as int,
                      data,
                    );
                  }

                  if (!mounted) return;
                  Navigator.of(context).pop();
                  _refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        supplier == null
                            ? 'Supplier added'
                            : 'Supplier updated',
                      ),
                    ),
                  );
                } catch (error) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Save failed: $error')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supplier List')),
      drawer: const MainDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSupplierDialog(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _suppliers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final suppliers = snapshot.data ?? [];
          if (suppliers.isEmpty) {
            return const Center(child: Text('No suppliers found.'));
          }

          return ListView.builder(
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index] as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(supplier['name'].toString()),
                  subtitle: Text(
                    'Contact: ${supplier['contact']}\nEmail: ${supplier['email']}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showSupplierDialog(supplier: supplier),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
