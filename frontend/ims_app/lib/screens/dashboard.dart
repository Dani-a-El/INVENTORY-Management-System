import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

/// Main overview screen that combines dashboard metrics, health status, and
/// quick links into one place.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    // Load dashboard metrics, backend health, and supplier count together so
    // the page can render from one consistent snapshot.
    _dashboardFuture = _loadDashboardData();
  }

  Future<List<dynamic>> _loadDashboardData() {
    // The dashboard needs multiple backend reads, so fetch them in parallel.
    return Future.wait([
      ApiService.getDashboard(),
      ApiService.checkDatabaseHealth(),
      ApiService.getSuppliers(),
    ]);
  }

  void _reload() {
    // Rebuild the future so FutureBuilder fetches fresh values on refresh.
    setState(() {
      _dashboardFuture = _loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final routeName =
        ModalRoute.of(context)?.settings.name ?? AppRoutes.dashboard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      drawer: AppDrawer(currentRouteName: routeName),
      body: FutureBuilder<List<dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString());
          }

          // Unpack the parallel responses in the same order they were loaded.
          final results = snapshot.data ?? <dynamic>[];
          final dashboardData = results.isNotEmpty
              ? results[0] as Map<String, dynamic>
              : <String, dynamic>{};
          final healthData = results.length > 1
              ? results[1] as Map<String, dynamic>
              : <String, dynamic>{};
          final suppliers = results.length > 2
              ? results[2] as List<dynamic>
              : <dynamic>[];

          final totalProducts = _asInt(dashboardData['total_products']);
          final totalStock = _asInt(dashboardData['total_stock']);
          final lowStockCount = _asInt(dashboardData['low_stock_count']);
          final totalSuppliers = suppliers.length;
          final healthStatus = healthData['status']?.toString();
          final healthMessage = healthData['message']?.toString();

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _HeroCard(
                  totalProducts: totalProducts,
                  totalStock: totalStock,
                  lowStockCount: lowStockCount,
                  totalSuppliers: totalSuppliers,
                  onRefresh: _reload,
                ),
                if (healthStatus != null && healthStatus != 'ok') ...[
                  const SizedBox(height: 12),
                  _StatusBanner(
                    message:
                        healthMessage ?? 'Database connection needs attention.',
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.add_box_rounded,
                        label: 'Add Product',
                        color: const Color(0xFF2A9D8F),
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.products),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.call_received_rounded,
                        label: 'Stock In',
                        color: const Color(0xFF4A90E2),
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.stock),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.call_made_rounded,
                        label: 'Stock Out',
                        color: const Color(0xFFF4A261),
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.stock),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Inventory Snapshot',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _InventoryChart(
                  totalProducts: totalProducts,
                  totalStock: totalStock,
                  lowStockCount: lowStockCount,
                  totalSuppliers: totalSuppliers,
                ),
              ],
            ),
          );
        },
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

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 52,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int totalProducts;
  final int totalStock;
  final int lowStockCount;
  final int totalSuppliers;
  final VoidCallback onRefresh;

  const _HeroCard({
    required this.totalProducts,
    required this.totalStock,
    required this.lowStockCount,
    required this.totalSuppliers,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // The hero card is intentionally visual: it surfaces the summary metrics
    // first, then lets the rest of the dashboard scroll below.
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A9D8F), Color(0xFF4A90E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Inventory Management System',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'A quick overview of products, stock, and suppliers.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.85,
              children: [
                _StatMiniCard(
                  icon: Icons.inventory_2_rounded,
                  label: 'Products',
                  value: totalProducts.toString(),
                ),
                _StatMiniCard(
                  icon: Icons.view_list_rounded,
                  label: 'Total Stock',
                  value: totalStock.toString(),
                ),
                _StatMiniCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'Low Stock',
                  value: lowStockCount.toString(),
                ),
                _StatMiniCard(
                  icon: Icons.local_shipping_rounded,
                  label: 'Suppliers',
                  value: totalSuppliers.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatMiniCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.14),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(label, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;

  const _StatusBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF3E0),
      child: ListTile(
        leading: const Icon(Icons.info_rounded, color: Color(0xFFF4A261)),
        title: const Text('Database status'),
        subtitle: Text(message),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Keep quick actions compact so three buttons fit neatly in one row.
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryChart extends StatelessWidget {
  final int totalProducts;
  final int totalStock;
  final int lowStockCount;
  final int totalSuppliers;

  const _InventoryChart({
    required this.totalProducts,
    required this.totalStock,
    required this.lowStockCount,
    required this.totalSuppliers,
  });

  @override
  Widget build(BuildContext context) {
    // This chart is intentionally lightweight: it gives a visual cue without
    // requiring a chart package.
    final bars = <_BarData>[
      _BarData('Stock', totalStock.toDouble(), const Color(0xFF2A9D8F)),
      _BarData('Low', lowStockCount.toDouble(), const Color(0xFFF4A261)),
      _BarData('Products', totalProducts.toDouble(), const Color(0xFF4A90E2)),
      _BarData('Suppliers', totalSuppliers.toDouble(), const Color(0xFF7E7BED)),
    ];
    final maxValue = math.max(
      1.0,
      bars.map((bar) => bar.value).fold<double>(0, math.max),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stock overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final bar in bars)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              bar.value.toInt().toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(
                                    begin: 0,
                                    end: bar.value / maxValue,
                                  ),
                                  duration: const Duration(milliseconds: 700),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return FractionallySizedBox(
                                      heightFactor: value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: bar.color,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bar.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
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
}

class _BarData {
  final String label;
  final double value;
  final Color color;

  _BarData(this.label, this.value, this.color);
}
