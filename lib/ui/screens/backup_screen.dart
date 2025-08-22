import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

import '../../services/backup_service.dart';
import '../../utils/format.dart';

class BackupScreen extends StatefulWidget {
  static const routeName = '/backup';
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;
  List<File> _backups = [];
  bool _autoBackup = false;
  String _backupFrequency = 'Diario';
  final List<String> _frequencies = ['Diario', 'Semanal', 'Mensual'];

  DateTime? _lastBackupDate;
  bool _hasError = false;
  String? _errorMessage;

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _initializeBackupScreen();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeBackupScreen() async {
    try {
      await Future.wait([
        _loadBackups(),
        _loadAutoBackupSettings(),
        _loadLastBackupDate(),
      ]);
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Error al cargar la información de respaldo: $e';
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadLastBackupDate() async {
    try {
      _lastBackupDate = await BackupService.getLastBackupDate();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error al cargar la fecha del último respaldo: $e');
      // No actualizamos el estado para no mostrar un error por esto
    }
  }

  Future<void> _loadAutoBackupSettings() async {
    _autoBackup = await BackupService.isAutoBackupEnabled();
    _backupFrequency = await BackupService.getBackupFrequency();
    if (mounted) setState(() {});
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    try {
      _backups = await BackupService.listBackups();
    } catch (e) {
      _showError('Error al cargar respaldos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });
    
    try {
      await BackupService.createBackup();
      await Future.wait([
        _loadBackups(),
        _loadLastBackupDate(),
      ]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Respaldo creado exitosamente'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      final errorMsg = 'Error al crear respaldo: ${e.toString().replaceAll('Exception: ', '')}';
      _hasError = true;
      _errorMessage = errorMsg;
      _showError(errorMsg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _shareBackup(File backup) async {
    try {
      await Share.shareXFiles([XFile(backup.path)],
          text: 'Respaldo de Mi Tienda - ${p.basename(backup.path)}');
    } catch (e) {
      _showError('Error al compartir respaldo: $e');
    }
  }

  Future<void> _deleteBackup(File backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar respaldo'),
        content: const Text('¿Estás seguro de eliminar este respaldo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await backup.delete();
        await _loadBackups();
      } catch (e) {
        _showError('Error al eliminar respaldo: $e');
      }
    }
  }

  Future<void> _restoreBackup(File backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar respaldo'),
        content: const Text(
            '¿Estás seguro de restaurar este respaldo? Se creará un respaldo de la base de datos actual antes de restaurar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restaurar', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await BackupService.restoreBackup(backup);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Respaldo restaurado. La aplicación se reiniciará.')),
          );
          // Aquí podrías reiniciar la app o forzar un hot restart
        }
      } catch (e) {
        _showError('Error al restaurar respaldo: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAutoBackup(bool? value) async {
    if (value == null) return;
    
    setState(() => _isLoading = true);
    try {
      await BackupService.configureAutoBackup(value, frequency: _backupFrequency);
      setState(() => _autoBackup = value);
    } catch (e) {
      _showError('Error al configurar respaldo automático: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBackupFrequency(String? value) async {
    if (value == null) return;
    
    setState(() => _isLoading = true);
    try {
      await BackupService.configureAutoBackup(_autoBackup, frequency: value);
      setState(() => _backupFrequency = value);
    } catch (e) {
      _showError('Error al actualizar frecuencia: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Respaldo'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading && _backups.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBackups,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sección de respaldo manual
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Respaldo Manual',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Crea un respaldo manual de toda la información de la aplicación.',
                              style: TextStyle(color: Colors.grey),
                            ),
                            if (_lastBackupDate != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Último respaldo: ${_formatDate(_lastBackupDate!)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (_hasError && _errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _createBackup,
                                icon: _isLoading 
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.backup),
                                label: Text(_isLoading ? 'Creando respaldo...' : 'Crear Respaldo'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sección de respaldo automático
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Respaldo Automático',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              title: const Text('Activar respaldo automático'),
                              value: _autoBackup,
                              onChanged: _toggleAutoBackup,
                            ),
                            if (_autoBackup) ...[
                              const SizedBox(height: 8),
                              const Text('Frecuencia de respaldo:'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _backupFrequency,
                                items: _frequencies
                                    .map((f) => DropdownMenuItem(
                                          value: f,
                                          child: Text(f),
                                        ))
                                    .toList(),
                                onChanged: _updateBackupFrequency,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                isExpanded: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Lista de respaldos existentes
                    const Text(
                      'Respaldos Existentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_backups.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No hay respaldos disponibles'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _backups.length,
                        itemBuilder: (ctx, index) {
                          final backup = _backups[index];
                          final fileSize = (backup.lengthSync() / 1024 / 1024)
                              .toStringAsFixed(2);
                          final modified = backup.lastModifiedSync();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                'Respaldo ${index + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Tamaño: $fileSize MB • ${Fmt.date(modified)}'),
                                  Text(
                                    DateFormat('HH:mm').format(modified),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'restore',
                                    child: Row(
                                      children: [
                                        Icon(Icons.restore, size: 20),
                                        SizedBox(width: 8),
                                        Text('Restaurar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'share',
                                    child: Row(
                                      children: [
                                        Icon(Icons.share, size: 20),
                                        SizedBox(width: 8),
                                        Text('Compartir'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'restore':
                                      await _restoreBackup(backup);
                                      break;
                                    case 'share':
                                      await _shareBackup(backup);
                                      break;
                                    case 'delete':
                                      await _deleteBackup(backup);
                                      break;
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
