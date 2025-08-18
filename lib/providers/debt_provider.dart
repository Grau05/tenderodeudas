import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' show Value;
import '../core/db/app_database.dart';
import '../services/notification_service.dart';

class DebtProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  List<Debt> _debts = [];
  final Map<int, double> _pendingByDebt = {};
  bool _loading = false;

  List<Debt> get debts => _debts;
  bool get loading => _loading;
  double pendingFor(int debtId) => _pendingByDebt[debtId] ?? 0.0;

  Future<void> loadByClient(int clientId) async {
    _loading = true;
    notifyListeners();
    try {
      _debts = await _db.getDebtsByClient(clientId);
      _pendingByDebt.clear();
      for (final d in _debts) {
        _pendingByDebt[d.id] = await _db.pendingAmountForDebt(d.id);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addDebt({
    required int clientId,
    required double amount,
    String? description,
    required DateTime dueDate,
  }) async {
    final id = await _db.insertDebt(DebtsCompanion.insert(
      clientId: clientId,
      amount: amount,
      description: Value(description),
      dueDate: dueDate,
    ));
    // Programar (placeholder: mostrar ahora). Luego cambiar a programación real.
    await NotificationService.scheduleDueReminder(
      id: id,
      title: 'Vence deuda',
      body: 'Deuda de $amount para cliente #$clientId',
      scheduledAt: dueDate,
    );
    return id > 0;
  }

  Future<void> refreshDebtPending(int debtId) async {
    _pendingByDebt[debtId] = await _db.pendingAmountForDebt(debtId);
    notifyListeners();
  }

  Future<void> markPaidIfZero(int debtId) async {
    final pending = await _db.pendingAmountForDebt(debtId);
    if (pending <= 0.0) {
      await _db.updateDebtStatus(debtId, 'pagada');
    }
  }
}
