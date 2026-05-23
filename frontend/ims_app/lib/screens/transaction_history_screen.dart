export 'transaction_history.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/main_drawer.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<dynamic>> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = ApiService.getTransactions();
  }

  void _refresh() {
    setState(() {
      _transactions = ApiService.getTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      drawer: const MainDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<dynamic>>(
          future: _transactions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final transactions = snapshot.data ?? [];
            if (transactions.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 240),
                  Center(child: Text('No transactions found.')),
                ],
              );
            }

            return ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index] as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text('${tx['product_name']} (${tx['type']})'),
                    subtitle: Text(
                      'Quantity: ${tx['quantity']}\n'
                      'Time: ${tx['timestamp']}',
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
