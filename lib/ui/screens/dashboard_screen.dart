import 'package:flutter/material.dart';
import 'clients_screen.dart';
import 'new_debt_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  static const routeName = '/';
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen rápido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatCard(title: 'Pendiente', value: '\$0'),
                const SizedBox(width: 12),
                _StatCard(title: 'Vencido', value: '\$0'),
                const SizedBox(width: 12),
                _StatCard(title: 'Pagado', value: '\$0'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Acciones rápidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, ClientsScreen.routeName),
                  icon: const Icon(Icons.people),
                  label: const Text('Clientes'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, NewDebtScreen.routeName),
                  icon: const Icon(Icons.add_card),
                  label: const Text('Nueva deuda'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, ReportsScreen.routeName),
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Reportes'),
                ),
              ],
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, SettingsScreen.routeName),
        child: const Icon(Icons.settings),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
