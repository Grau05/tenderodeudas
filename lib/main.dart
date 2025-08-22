import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/backup_service.dart';
import 'app.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize backup service
  try {
    await BackupService.initialize();
  } catch (e) {
    debugPrint('Error initializing backup service: $e');
    // Continue with app initialization even if backup service fails
  }

  runApp(const MyApp());
}