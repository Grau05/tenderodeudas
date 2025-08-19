import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/navigation_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';

class RootShell extends StatelessWidget {
  static const routeName = '/';
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    final index = context.watch<NavigationProvider>().index;
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          DashboardScreen(),
          ClientsScreen(),
          ReportsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.read<NavigationProvider>().setIndex(i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reportes'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
