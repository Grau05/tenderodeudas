import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'backup_screen.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storeCtrl = TextEditingController();
  final _tplCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();
    _storeCtrl.text = s.storeName;
    _tplCtrl.text = s.whatsappTemplate;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _storeCtrl,
            decoration: const InputDecoration(labelText: 'Nombre de la tienda'),
            onChanged: (v) => s.updateStoreName(v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tplCtrl,
            decoration: const InputDecoration(labelText: 'Mensaje predeterminado de WhatsApp'),
            maxLines: 4,
            onChanged: (v) => s.updateTemplate(v),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Respaldos y restauración'),
            subtitle: const Text('Gestiona tus respaldos y restauraciones'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, BackupScreen.routeName);
            },
          ),
        ],
      ),
    );
  }
}
