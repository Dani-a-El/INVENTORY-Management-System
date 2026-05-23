import 'dart:async';

import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _startupTimer;

  @override
  void initState() {
    super.initState();
    // Hold the splash briefly so bootstrap and branding both feel deliberate.
    _startupTimer = Timer(const Duration(seconds: 2), _bootstrap);
  }

  @override
  void dispose() {
    // Cancel the timer to avoid navigation after the widget is removed.
    _startupTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      // Restore auth state before deciding whether to route to login or the
      // dashboard flow.
      await AuthService.instance.initialize();
      await Future<void>.delayed(const Duration(seconds: 2));
    } catch (_) {
      // Even if initialization fails, keep the splash timing consistent.
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    if (!mounted) {
      return;
    }

    final nextRoute = AuthService.instance.isAuthenticated
        ? AppRoutes.dashboard
        : AppRoutes.login;

    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A9D8F), Color(0xFF4A90E2), Color(0xFFF4A261)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Inventory Management System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Simple stock control for your business',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading app...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
