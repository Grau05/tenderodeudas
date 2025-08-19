import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupService {
  static Future<File> get databaseFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'me_debe.sqlite'));
    
  }

  static Future<File> get backupFile async {
    final docs = await getApplicationDocumentsDirectory();
    return File(p.join(docs.path, 'backup_me_debe.sqlite'));
  }

  static Future<File> createBackup() async {
    final db = await databaseFile;
    final backup = await backupFile;
    return db.copy(backup.path);
  }

  static Future<void> restoreBackup(File backupFile) async {
    final db = await databaseFile;
    if (await backupFile.exists()) {
      await backupFile.copy(db.path);
    }
  }
}
