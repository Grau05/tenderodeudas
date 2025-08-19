import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' show Value;
import '../core/db/app_database.dart';

class ClientProvider extends ChangeNotifier {
  final AppDatabase _db;

  ClientProvider(this._db);

  List<Client> _clients = [];
  bool _loading = false;

  List<Client> get clients => _clients;
  bool get loading => _loading;

  Future<void> loadClients({String? query}) async {
    _loading = true;
    notifyListeners();
    try {
      if (query == null || query.isEmpty) {
        _clients = await _db.getAllClients();
      } else {
        _clients = await _db.searchClients(query);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Client?> getById(int id) => _db.getClientById(id);

  Future<bool> addClient({required String name, required String phone, String? address}) async {
    final id = await _db.insertClient(ClientsCompanion.insert(
      name: name,
      phone: phone,
      address: Value(address),
    ));
    await loadClients();
    return id > 0;
  }

  Future<bool> updateClient({required int id, required String name, required String phone, String? address, bool? active}) async {
    final updated = await _db.updateClientEntry(ClientsCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      address: Value(address),
      active: active == null ? const Value.absent() : Value(active),
    ));
    await loadClients();
    return updated > 0;
  }

  Future<bool> deleteClient(int id) async {
    // Regla: si tiene deudas pendientes, NO eliminar. Ofrecer archivar.
    final hasPending = await _db.hasPendingDebtsForClient(id);
    if (hasPending) return false;
    final res = await _db.deleteClientById(id);
    await loadClients();
    return res > 0;
  }

  Future<void> archiveClient(int id) async {
    await _db.archiveClient(id);
    await loadClients();
  }

  Future<double> totalPendienteCliente(int clientId) {
    return _db.clientTotalPending(clientId);
  }
}
