import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/client_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/whatsapp_service.dart';
import '../../utils/format.dart';
import 'new_debt_screen.dart';
import 'register_payment_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  static const routeName = '/client-detail';
  const ClientDetailScreen({super.key});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  int? clientId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    clientId = ModalRoute.of(context)!.settings.arguments as int?;
    if (clientId != null) {
      context.read<DebtProvider>().loadByClient(clientId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (clientId == null) {
      return const Scaffold(body: Center(child: Text('Cliente no especificado')));
    }
    return FutureBuilder(
      future: context.read<ClientProvider>().getById(clientId!),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final client = snap.data!;
        final debts = context.watch<DebtProvider>();
        return Scaffold(
          appBar: AppBar(title: Text(client.name)),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(client.name, style: Theme.of(context).textTheme.titleLarge),
                          Text(client.phone),
                          if (client.address != null && client.address!.isNotEmpty) Text(client.address!),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.call),
                      onPressed: () async {
                        final uri = Uri.parse('tel:${client.phone}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat),
                      onPressed: () async {
                        final template = context.read<SettingsProvider>().whatsappTemplate;
                        final pendingTotal = await context.read<ClientProvider>().totalPendienteCliente(client.id);
                        await WhatsAppService.sendReminder(
                          phone: client.phone,
                          clientName: client.name,
                          pendingAmount: pendingTotal,
                          dueDate: DateTime.now(),
                          template: template,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final dp = context.read<DebtProvider>();
                        Navigator.pushNamed(context, NewDebtScreen.routeName, arguments: client.id)
                            .then((_) {
                          if (!mounted) return;
                          dp.loadByClient(client.id);
                        });
                      },
                      icon: const Icon(Icons.add_card),
                      label: const Text('Agregar deuda'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        final dp = context.read<DebtProvider>();
                        Navigator.pushNamed(context, RegisterPaymentScreen.routeName, arguments: client.id)
                            .then((_) {
                          if (!mounted) return;
                          dp.loadByClient(client.id);
                        });
                      },
                      icon: const Icon(Icons.attach_money),
                      label: const Text('Registrar pago'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Preparar mensaje y permitir previsualización/edición
                        final template = context.read<SettingsProvider>().whatsappTemplate;
                        final clientProv = context.read<ClientProvider>();
                        final debtsProv = context.read<DebtProvider>();
                        final pendingTotal = await clientProv.totalPendienteCliente(client.id);
                        DateTime dueDate = DateTime.now();
                        final withPending = debtsProv.debts
                            .where((d) => debtsProv.pendingFor(d.id) > 0)
                            .toList();
                        if (withPending.isNotEmpty) {
                          withPending.sort((a, b) => a.dueDate.compareTo(b.dueDate));
                          dueDate = withPending.first.dueDate;
                        }
                        // Construir mensaje usando el servicio para respetar formato local
                        final dateStr = Fmt.date(dueDate);
                        final amountStr = Fmt.money(pendingTotal);
                        final effectiveTemplate = (template.isEmpty)
                            ? 'Hola [NombreCliente], tienes un saldo pendiente de [MontoPendiente] con fecha [Fecha]. Por favor contáctame para coordinar el pago. Gracias.'
                            : template;
                        final initialMessage = effectiveTemplate
                            .replaceAll('[NombreCliente]', client.name)
                            .replaceAll('[MontoPendiente]', amountStr)
                            .replaceAll('[Fecha]', dateStr);

                        final controller = TextEditingController(text: initialMessage);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) {
                            return AlertDialog(
                              title: const Text('Previsualizar mensaje'),
                              content: TextField(
                                controller: controller,
                                maxLines: 6,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Enviar'),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirmed == true) {
                          await WhatsAppService.sendRaw(
                            phone: client.phone,
                            message: controller.text,
                          );
                        }
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Enviar recordatorio'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: debts.loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: debts.debts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final d = debts.debts[i];
                          final pending = debts.pendingFor(d.id);
                          final isOverdue = d.dueDate.isBefore(DateTime.now()) && pending > 0;
                          final color = pending <= 0
                              ? Colors.green
                              : (isOverdue ? Colors.red : Colors.amber);
                          final statusIcon = pending <= 0
                              ? '🟢'
                              : (isOverdue ? '🔴' : '🟡');
                          return ListTile(
                            title: Text('$statusIcon ${Fmt.money(d.amount)}  (Pendiente: ${Fmt.money(pending)})'),
                            subtitle: Text('Vence: ${Fmt.date(d.dueDate)}  • ${d.description ?? ''}'),
                            trailing: Icon(Icons.circle, color: color, size: 12),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
