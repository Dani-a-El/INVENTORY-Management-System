import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

/// Supplier management screen with list, search, edit, and delete flows.
class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  late Future<List<dynamic>> _suppliersFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Load the suppliers once and reuse the FutureBuilder refresh pattern.
    _suppliersFuture = ApiService.getSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    // Re-fetch suppliers after add, edit, or delete.
    setState(() {
      _suppliersFuture = ApiService.getSuppliers();
    });
  }

  List<Map<String, dynamic>> _filterSuppliers(List<dynamic> suppliers) {
    // Filter locally so the list updates instantly while typing.
    final trimmedQuery = _query.trim().toLowerCase();

    return suppliers.cast<Map<String, dynamic>>().where((supplier) {
      if (trimmedQuery.isEmpty) {
        return true;
      }

      final searchableText = [
        supplier['name'],
        supplier['contact'],
        supplier['email'],
      ].map((value) => value.toString().toLowerCase()).join(' ');

      return searchableText.contains(trimmedQuery);
    }).toList();
  }

  Future<void> _deleteSupplier(int id) async {
    // Keep destructive actions behind a confirmation dialog.
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete supplier?'),
          content: const Text('This removes the supplier from the list.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) {
      return;
    }

    await ApiService.deleteSupplier(id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Supplier deleted')));
    _refresh();
  }

  Future<void> _openForm({Map<String, dynamic>? supplier}) async {
    // Use the same form for create and edit, driven by the optional supplier.
    final saved = await Navigator.of(context).push<bool>(
      AppRoutes.buildPageRoute(SupplierFormPage(supplier: supplier)),
    );

    if (saved == true) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeName =
        ModalRoute.of(context)?.settings.name ?? AppRoutes.dashboard;

    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      drawer: AppDrawer(currentRouteName: routeName),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Supplier'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _suppliersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final filteredSuppliers = _filterSuppliers(snapshot.data ?? []);

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search suppliers',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) {
                    // Search stays local and instant for the current list.
                    setState(() {
                      _query = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (filteredSuppliers.isEmpty)
                  _emptyState()
                else
                  ...filteredSuppliers.map(
                    (supplier) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SupplierCard(
                        supplier: supplier,
                        onEdit: () => _openForm(supplier: supplier),
                        onDelete: () => _deleteSupplier(supplier['id'] as int),
                      ),
                    ),
                  ),
                const SizedBox(height: 72),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.local_shipping_outlined, size: 54),
            const SizedBox(height: 12),
            const Text(
              'No suppliers found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a supplier or use the search box to narrow the list.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Supplier'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final Map<String, dynamic> supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SupplierCard({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // The avatar uses the first letter so the card still feels personal even
    // without a supplier image.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE8F5F4),
                  child: Text(
                    supplier['name'].toString().isNotEmpty
                        ? supplier['name'].toString()[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    supplier['name'].toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SupplierInfoRow(
              icon: Icons.phone_rounded,
              label: supplier['contact'].toString(),
            ),
            const SizedBox(height: 8),
            _SupplierInfoRow(
              icon: Icons.email_rounded,
              label: supplier['email'].toString(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Edit supplier',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                ),
                IconButton(
                  tooltip: 'Delete supplier',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_rounded,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SupplierInfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
      ],
    );
  }
}

class SupplierFormPage extends StatefulWidget {
  final Map<String, dynamic>? supplier;

  const SupplierFormPage({super.key, this.supplier});

  @override
  State<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    // Seed the form when editing an existing supplier.
    if (widget.supplier != null) {
      _nameController.text = widget.supplier!['name'].toString();
      _contactController.text = widget.supplier!['contact'].toString();
      _emailController.text = widget.supplier!['email'].toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Disable the button while the API call is in progress.
    setState(() {
      _saving = true;
    });

    final data = {
      'name': _nameController.text.trim(),
      'contact': _contactController.text.trim(),
      'email': _emailController.text.trim(),
    };

    try {
      if (widget.supplier == null) {
        await ApiService.addSupplier(data);
      } else {
        await ApiService.updateSupplier(widget.supplier!['id'] as int, data);
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.supplier == null
                ? 'Supplier added successfully'
                : 'Supplier updated successfully',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.supplier != null;

    // One form handles both add and edit, with the title and button text
    // adapting to the current mode.
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Supplier' : 'Add Supplier')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Supplier Name'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a supplier name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a contact number'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter an email'
                      : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _saveSupplier,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isEdit ? Icons.save_rounded : Icons.add_rounded),
                    label: Text(isEdit ? 'Update Supplier' : 'Add Supplier'),
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
