import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/debt_provider.dart';
import '../../providers/client_provider.dart';
import '../../core/db/app_database.dart';

class NewDebtScreen extends StatefulWidget {
  static const routeName = '/new-debt';
  const NewDebtScreen({super.key});

  @override
  State<NewDebtScreen> createState() => _NewDebtScreenState();
}

class _NewDebtScreenState extends State<NewDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  int? _clientId;
  Client? _client;
  bool _inited = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    _clientId = ModalRoute.of(context)!.settings.arguments as int?;
    if (_clientId != null) {
      context.read<ClientProvider>().getById(_clientId!).then((c) {
        if (mounted) setState(() => _client = c);
      });
    }
  }

  Future<void> _pickClient() async {
    final outerCtx = context;
    final prov = outerCtx.read<ClientProvider>();
    // Cargar sin esperar; el diálogo observará `loading`.
    prov.loadClients();
    if (!mounted) return;
    final selected = await showDialog<Client>(
      context: outerCtx,
      builder: (ctx) {
        final watch = ctx.watch<ClientProvider>();
        return AlertDialog(
          title: const Text('Seleccionar cliente'),
          content: SizedBox(
            width: double.maxFinite,
            child: watch.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: watch.clients.length,
                    itemBuilder: (_, i) {
                      final c = watch.clients[i];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(c.name),
                        subtitle: Text(c.phone),
                        onTap: () => Navigator.pop(ctx, c),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ],
        );
      },
    );
    if (selected != null) {
      setState(() {
        _clientId = selected.id;
        _client = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva deuda')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Cliente
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _pickClient,
                  icon: const Icon(Icons.person_search),
                  label: Text(_client == null ? 'Seleccionar cliente' : 'Cliente: ${_client!.name}'),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final s = (v ?? '').replaceAll(',', '.');
                  final val = double.tryParse(s);
                  if (val == null || val <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('Vence: ${DateFormat('yyyy-MM-dd').format(_dueDate)}')),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 0)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                    icon: const Icon(Icons.date_range),
                    label: const Text('Cambiar'),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _clientId == null
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          final nav = Navigator.of(context);
                          final debts = context.read<DebtProvider>();
                          final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
                          final ok = await debts.addDebt(
                            clientId: _clientId!,
                            amount: amount,
                            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
                            dueDate: _dueDate,
                          );
                          if (!mounted) return;
                          if (ok) nav.pop(true);
                        },
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
