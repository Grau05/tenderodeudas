import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupService {
  static Future<File> get databaseFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'me_debe.sqlite'));
    
  }

  static Future<File> createBackup() async {
    final db = await databaseFile;
    final docs = await getApplicationDocumentsDirectory();
    final backup = File(p.join(docs.path, 'backup_me_debe.sqlite'));
    return db.copy(backup.path);
  }

  static Future<void> restoreBackup(File backupFile) async {
    final db = await databaseFile;
    if (await backupFile.exists()) {
      await backupFile.copy(db.path);
    }
  }
}
