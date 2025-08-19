import 'package:flutter/material.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exportado a: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.pending_actions),
                      title: const Text('Total pendiente'),
                      trailing: Text(Fmt.money(_totalPendiente)),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle),
                      title: const Text('Total pagado'),
                      trailing: Text(Fmt.money(_totalPagado)),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber),
                      title: const Text('Total vencido (pendiente)'),
                      trailing: Text(Fmt.money(_totalVencido)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold)),
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
}
