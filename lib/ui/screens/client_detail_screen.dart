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
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, NewDebtScreen.routeName, arguments: client.id)
                            .then((_) => context.read<DebtProvider>().loadByClient(client.id));
                      },
                      icon: const Icon(Icons.add_card),
                      label: const Text('Agregar deuda'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, RegisterPaymentScreen.routeName, arguments: client.id)
                            .then((_) => context.read<DebtProvider>().loadByClient(client.id));
                      },
                      icon: const Icon(Icons.attach_money),
                      label: const Text('Registrar pago'),
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
                            title: Text('${statusIcon} ${Fmt.money(d.amount)}  (Pendiente: ${Fmt.money(pending)})'),
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
