export 'stock_in_out.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/main_drawer.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _productIdController = TextEditingController();
  final _quantityController = TextEditingController();

  Future<void> _submit(String type) async {
    final productId = int.tryParse(_productIdController.text);
    final quantity = int.tryParse(_quantityController.text);

    if (productId == null || quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid product ID and quantity')),
      );
      return;
    }

    try {
      if (type == 'in') {
        await ApiService.stockIn(productId, quantity);
      } else {
        await ApiService.stockOut(productId, quantity);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock $type operation completed')),
      );
      _productIdController.clear();
      _quantityController.clear();
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock In/Out')),
      drawer: const MainDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Enter Product ID and Quantity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _productIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Product ID'),
            ),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _submit('in'),
              child: const Text('Stock In'),
            ),
            ElevatedButton(
              onPressed: () => _submit('out'),
              child: const Text('Stock Out'),
            ),
          ],
        ),
      ),
    );
  }
}
