import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'dashboard.dart';

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late Future<Map<String, dynamic>> _healthCheck;
  bool _redirectingToLogin = false;

  @override
  void initState() {
    super.initState();
    // Start the backend health probe once when the dashboard flow opens.
    _healthCheck = ApiService.checkDatabaseHealth();
  }

  void _retry() {
    // Re-run the same health probe when the user taps Retry.
    setState(() {
      _healthCheck = ApiService.checkDatabaseHealth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _healthCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final status = snapshot.data?['status']?.toString();
        if (!AuthService.instance.isAuthenticated) {
          // Protect the dashboard from being shown without a valid session.
          if (!_redirectingToLogin) {
            _redirectingToLogin = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }

              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
            });
          }

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (status == 'offline') {
          // Keep the UI friendly when the backend is reachable but the
          // database itself is not.
          final message =
              snapshot.data?['message']?.toString() ??
              'Database offline. Check MySQL and backend credentials.';

          return Scaffold(
            appBar: AppBar(title: const Text('Inventory Management System')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 72,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Database offline',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(message, textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry connection'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return const DashboardScreen();
      },
    );
  }
}
