import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  String _storeName = 'Mi Tienda';
  String _whatsTemplate = r'Hola [NombreCliente], tienes una deuda pendiente de $[MontoPendiente]. Fecha límite: [Fecha]. Por favor realizar el pago lo más pronto posible.';
  DateTime? _lastBackup;

  String get storeName => _storeName;
  String get whatsappTemplate => _whatsTemplate;
  DateTime? get lastBackup => _lastBackup;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _storeName = prefs.getString('storeName') ?? _storeName;
    _whatsTemplate = prefs.getString('whatsTemplate') ?? _whatsTemplate;
    final millis = prefs.getInt('lastBackup');
    if (millis != null) _lastBackup = DateTime.fromMillisecondsSinceEpoch(millis);
    notifyListeners();
  }

  Future<void> updateStoreName(String name) async {
    _storeName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storeName', name);
    notifyListeners();
  }

  Future<void> updateTemplate(String value) async {
    _whatsTemplate = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('whatsTemplate', value);
    notifyListeners();
  }

  Future<void> setLastBackup(DateTime time) async {
    _lastBackup = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastBackup', time.millisecondsSinceEpoch);
    notifyListeners();
  }
}
