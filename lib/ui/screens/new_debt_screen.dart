import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/debt_provider.dart';

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

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientId = ModalRoute.of(context)!.settings.arguments as int?;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva deuda')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                  onPressed: clientId == null
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          final nav = Navigator.of(context);
                          final debts = context.read<DebtProvider>();
                          final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
                          final ok = await debts.addDebt(
                            clientId: clientId,
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
