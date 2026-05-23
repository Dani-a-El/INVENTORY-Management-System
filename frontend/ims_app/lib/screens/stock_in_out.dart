import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

/// Stock movement page for posting stock in and stock out transactions.
class StockInOutScreen extends StatefulWidget {
  const StockInOutScreen({super.key});

  @override
  State<StockInOutScreen> createState() => _StockInOutScreenState();
}

class _StockInOutScreenState extends State<StockInOutScreen> {
  late Future<List<dynamic>> _productsFuture;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  int? _selectedProductId;
  String _movementType = 'in';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Load the product list once so the dropdown can be built from live data.
    _productsFuture = ApiService.getProducts();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _refreshProducts() {
    // Rebuild the future after a successful stock movement so the dropdown
    // stays in sync with updated product data.
    setState(() {
      _productsFuture = ApiService.getProducts();
    });
  }

  Future<void> _submitStockMovement(List<dynamic> products) async {
    if (!_formKey.currentState!.validate() || _selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a product and enter a valid quantity.'),
        ),
      );
      return;
    }

    // Resolve the selected product so the confirmation dialog shows a clear
    // human-readable label instead of only an ID.
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final selectedProduct = products.cast<Map<String, dynamic>>().firstWhere(
      (product) => product['id'] == _selectedProductId,
      orElse: () => <String, dynamic>{},
    );
    final productName =
        selectedProduct['name']?.toString() ?? 'Selected product';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        // Stock updates are immediate, so confirm the action before calling
        // the backend.
        return AlertDialog(
          title: Text(
            _movementType == 'in' ? 'Confirm stock in' : 'Confirm stock out',
          ),
          content: Text(
            'Product: $productName\nQuantity: $quantity\n\nNotes: ${_notesController.text.isEmpty ? 'None' : _notesController.text}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      // Choose the backend endpoint based on the stock direction toggle.
      if (_movementType == 'in') {
        await ApiService.stockIn(_selectedProductId!, quantity);
      } else {
        await ApiService.stockOut(_selectedProductId!, quantity);
      }

      if (!mounted) {
        return;
      }

      _quantityController.clear();
      _notesController.clear();
      _refreshProducts();

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Success'),
            content: Text(
              _movementType == 'in'
                  ? 'Stock has been added successfully.'
                  : 'Stock has been removed successfully.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submission failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeName =
        ModalRoute.of(context)?.settings.name ?? AppRoutes.dashboard;

    return Scaffold(
      appBar: AppBar(title: const Text('Stock In / Out')),
      drawer: AppDrawer(currentRouteName: routeName),
      body: FutureBuilder<List<dynamic>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return _emptyState();
          }

          // Cast once so the form and confirmation dialog can reuse the same
          // strongly typed list.
          final productItems = products.cast<Map<String, dynamic>>();

          return RefreshIndicator(
            onRefresh: () async => _refreshProducts(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Update inventory levels',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Choose a product, enter the quantity, and add a short note if you want.',
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedProductId,
                            decoration: const InputDecoration(
                              labelText: 'Select product',
                            ),
                            items: productItems
                                .map(
                                  (product) => DropdownMenuItem<int>(
                                    value: product['id'] as int,
                                    child: Text(
                                      '${product['name']} (SKU: ${product['sku']})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              // Keep selection in local state so validation and
                              // submission know which product to use.
                              setState(() {
                                _selectedProductId = value;
                              });
                            },
                            validator: (value) => value == null
                                ? 'Please select a product'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                            ),
                            validator: (value) {
                              final quantity = int.tryParse(value ?? '');
                              if (quantity == null || quantity <= 0) {
                                return 'Enter a quantity greater than zero';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                            ),
                          ),
                          const SizedBox(height: 16),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'in',
                                label: Text('Stock In'),
                                icon: Icon(Icons.add_circle_outline_rounded),
                              ),
                              ButtonSegment(
                                value: 'out',
                                label: Text('Stock Out'),
                                icon: Icon(Icons.remove_circle_outline_rounded),
                              ),
                            ],
                            selected: {_movementType},
                            onSelectionChanged: (selection) {
                              setState(() {
                                _movementType = selection.first;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _submitting
                                  ? null
                                  : () => _submitStockMovement(productItems),
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _movementType == 'in'
                                          ? Icons.call_received_rounded
                                          : Icons.call_made_rounded,
                                    ),
                              label: Text(
                                _movementType == 'in'
                                    ? 'Submit Stock In'
                                    : 'Submit Stock Out',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    // Show a plain empty state because stock changes require at least one
    // product to exist.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 54),
                const SizedBox(height: 12),
                const Text(
                  'No products available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a product first before posting stock movements.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.products),
                  child: const Text('Go to Products'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
