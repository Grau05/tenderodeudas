import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:sqflite/sqflite.dart';
import '../core/db/app_database.dart';

// Importar getTemporaryDirectory desde path_provider
import 'package:path_provider/path_provider.dart' as path_provider;

// Callback para el trabajo en segundo plano
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'auto_backup_task') {
      await BackupService.createBackup();
      await BackupService.cleanOldBackups();
      return true;
    }
    return false;
  });
}

class BackupService {
  static const String _backupKey = 'last_backup';
  static const String _autoBackupKey = 'auto_backup_enabled';
  static const String _backupFrequencyKey = 'backup_frequency';
  
  // Frecuencias de respaldo
  static const Map<String, Duration> backupFrequencies = {
    'Diario': Duration(hours: 24),
    'Semanal': Duration(days: 7),
    'Mensual': Duration(days: 30),
  };

  // Obtener directorio de la base de datos
  static Future<String> getDatabasePath() async {
    final dbFolder = await getDatabasesPath();
    return p.join(dbFolder, 'me_debe.sqlite');
  }

  // Obtener archivo de base de datos principal
  static Future<File> get databaseFile async {
    final dbPath = await getDatabasePath();
    return File(dbPath);
  }

  // Obtener archivo WAL (Write-Ahead Log)
  static Future<File> get databaseWalFile async {
    final dbPath = await getDatabasePath();
    return File('$dbPath-wal');
  }

  // Obtener archivo SHM (Shared Memory)
  static Future<File> get databaseShmFile async {
    final dbPath = await getDatabasePath();
    return File('$dbPath-shm');
  }

  // Obtener archivo de respaldo (para compatibilidad)
  static Future<File> getBackupFile([String? name]) async {
    final backupDir = await _ensureBackupDirectory();
    final fileName = name ?? 'backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.sqlite';
    return File(p.join(backupDir.path, fileName));
  }

  // Asegurar que exista el directorio de respaldos
  static Future<Directory> _ensureBackupDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  // Listar todos los respaldos disponibles
  static Future<List<File>> listBackups() async {
    try {
      final backupDir = await _ensureBackupDirectory();
      final files = await backupDir.list()
          .where((entity) => entity is File && entity.path.endsWith('.sqlite'))
          .map((entity) => entity as File)
          .toList();
      
      // Ordenar por fecha de modificación (más reciente primero)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (e) {
      print('Error listando respaldos: $e');
      rethrow;
    }
  }

