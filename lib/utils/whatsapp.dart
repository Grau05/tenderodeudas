import 'package:url_launcher/url_launcher.dart';

class WhatsApp {
  /// Abre WhatsApp al chat del número dado. `phone` debe ser en formato internacional, ej: 57XXXXXXXXXX
  /// `message` es opcional; si se provee, se precarga en el chat.
  static Future<void> open({required String phone, String? message}) async {
    final encodedMsg = Uri.encodeComponent(message ?? '');
    final uri = Uri.parse(
      message == null || message.isEmpty
          ? 'https://wa.me/$phone'
          : 'https://wa.me/$phone?text=$encodedMsg',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo abrir WhatsApp para $phone';
    }
  }
}
