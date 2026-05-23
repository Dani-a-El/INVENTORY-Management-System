export 'app_drawer.dart';
import 'package:flutter/material.dart';

import '../routes.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'IMS Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          _drawerItem(context, 'Dashboard', AppRoutes.dashboard),
          _drawerItem(context, 'Product List', AppRoutes.products),
          _drawerItem(context, 'Stock In/Out', AppRoutes.stock),
          _drawerItem(context, 'Supplier List', AppRoutes.suppliers),
          _drawerItem(context, 'Transaction History', AppRoutes.transactions),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, String title, String routeName) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, routeName);
      },
    );
  }
}
