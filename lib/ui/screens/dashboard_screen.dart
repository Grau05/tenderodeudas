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

class _UpcomingItem {
  final int clientId;
  final String clientName;
  final DateTime dueDate;
  final int daysLeft;
  final Color color;

  _UpcomingItem({
    required this.clientId,
    required this.clientName,
    required this.dueDate,
    required this.daysLeft,
    required this.color,
  });
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AppDatabase _db;
  bool _inited = false;
  bool _loading = false;
  double _totalPendiente = 0;
  double _totalPagado = 0;
  double _totalVencido = 0;
  List<_UpcomingItem> _upcoming = [];
  // Toggle para aislar rendimiento: desactiva 'Próximos pagos'
  static const bool _disableUpcoming = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    _db = context.read<AppDatabase>();
    // Diferir la carga hasta después del primer frame para evitar jank inicial
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Ejecutar en paralelo para reducir el tiempo total de espera
      final fP = _db.totalPending();
      final fG = _db.totalPaid();
      final fV = _db.totalOverdue();
      final fU = _disableUpcoming ? Future.value(<_UpcomingItem>[]) : _computeUpcoming();
      final p = await fP;
      final g = await fG;
      final v = await fV;
      final upcoming = await fU;
      if (!mounted) return;
      setState(() {
        _totalPendiente = p;
        _totalPagado = g;
        _totalVencido = v;
        _upcoming = upcoming;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<_UpcomingItem>> _computeUpcoming() async {
    try {
      final now = DateTime.now();
      final allDebts = await _db.getAllDebts();
      // Filtrar por fecha en memoria y calcular pendientes en lote
      final futureDebts = allDebts.where((d) => d.dueDate.isAfter(now)).toList();
      final ids = futureDebts.map((e) => e.id).toList(growable: false);
      final pendings = await _db.pendingAmountsForDebtIds(ids);
      final candidates = futureDebts.where((d) => (pendings[d.id] ?? 0) > 0).toList();
      // Agrupar por cliente y tomar la fecha más próxima
      final Map<int, DateTime> minDueByClient = {};
      for (final d in candidates) {
        final current = minDueByClient[d.clientId];
        if (current == null || d.dueDate.isBefore(current)) {
          minDueByClient[d.clientId] = d.dueDate;
        }
      }
      // Obtener nombres de clientes (una sola vez)
      final clients = await _db.getAllClients();
      final Map<int, Client> clientById = {for (final c in clients) c.id: c};
      // Mapear a ítems y categorizar por días restantes
      final items = <_UpcomingItem>[];
      for (final entry in minDueByClient.entries) {
        final cid = entry.key;
        final due = entry.value;
        final days = due.difference(now).inDays;
        if (days > 30) continue; // Solo hasta 30 días
        final client = clientById[cid];
        if (client == null) continue;
        final color = days <= 3
            ? Colors.red
            : (days <= 7 ? Colors.amber : Colors.green);
        items.add(_UpcomingItem(clientId: cid, clientName: client.name, dueDate: due, daysLeft: days, color: color));
      }
      // Ordenar por fecha más próxima
      items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return items;
    } catch (e, st) {
      debugPrint('Error en _computeUpcoming: $e\n$st');
      return <_UpcomingItem>[];
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
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isNarrow = constraints.maxWidth < 520;
                      final cards = [
                        _StatCard(
                          title: 'Pendiente',
                          value: Fmt.money(_totalPendiente),
                          icon: Icons.hourglass_bottom,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        _StatCard(
                          title: 'Vencido',
                          value: Fmt.money(_totalVencido),
                          icon: Icons.warning_amber_rounded,
                          color: Colors.amber,
                        ),
                        _StatCard(
                          title: 'Pagado',
                          value: Fmt.money(_totalPagado),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ];
                      if (isNarrow) {
                        return Column(
                          children: [
                            for (int i = 0; i < cards.length; i++) ...[
                              cards[i],
                              if (i != cards.length - 1) const SizedBox(height: 8),
                            ]
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 12),
                          Expanded(child: cards[1]),
                          const SizedBox(width: 12),
                          Expanded(child: cards[2]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  if (!_disableUpcoming) ...[
                    Text('Próximos pagos', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (_upcoming.isEmpty)
                      Text('No hay pagos próximos en los próximos 30 días', style: Theme.of(context).textTheme.bodyMedium)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _upcoming.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final it = _upcoming[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: it.color.withOpacity(0.2), child: Icon(Icons.event, color: it.color)),
                              title: Text(it.clientName),
                              subtitle: Text('Vence: ${Fmt.date(it.dueDate)}  • En ${it.daysLeft} días'),
                              trailing: Icon(Icons.circle, size: 10, color: it.color),
                              onTap: () => Navigator.pushNamed(context, RegisterPaymentScreen.routeName, arguments: it.clientId),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
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
    return Card(
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
    );
  }
}
