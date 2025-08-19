import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';

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
            title: const Text('Último respaldo'),
            subtitle: Text(s.lastBackup?.toLocal().toString() ?? 'Sin respaldo'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final file = await BackupService.createBackup();
                      await s.setLastBackup(DateTime.now());
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Respaldo creado: ${file.path}')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al respaldar: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.backup),
                  label: const Text('Crear respaldo'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final backup = await BackupService.backupFile;
                      if (!await backup.exists()) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No existe archivo de respaldo')),
                        );
                        return;
                      }
                      await BackupService.restoreBackup(backup);
                      await s.setLastBackup(DateTime.now());
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Restauración completada. Reinicia la app para ver cambios.')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al restaurar: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Restaurar respaldo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
