import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<dynamic>> _productsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Load the list once up front; pull-to-refresh can reload it later.
    _productsFuture = ApiService.getProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    // Recreate the future so FutureBuilder fetches fresh product data.
    setState(() {
      _productsFuture = ApiService.getProducts();
    });
  }

  Future<void> _deleteProduct(int id) async {
    // Confirm destructive actions before calling the backend.
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete product?'),
          content: const Text(
            'This will remove the product from the inventory list.',
          ),
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

    await ApiService.deleteProduct(id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Product deleted')));
    _refresh();
  }

  Future<void> _openForm({Map<String, dynamic>? product}) async {
    // Reuse the same form for create and edit flows.
    final saved = await Navigator.of(
      context,
    ).push<bool>(AppRoutes.buildPageRoute(ProductFormPage(product: product)));

    if (saved == true) {
      _refresh();
    }
  }

  List<Map<String, dynamic>> _filterProducts(List<dynamic> products) {
    // Keep search local so the UI stays responsive while filtering.
    final trimmedQuery = _query.trim().toLowerCase();

    return products.cast<Map<String, dynamic>>().where((product) {
      if (trimmedQuery.isEmpty) {
        return true;
      }

      final searchableText = [
        product['name'],
        product['sku'],
        product['category'],
      ].map((value) => value.toString().toLowerCase()).join(' ');

      return searchableText.contains(trimmedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // ModalRoute name is used to keep drawer selection in sync.
    final routeName =
        ModalRoute.of(context)?.settings.name ?? AppRoutes.dashboard;

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      drawer: AppDrawer(currentRouteName: routeName),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final filteredProducts = _filterProducts(snapshot.data ?? []);

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search products',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (filteredProducts.isEmpty)
                  _emptyState()
                else
                  ...filteredProducts.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: ValueKey(product['id']),
                        direction: DismissDirection.horizontal,
                        background: _swipeBackground(
                          color: const Color(0xFF2A9D8F),
                          icon: Icons.edit_rounded,
                          alignment: Alignment.centerLeft,
                          label: 'Edit',
                        ),
                        secondaryBackground: _swipeBackground(
                          color: Colors.redAccent,
                          icon: Icons.delete_rounded,
                          alignment: Alignment.centerRight,
                          label: 'Delete',
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            await _openForm(product: product);
                            return false;
                          }

                          await _deleteProduct(product['id'] as int);
                          return false;
                        },
                        child: _ProductCard(
                          product: product,
                          onEdit: () => _openForm(product: product),
                          onDelete: () => _deleteProduct(product['id'] as int),
                        ),
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
            const Icon(Icons.inventory_2_outlined, size: 54),
            const SizedBox(height: 12),
            const Text(
              'No products found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a product or clear your search to see the full catalog.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
          if (alignment == Alignment.centerRight) ...[
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: color),
          ],
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final quantity = _asInt(product['quantity']);
    final price = _asDouble(product['price']);
    final isLowStock = quantity < 5;

    // The card keeps the inventory details easy to scan at a glance.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'].toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('SKU: ${product['sku']}'),
                    ],
                  ),
                ),
                if (isLowStock)
                  const Chip(
                    label: Text('Low stock'),
                    backgroundColor: Color(0xFFFFE7D6),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: 'Category',
                  value: product['category'].toString(),
                ),
                _InfoChip(label: 'Quantity', value: quantity.toString()),
                _InfoChip(
                  label: 'Price',
                  value: 'UGX ${price.toStringAsFixed(2)}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Edit product',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                ),
                IconButton(
                  tooltip: 'Delete product',
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

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: const Color(0xFFF2F8FB),
    );
  }
}

class ProductFormPage extends StatefulWidget {
  final Map<String, dynamic>? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    if (widget.product != null) {
      _nameController.text = widget.product!['name'].toString();
      _skuController.text = widget.product!['sku'].toString();
      _categoryController.text = widget.product!['category'].toString();
      _priceController.text = widget.product!['price'].toString();
      _quantityController.text = widget.product!['quantity'].toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show a loading state while the API call is in flight.
    setState(() {
      _saving = true;
    });

    final data = {
      'name': _nameController.text.trim(),
      'sku': _skuController.text.trim(),
      'category': _categoryController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0,
      'quantity': int.tryParse(_quantityController.text) ?? 0,
    };

    try {
      if (widget.product == null) {
        await ApiService.addProduct(data);
      } else {
        await ApiService.updateProduct(widget.product!['id'] as int, data);
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product == null
                ? 'Product added successfully'
                : 'Product updated successfully',
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
    final isEdit = widget.product != null;

    // The same form handles both create and edit, so the labels adapt based
    // on whether an existing product was passed in.
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Product' : 'Add Product')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a product name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(labelText: 'SKU'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a SKU'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a category'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (UGX)',
                    prefixText: 'UGX ',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a price in UGX'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a quantity'
                      : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _saveProduct,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isEdit ? Icons.save_rounded : Icons.add_rounded),
                    label: Text(isEdit ? 'Update Product' : 'Add Product'),
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
