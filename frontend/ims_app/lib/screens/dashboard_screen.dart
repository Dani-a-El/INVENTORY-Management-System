export 'dashboard.dart';
import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/api_service.dart';
import '../widgets/main_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardData;
  late Future<Map<String, dynamic>> _databaseHealth;

  @override
  void initState() {
    super.initState();
    _dashboardData = ApiService.getDashboard();
    _databaseHealth = ApiService.checkDatabaseHealth();
  }

  void _reload() {
    setState(() {
      _dashboardData = ApiService.getDashboard();
      _databaseHealth = ApiService.checkDatabaseHealth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _databaseHealth,
      builder: (context, healthSnapshot) {
        final status = healthSnapshot.data?['status']?.toString();
        final message = healthSnapshot.data?['message']?.toString();

        return Scaffold(
          appBar: AppBar(title: const Text('Dashboard')),
          drawer: const MainDrawer(),
          body: FutureBuilder<Map<String, dynamic>>(
            future: _dashboardData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final data = snapshot.data ?? {};
              final totalProducts = data['total_products'] ?? 0;
              final totalStock = data['total_stock'] ?? 0;
              final lowStockCount = data['low_stock_count'] ?? 0;

              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (status != null && status != 'ok')
                      _statusBanner(
                        message ??
                            'Database is degraded. Some actions may fail until the backend recovers.',
                      ),
                    _infoCard('Total Products', totalProducts.toString()),
                    _infoCard('Total Stock', totalStock.toString()),
                    _infoCard(
                      'Low Stock Alerts (< 5)',
                      lowStockCount.toString(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.products);
                      },
                      child: const Text('Go to Product List'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _statusBanner(String message) {
    return Card(
      color: Colors.orange.shade100,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: const Text('Database degraded'),
        subtitle: Text(message),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
