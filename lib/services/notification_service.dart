import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const init = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(init);
  }

  static Future<void> scheduleDueReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'due_reminders',
        'Recordatorios de deudas',
        channelDescription: 'Avisos de vencimiento de deudas',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    // NOTE: Using immediate show for now to avoid timezone/scheduling setup.
    // TODO: Switch to zonedSchedule/schedule after adding proper permissions and tz config.
    await _plugin.show(id, title, body, details, payload: 'due');
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);
}
