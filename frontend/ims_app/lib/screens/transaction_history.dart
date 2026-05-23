import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

/// Transaction history screen with search and type/date filtering.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<dynamic>> _transactionsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedType = 'all';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Load the transaction list once when the page opens.
    _transactionsFuture = ApiService.getTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    // Recreate the future so pull-to-refresh always fetches fresh history.
    setState(() {
      _transactionsFuture = ApiService.getTransactions();
    });
  }

  Future<void> _pickDate() async {
    // The date filter is optional and only narrows the current list when the
    // user explicitly chooses a date.
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _selectedDate ?? DateTime.now(),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  List<Map<String, dynamic>> _filterTransactions(List<dynamic> transactions) {
    // Apply the filters locally so search and chips respond immediately.
    final trimmedQuery = _query.trim().toLowerCase();

    return transactions.cast<Map<String, dynamic>>().where((transaction) {
      final type = transaction['type']?.toString().toLowerCase() ?? '';
      final timestamp = transaction['timestamp']?.toString() ?? '';
      final productName =
          transaction['product_name']?.toString().toLowerCase() ?? '';

      if (_selectedType != 'all' && type != _selectedType) {
        return false;
      }

      if (_selectedDate != null) {
        final dateText = _formatDate(transaction['timestamp']);
        if (!dateText.startsWith(_formatDate(_selectedDate))) {
          return false;
        }
      }

      if (trimmedQuery.isEmpty) {
        return true;
      }

      return [
        productName,
        type,
        timestamp.toLowerCase(),
      ].join(' ').contains(trimmedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final routeName =
        ModalRoute.of(context)?.settings.name ?? AppRoutes.dashboard;

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      drawer: AppDrawer(currentRouteName: routeName),
      body: FutureBuilder<List<dynamic>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final filteredTransactions = _filterTransactions(snapshot.data ?? []);

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search transactions',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) {
                    // Search is intentionally local so the UI stays fast while
                    // the user types.
                    setState(() {
                      _query = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedType == 'all',
                      onSelected: (_) => setState(() => _selectedType = 'all'),
                    ),
                    ChoiceChip(
                      label: const Text('Stock In'),
                      selected: _selectedType == 'in',
                      selectedColor: const Color(0xFFDDF5EC),
                      onSelected: (_) => setState(() => _selectedType = 'in'),
                    ),
                    ChoiceChip(
                      label: const Text('Stock Out'),
                      selected: _selectedType == 'out',
                      selectedColor: const Color(0xFFFFE3DD),
                      onSelected: (_) => setState(() => _selectedType = 'out'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text(
                        _selectedDate == null
                            ? 'Filter by date'
                            : _formatDate(_selectedDate),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedDate != null || _selectedType != 'all')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Text('Active filters:'),
                        const SizedBox(width: 8),
                        if (_selectedType != 'all')
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text(
                                _selectedType == 'in'
                                    ? 'Stock In'
                                    : 'Stock Out',
                              ),
                            ),
                          ),
                        if (_selectedDate != null)
                          Chip(label: Text(_formatDate(_selectedDate))),
                      ],
                    ),
                  ),
                if (filteredTransactions.isEmpty)
                  _emptyState()
                else
                  ...filteredTransactions.map(
                    (transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TransactionCard(transaction: transaction),
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
            const Icon(Icons.receipt_long_outlined, size: 54),
            const SizedBox(height: 12),
            const Text(
              'No transactions found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try clearing your filters or post a new stock movement.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: const Text('Refresh')),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return '';
    }

    final text = value.toString();
    final parsed = DateTime.tryParse(text.replaceFirst(' ', 'T'));
    final date =
        parsed ??
        DateTime.tryParse(text.split('.').first.replaceFirst(' ', 'T'));

    if (date == null) {
      return text.length >= 10 ? text.substring(0, 10) : text;
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    // Color the card by transaction type to make inbound and outbound stock
    // easy to spot at a glance.
    final isStockIn = transaction['type']?.toString() == 'in';
    final badgeColor = isStockIn
        ? const Color(0xFFDDF5EC)
        : const Color(0xFFFFE3DD);
    final badgeTextColor = isStockIn
        ? const Color(0xFF2A9D8F)
        : const Color(0xFFD97706);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isStockIn
                    ? Icons.call_received_rounded
                    : Icons.call_made_rounded,
                color: badgeTextColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction['product_name'].toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Chip(
                        backgroundColor: badgeColor,
                        label: Text(
                          isStockIn ? 'IN' : 'OUT',
                          style: TextStyle(
                            color: badgeTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Quantity: ${transaction['quantity']}'),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(transaction['timestamp']),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic value) {
    final text = value?.toString() ?? '';
    final parsed = DateTime.tryParse(text.replaceFirst(' ', 'T'));
    if (parsed == null) {
      return text;
    }

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$day/$month/${parsed.year} at $hour:$minute';
  }
}
