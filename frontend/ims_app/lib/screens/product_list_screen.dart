export 'product_list.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/main_drawer.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<dynamic>> _products;

  @override
  void initState() {
    super.initState();
    _products = ApiService.getProducts();
  }

  void _refresh() {
    setState(() {
      _products = ApiService.getProducts();
    });
  }

  Future<void> _deleteProduct(int id) async {
    await ApiService.deleteProduct(id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product List')),
      drawer: const MainDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductFormScreen()),
          );
          _refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index] as Map<String, dynamic>;
              final isLowStock = (product['quantity'] as int) < 5;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text('${product['name']} (${product['sku']})'),
                  subtitle: Text(
                    'Category: ${product['category']}\n'
                    'Price: UGX ${product['price']} | Quantity: ${product['quantity']}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLowStock)
                        const Text('Low', style: TextStyle(color: Colors.red)),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductFormScreen(product: product),
                              ),
                            );
                            _refresh();
                          } else if (value == 'delete') {
                            await _deleteProduct(product['id'] as int);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
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
}

class ProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isEdit = widget.product != null;

    final data = {
      'name': _nameController.text,
      'sku': _skuController.text,
      'category': _categoryController.text,
      'price': double.tryParse(_priceController.text) ?? 0,
      'quantity': int.tryParse(_quantityController.text) ?? 0,
    };

    try {
      if (widget.product == null) {
        await ApiService.addProduct(data);
      } else {
        await ApiService.updateProduct(widget.product!['id'] as int, data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Product updated' : 'Product added')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Product' : 'Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter product name'
                    : null,
              ),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter SKU' : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter category' : null,
              ),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (UGX)',
                  prefixText: 'UGX ',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter price in UGX'
                    : null,
              ),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter quantity' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveProduct,
                child: Text(isEdit ? 'Update Product' : 'Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
