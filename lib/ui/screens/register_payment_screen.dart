import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/payment_provider.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final clientId = ModalRoute.of(context)!.settings.arguments as int?;
    if (clientId != null) {
      context.read<DebtProvider>().loadByClient(clientId);
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
    final clientId = ModalRoute.of(context)!.settings.arguments as int?;
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
                    DropdownButtonFormField<int>(
                      value: _selectedDebtId,
                      decoration: const InputDecoration(labelText: 'Deuda'),
                      items: debts
                          .map((d) => DropdownMenuItem(
                                value: d.id,
                                child: Text(
                                    'Deuda ${d.id} • Pendiente: ${Fmt.money(debtsProv.pendingFor(d.id))} • Vence: ${Fmt.date(d.dueDate)}'),
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
                        onPressed: (clientId == null)
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                final debtId = _selectedDebtId!;
                                final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
                                final ok = await context.read<PaymentProvider>().addPayment(
                                      debtId: debtId,
                                      amount: amount,
                                      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                                    );
                                await context.read<DebtProvider>().refreshDebtPending(debtId);
                                await context.read<DebtProvider>().markPaidIfZero(debtId);
                                if (!mounted) return;
                                if (ok) Navigator.pop(context, true);
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