  // Crear un nuevo respaldo
  static Future<File> createBackup() async {
    if (!await _checkStoragePermission()) {
      throw Exception('No se tienen los permisos necesarios para acceder al almacenamiento');
    }

    try {
      // Cerrar la conexión a la base de datos si está abierta
      final db = AppDatabase();
      await db.close();
      
      // Obtener los archivos de la base de datos
      final dbFile = await databaseFile;
      final walFile = await databaseWalFile;
      final shmFile = await databaseShmFile;
      
      if (!await dbFile.exists()) {
        throw Exception('No se encontró el archivo de la base de datos en ${dbFile.path}');
      }

      // Crear el archivo de respaldo
      final backupFile = await getBackupFile();
      final backupWalFile = File('${backupFile.path}-wal');
      final backupShmFile = File('${backupFile.path}-shm');
      
      // Copiar los archivos de la base de datos
      await dbFile.copy(backupFile.path);
      
      // Copiar archivos WAL y SHM si existen
      if (await walFile.exists()) {
        await walFile.copy(backupWalFile.path);
      }
      
      if (await shmFile.exists()) {
        await shmFile.copy(backupShmFile.path);
      }
      
      // Actualizar la fecha del último respaldo
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backupKey, DateTime.now().toIso8601String());
      
      // Limpiar respaldos antiguos
      await cleanOldBackups();
      
      // Cerrar la base de datos para asegurar que todos los cambios se guarden
      await db.close();
      // La base de datos se volverá a abrir cuando se necesite
      
      return backupFile;
    } catch (e) {
      debugPrint('Error creando respaldo: $e');
      rethrow;
    } finally {
      // No es necesario abrir la base de datos explícitamente,
      // ya que se abrirá automáticamente cuando se necesite
      try {
        final db = AppDatabase();
        await db.close();
      } catch (e) {
        debugPrint('Error al cerrar la base de datos: $e');
      }
    }
  }

  // Restaurar desde un respaldo
  static Future<void> restoreBackup(File backupFile) async {
    if (!await backupFile.exists()) {
      throw Exception('El archivo de respaldo no existe');
    }

    // Cerrar la conexión a la base de datos actual
    final db = AppDatabase();
    await db.close();
    
    try {
      final dbFile = await databaseFile;
      final walFile = await databaseWalFile;
      final shmFile = await databaseShmFile;
      
      // Hacer una copia de seguridad de la base de datos actual
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupDir = await _ensureBackupDirectory();
      
      final restoreBackupFile = File(p.join(backupDir.path, 'before_restore_$timestamp.sqlite'));
      
      // Hacer copia de seguridad de los archivos actuales
      if (await dbFile.exists()) {
        await dbFile.copy(restoreBackupFile.path);
        final restoreWalFile = File('${restoreBackupFile.path}-wal');
        final restoreShmFile = File('${restoreBackupFile.path}-shm');
        
        if (await walFile.exists()) await walFile.copy(restoreWalFile.path);
        if (await shmFile.exists()) await shmFile.copy(restoreShmFile.path);
      }
      
      // Eliminar archivos de base de datos existentes
      if (await dbFile.exists()) await dbFile.delete();
      if (await walFile.exists()) await walFile.delete();
      if (await shmFile.exists()) await shmFile.delete();
      
      // Copiar archivos del respaldo
      await backupFile.copy(dbFile.path);
      
      // Copiar archivos WAL y SHM si existen
      final backupWalFile = File('${backupFile.path}-wal');
      final backupShmFile = File('${backupFile.path}-shm');
      
      if (await backupWalFile.exists()) {
        await backupWalFile.copy(walFile.path);
      }
      
      if (await backupShmFile.exists()) {
        await backupShmFile.copy(shmFile.path);
      }
      
      // Actualizar la fecha del último respaldo
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backupKey, DateTime.now().toIso8601String());
      
      // Cerrar la base de datos para asegurar que todos los cambios se guarden
      await db.close();
      // La base de datos se volverá a abrir cuando se necesite
      
    } catch (e) {
      debugPrint('Error restaurando respaldo: $e');
      rethrow;
    } finally {
      // No es necesario abrir la base de datos explícitamente,
      // ya que se abrirá automáticamente cuando se necesite
      try {
        await db.close();
      } catch (e) {
        debugPrint('Error al cerrar la base de datos: $e');
      }
    }
  }

  // Limpiar respaldos antiguos
  static Future<void> cleanOldBackups({int keepLast = 5}) async {
    try {
      final backups = await listBackups();
      if (backups.length <= keepLast) return;
      
      // Mantener solo los 'keepLast' más recientes
      final toDelete = backups.sublist(keepLast);
      for (final file in toDelete) {
        try {
          await file.delete();
        } catch (e) {
          print('Error eliminando respaldo antiguo ${file.path}: $e');
        }
      }
    } catch (e) {
      print('Error limpiando respaldos antiguos: $e');
      // No relanzar el error, ya que esto no es crítico
    }
  }

  // Configurar respaldo automático
  static Future<void> configureAutoBackup(bool enabled, {String frequency = 'Diario'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
    await prefs.setString(_backupFrequencyKey, frequency);
    
    if (enabled) {
      // Configurar el trabajo programado
      await Workmanager().registerPeriodicTask(
        'auto_backup',
        'auto_backup_task',
        frequency: backupFrequencies[frequency] ?? const Duration(days: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
          requiresStorageNotLow: true,
        ),
      );
    } else {
      // Cancelar el trabajo programado
      await Workmanager().cancelByTag('auto_backup');
    }
  }

  // Verificar si el respaldo automático está activado
  static Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupKey) ?? false;
  }

  // Obtener la frecuencia de respaldo configurada
  static Future<String> getBackupFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backupFrequencyKey) ?? 'Diario';
  }

  // Obtener la fecha del último respaldo
  static Future<DateTime?> getLastBackupDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = prefs.getString(_backupKey);
      if (dateStr == null) return null;
      
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        debugPrint('Error parsing backup date: $e');
        // Si hay un error al parsear la fecha, eliminamos el valor inválido
        await prefs.remove(_backupKey);
        return null;
      }
    } catch (e) {
      debugPrint('Error getting last backup date: $e');
      return null;
    }
  }

  // Verificar permisos de almacenamiento
  static Future<bool> _checkStoragePermission() async {
    try {
      // En Android 10+ (API 29+) no se necesitan permisos de almacenamiento para archivos propios
      // Solo verificamos que podamos acceder al directorio de la aplicación
      final tempDir = await path_provider.getTemporaryDirectory();
      final testFile = File('${tempDir.path}/.test_permission');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      debugPrint('Error verificando permisos de almacenamiento: $e');
      return false;
    }
  }

  // Inicializar el servicio de respaldos
  static Future<void> initialize() async {
    try {
      // Verificar permisos
      if (!await _checkStoragePermission()) {
        debugPrint('Advertencia: No se tienen los permisos necesarios para los respaldos');
      }
      
      // Inicializar workmanager
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      
      // Configurar respaldo automático si está habilitado
      if (await isAutoBackupEnabled()) {
        final frequency = await getBackupFrequency();
        await configureAutoBackup(true, frequency: frequency);
      }
    } catch (e) {
      debugPrint('Error al inicializar el servicio de respaldos: $e');
      // No relanzamos el error para no bloquear la aplicación
    }
  }
}
