import 'package:url_launcher/url_launcher.dart';
import '../utils/format.dart';

class WhatsAppService {
  static Future<void> sendRaw({
    required String phone,
    required String message,
  }) async {
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  static Future<void> sendReminder({
    required String phone,
    required String clientName,
    required double pendingAmount,
    required DateTime dueDate,
    required String template,
  }) async {
    final dateStr = Fmt.date(dueDate);
    final amountStr = Fmt.money(pendingAmount);
    final effectiveTemplate = (template.isEmpty)
        ? 'Hola [NombreCliente], tienes un saldo pendiente de [MontoPendiente] con fecha [Fecha]. Por favor contáctame para coordinar el pago. Gracias.'
        : template;
    String message = effectiveTemplate
        .replaceAll('[NombreCliente]', clientName)
        .replaceAll('[MontoPendiente]', amountStr)
        .replaceAll('[Fecha]', dateStr);
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
