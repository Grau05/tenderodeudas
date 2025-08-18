import 'package:flutter/foundation.dart';
import '../core/db/app_database.dart';

class ClientProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  List<Client> _clients = [];
  List<Client> get clients => _clients;

  Future<void> loadClients({String? query}) async {
    if (query == null || query.isEmpty) {
      _clients = await _db.getAllClients();
    } else {
      final all = await _db.getAllClients();
      _clients = all
          .where((c) => c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.phone.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }
}
