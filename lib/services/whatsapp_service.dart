import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class WhatsAppService {
  static Future<void> sendReminder({
    required String phone,
    required String clientName,
    required double pendingAmount,
    required DateTime dueDate,
    required String template,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(dueDate);
    String message = template
        .replaceAll('[NombreCliente]', clientName)
        .replaceAll('[MontoPendiente]', pendingAmount.toStringAsFixed(2))
        .replaceAll('[Fecha]', dateStr);
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
