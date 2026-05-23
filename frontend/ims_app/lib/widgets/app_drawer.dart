import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  final String currentRouteName;

  const AppDrawer({super.key, this.currentRouteName = AppRoutes.dashboard});

  @override
  Widget build(BuildContext context) {
    // Normalize the selected route so the drawer highlights stay stable even
    // when the incoming route name is empty.
    final selectedRoute = currentRouteName.isEmpty
        ? AppRoutes.dashboard
        : currentRouteName;
    final currentUser = AuthService.instance.currentUser;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2A9D8F), Color(0xFF4A90E2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: Color(0xFF2A9D8F),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    currentUser?.name ?? 'IMS Admin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser?.email ?? 'admin@inventory.local',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    selected: selectedRoute == AppRoutes.dashboard,
                    onTap: () => _navigate(context, AppRoutes.dashboard),
                  ),
                  _DrawerItem(
                    icon: Icons.inventory_2_rounded,
                    label: 'Products',
                    selected: selectedRoute == AppRoutes.products,
                    onTap: () => _navigate(context, AppRoutes.products),
                  ),
                  _DrawerItem(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Stock In / Out',
                    selected: selectedRoute == AppRoutes.stock,
                    onTap: () => _navigate(context, AppRoutes.stock),
                  ),
                  _DrawerItem(
                    icon: Icons.local_shipping_rounded,
                    label: 'Suppliers',
                    selected: selectedRoute == AppRoutes.suppliers,
                    onTap: () => _navigate(context, AppRoutes.suppliers),
                  ),
                  _DrawerItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Transactions',
                    selected: selectedRoute == AppRoutes.transactions,
                    onTap: () => _navigate(context, AppRoutes.transactions),
                  ),
                  const Divider(height: 28),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    selected: selectedRoute == AppRoutes.settings,
                    onTap: () => _navigate(context, AppRoutes.settings),
                  ),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    selected: false,
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String routeName) {
    // Close the drawer first so the page transition is not hidden behind it.
    Navigator.pop(context);
    if (routeName == currentRouteName) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(routeName);
  }

  Future<void> _logout(BuildContext context) async {
    // Logout is handled centrally so the token and route stack are both reset.
    Navigator.pop(context);
    await AuthService.instance.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
