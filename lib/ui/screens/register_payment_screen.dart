import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/client_provider.dart';
import '../../core/db/app_database.dart';
import '../../utils/format.dart';

class RegisterPaymentScreen extends StatefulWidget {
  static const routeName = '/register-payment';
  const RegisterPaymentScreen({super.key});

  @override
  State<RegisterPaymentScreen> createState() => _RegisterPaymentScreenState();
}

class _RegisterPaymentScreenState extends State<RegisterPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int? _selectedDebtId;
  bool _inited = false;
  int? _clientId;
  Client? _client;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    _clientId = ModalRoute.of(context)!.settings.arguments as int?;
    if (_clientId != null) {
      context.read<DebtProvider>().loadByClient(_clientId!);
      context.read<ClientProvider>().getById(_clientId!).then((c) {
        if (mounted) setState(() => _client = c);
      });
    }
  }

  Future<void> _pickClient() async {
    final outerCtx = context;
    final prov = outerCtx.read<ClientProvider>();
    final debtsProv = outerCtx.read<DebtProvider>();
    // Disparar carga sin esperar; el diálogo observará `loading`.
    prov.loadClients();
    if (!mounted) return;
    // ignore: use_build_context_synchronously
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
        _selectedDebtId = null;
      });
      await debtsProv.loadByClient(_clientId!);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debtsProv = context.watch<DebtProvider>();
    final debts = debtsProv.debts
        .where((d) => debtsProv.pendingFor(d.id) > 0)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar pago')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: debtsProv.loading && debts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Form(
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
                    DropdownButtonFormField<int>(
                      initialValue: _selectedDebtId,
                      decoration: const InputDecoration(labelText: 'Deuda'),
                      isExpanded: true,
                      items: debts
                          .map((d) => DropdownMenuItem(
                                value: d.id,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    'Deuda ${d.id} • Pendiente: ${Fmt.money(debtsProv.pendingFor(d.id))} • Vence: ${Fmt.date(d.dueDate)}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedDebtId = v),
                      validator: (v) => v == null ? 'Seleccione una deuda' : null,
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
                        if (_selectedDebtId != null) {
                          final max = debtsProv.pendingFor(_selectedDebtId!);
                          if (val > max) return 'No puede exceder el pendiente (${Fmt.money(max)})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(labelText: 'Nota (opcional)'),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_clientId == null || _selectedDebtId == null)
                            ? null
                            : () async {
                              if (!_formKey.currentState!.validate()) return;
                              final nav = Navigator.of(context);
                              final payments = context.read<PaymentProvider>();
                              final debtsReader = context.read<DebtProvider>();
                              final debtId = _selectedDebtId!;
                              final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
                              final ok = await payments.addPayment(
                                debtId: debtId,
                                amount: amount,
                                note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                              );
                              await debtsReader.refreshDebtPending(debtId);
                              await debtsReader.markPaidIfZero(debtId);
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
