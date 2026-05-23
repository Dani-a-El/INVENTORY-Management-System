import 'package:flutter/material.dart';

import 'screens/forgot_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/product_list.dart';
import 'screens/stock_in_out.dart';
import 'screens/startup_gate.dart';
import 'screens/supplier_list.dart';
import 'screens/transaction_history.dart';

/// Central route registry for the Flutter app.
class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const settings = '/settings';
  static const dashboard = '/';
  static const products = '/products';
  static const stock = '/stock';
  static const suppliers = '/suppliers';
  static const transactions = '/transactions';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    // Keep route resolution in one place so navigation stays predictable.
    switch (routeSettings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), routeSettings);
      case login:
        return _buildRoute(const LoginScreen(), routeSettings);
      case register:
        return _buildRoute(const RegisterScreen(), routeSettings);
      case forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), routeSettings);
      case settings:
        return _buildRoute(const SettingsScreen(), routeSettings);
      case dashboard:
        return _buildRoute(const StartupGate(), routeSettings);
      case products:
        return _buildRoute(const ProductListScreen(), routeSettings);
      case stock:
        return _buildRoute(const StockInOutScreen(), routeSettings);
      case suppliers:
        return _buildRoute(const SupplierListScreen(), routeSettings);
      case transactions:
        return _buildRoute(const TransactionHistoryScreen(), routeSettings);
      default:
        return _buildRoute(const SplashScreen(), routeSettings);
    }
  }

  static PageRouteBuilder<T> buildPageRoute<T>(Widget page) {
    return _buildRoute<T>(page, const RouteSettings());
  }

  static PageRouteBuilder<T> _buildRoute<T>(
    Widget page,
    RouteSettings settings,
  ) {
    // Use the same transition for forms and module pages so the app feels
    // consistent no matter where navigation starts.
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(curvedAnimation);

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
    );
  }
}
