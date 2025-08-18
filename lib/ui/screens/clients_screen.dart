import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/client_provider.dart';
import 'client_detail_screen.dart';

class ClientsScreen extends StatefulWidget {
  static const routeName = '/clients';
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ClientProvider>().loadClients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por nombre o teléfono',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    provider.loadClients();
                  },
                ),
              ),
              onChanged: (v) => provider.loadClients(query: v),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: provider.clients.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = provider.clients[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(c.name),
                  subtitle: Text(c.phone),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        _showClientForm(context, provider, existingId: c.id, name: c.name, phone: c.phone, address: c.address ?? '');
                      } else if (v == 'archive') {
                        await provider.archiveClient(c.id);
                      } else if (v == 'delete') {
                        final ok = await provider.deleteClient(c.id);
                        if (!ok && context.mounted) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('No se puede eliminar'),
                              content: const Text('Este cliente tiene deudas activas. Puedes archivarlo para ocultarlo.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
                              ],
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'archive', child: Text('Archivar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                  onTap: () => Navigator.pushNamed(context, ClientDetailScreen.routeName, arguments: c.id),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClientForm(context, provider),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

void _showClientForm(BuildContext context, ClientProvider provider, {int? existingId, String name = '', String phone = '', String address = ''}) {
  final nameCtrl = TextEditingController(text: name);
  final phoneCtrl = TextEditingController(text: phone);
  final addrCtrl = TextEditingController(text: address);
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(existingId == null ? 'Nuevo cliente' : 'Editar cliente', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    final reg = RegExp(r'^[0-9+\-\s]{7,15}$');
                    if (s.isEmpty) return 'Requerido';
                    if (!reg.hasMatch(s)) return 'Teléfono inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección (opcional)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          if (existingId == null) {
                            await provider.addClient(name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim(), address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim());
                          } else {
                            await provider.updateClient(id: existingId, name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim(), address: addrCtrl.text.trim());
                          }
                          if (context.mounted) Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
    },
  );
}
