import 'package:flutter/material.dart';

import 'routes.dart';
import 'services/app_settings_service.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const IMSApp());
}

/// Top-level app widget that boots shared services before showing MaterialApp.
class IMSApp extends StatefulWidget {
  const IMSApp({super.key});

  @override
  State<IMSApp> createState() => _IMSAppState();
}

class _IMSAppState extends State<IMSApp> {
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    // Load settings and auth together so theme and session state are ready
    // before the first visible route is built.
    _bootstrapFuture = Future.wait([
      AppSettingsService.instance.initialize(),
      AuthService.instance.initialize(),
    ]).then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Keep the app simple during bootstrap: show a loading shell until
          // shared state is ready.
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppSettingsService.instance.themeModeNotifier,
          builder: (context, themeMode, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Inventory Management System',
              theme: _buildLightTheme(),
              darkTheme: _buildDarkTheme(),
              themeMode: themeMode,
              initialRoute: AppRoutes.splash,
              onGenerateRoute: AppRoutes.onGenerateRoute,
            );
          },
        );
      },
    );
  }
}

ThemeData _buildLightTheme() {
  const seedColor = Color(0xFF2A9D8F);
  // Build a soft, branded light theme that matches the app's UI language.
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF2A9D8F),
        secondary: const Color(0xFF4A90E2),
        tertiary: const Color(0xFFF4A261),
        surface: const Color(0xFFF7FBFC),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: const Color(0xFFF3FAFB),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 2,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        shadowColor: Colors.black26,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      labelStyle: TextStyle(color: colorScheme.onSurface),
      backgroundColor: const Color(0xFFE8F5F4),
      side: BorderSide(color: colorScheme.outlineVariant),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFFF7FBFC),
      surfaceTintColor: Colors.transparent,
    ),
  );
}

ThemeData _buildDarkTheme() {
  // Keep the dark theme intentionally simple; the light theme carries most of
  // the custom design work.
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xFF2A9D8F),
    fontFamily: 'Roboto',
  );
}
