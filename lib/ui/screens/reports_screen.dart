import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/db/app_database.dart';
import '../../services/export_service.dart';
import '../../utils/format.dart';

class ReportsScreen extends StatefulWidget {
  static const routeName = '/reports';
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final AppDatabase _db;
  bool _loading = false;
  double _totalPendiente = 0;
  double _totalPagado = 0;
  double _totalVencido = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _db = context.read<AppDatabase>();
    // Cargar cuando el árbol y providers estén listos
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _db.totalPending();
      final g = await _db.totalPaid();
      final v = await _db.totalOverdue();
      setState(() {
        _totalPendiente = p;
        _totalPagado = g;
        _totalVencido = v;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _export() async {
    setState(() => _loading = true);
    try {
      final clients = await _db.getAllClients();
      final debts = await _db.getAllDebts();
      final payments = await _db.getAllPayments();

      final clientRows = <List<String>>[
        ['ID', 'Nombre', 'Teléfono', 'Dirección', 'Activo', 'Creado']
      ];
      for (final c in clients) {
        clientRows.add([
          c.id.toString(),
          c.name,
          c.phone,
          c.address ?? '',
          c.active ? 'Sí' : 'No',
          c.createdAt.toIso8601String(),
        ]);
      }

      final debtRows = <List<String>>[
        ['ID', 'ClienteID', 'Monto', 'Descripción', 'Vence', 'Estado', 'Creado']
      ];
      for (final d in debts) {
        debtRows.add([
          d.id.toString(),
          d.clientId.toString(),
          d.amount.toStringAsFixed(2),
          d.description ?? '',
          d.dueDate.toIso8601String(),
          d.status,
          d.createdAt.toIso8601String(),
        ]);
      }

      final paymentRows = <List<String>>[
        ['ID', 'DeudaID', 'Monto', 'Fecha', 'Nota']
      ];
      for (final p in payments) {
        paymentRows.add([
          p.id.toString(),
          p.debtId.toString(),
          p.amount.toStringAsFixed(2),
          p.date.toIso8601String(),
          p.note ?? '',
        ]);
      }

      final file = await ExportService.exportBasic(
        clients: clientRows,
        debts: debtRows,
        payments: paymentRows,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Exportado a: ${file.path}')),
      );
      // Ofrecer compartir el archivo
      await Share.shareXFiles([XFile(file.path)], text: 'Reporte de deudas');
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _export,
            icon: const Icon(Icons.ios_share),
            tooltip: 'Exportar a Excel',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _StatTile(
                              icon: Icons.pending_actions,
                              title: 'Total pendiente',
                              value: Fmt.money(_totalPendiente),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _StatTile(
                              icon: Icons.check_circle,
                              title: 'Total pagado',
                              value: Fmt.money(_totalPagado),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _StatTile(
                        icon: Icons.warning_amber,
                        title: 'Total vencido (pendiente)',
                        value: Fmt.money(_totalVencido),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Distribución', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 220,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 32,
                                sections: _buildPieSections(context),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _Legend(
                            pendiente: _totalPendiente,
                            pagado: _totalPagado,
                            vencido: _totalVencido,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Acciones', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _export,
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Exportar a Excel'),
                  ),
                ],
              ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(BuildContext context) {
    final total = (_totalPendiente + _totalPagado + _totalVencido).clamp(0, double.infinity);
    final theme = Theme.of(context).colorScheme;
    if (total == 0) {
      // Sin datos: mostrar gráfico vacío sin etiquetas
      return [
        PieChartSectionData(
          color: theme.surfaceContainerHighest,
          value: 1,
          title: '',
          radius: 50,
        )
      ];
    }
    return [
      PieChartSectionData(
        color: Colors.amberAccent.shade200,
        value: _totalVencido,
        title: '',
        radius: 60,
      ),
      PieChartSectionData(
        color: Colors.lightBlueAccent.shade200,
        value: _totalPendiente,
        title: '',
        radius: 60,
      ),
      PieChartSectionData(
        color: Colors.greenAccent.shade200,
        value: _totalPagado,
        title: '',
        radius: 60,
      ),
    ];
  }
}

class _Legend extends StatelessWidget {
  final double pendiente;
  final double pagado;
  final double vencido;
  const _Legend({required this.pendiente, required this.pagado, required this.vencido});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LegendRow(color: Colors.lightBlueAccent.shade200, label: 'Pendiente', value: Fmt.money(pendiente)),
        _LegendRow(color: Colors.greenAccent.shade200, label: 'Pagado', value: Fmt.money(pagado)),
        _LegendRow(color: Colors.amberAccent.shade200, label: 'Vencido', value: Fmt.money(vencido)),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _StatTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ],
    );
  }
}
