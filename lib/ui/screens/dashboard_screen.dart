import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/db/app_database.dart';
import '../../utils/format.dart';
import '../../providers/navigation_provider.dart';
import 'new_debt_screen.dart';
import 'register_payment_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = AppDatabase();
  bool _loading = false;
  double _totalPendiente = 0;
  double _totalPagado = 0;
  double _totalVencido = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _db.totalPending();
      final g = await _db.totalPaid();
      final v = await _db.totalOverdue();
      if (!mounted) return;
      setState(() {
        _totalPendiente = p;
        _totalPagado = g;
        _totalVencido = v;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumen rápido', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                        title: 'Pendiente',
                        value: Fmt.money(_totalPendiente),
                        icon: Icons.hourglass_bottom,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        title: 'Vencido',
                        value: Fmt.money(_totalVencido),
                        icon: Icons.warning_amber_rounded,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        title: 'Pagado',
                        value: Fmt.money(_totalPagado),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Acciones rápidas', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 3.2,
                    ),
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => Navigator.pushNamed(context, NewDebtScreen.routeName),
                        icon: const Icon(Icons.add_card),
                        label: const Text('Nueva deuda'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => Navigator.pushNamed(context, RegisterPaymentScreen.routeName),
                        icon: const Icon(Icons.payments),
                        label: const Text('Registrar pago'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => context.read<NavigationProvider>().setIndex(1),
                        icon: const Icon(Icons.search),
                        label: const Text('Buscar cliente'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => context.read<NavigationProvider>().setIndex(2),
                        icon: const Icon(Icons.bar_chart),
                        label: const Text('Reportes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      // NavigationBar persistente se maneja en RootShell
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Text(value, style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                foregroundColor: color,
                child: Icon(icon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
