import 'package:flutter/widgets.dart';
import 'package:drift/drift.dart' show Value;
import '../core/db/app_database.dart';

class DebtProvider extends ChangeNotifier {
  final AppDatabase _db;

  DebtProvider(this._db);

  List<Debt> _debts = [];
  final Map<int, double> _pendingByDebt = {};
  bool _loading = false;

  List<Debt> get debts => _debts;
  bool get loading => _loading;
  double pendingFor(int debtId) => _pendingByDebt[debtId] ?? 0.0;

  Future<void> loadByClient(int clientId) async {
    _loading = true;
    // Evita markNeedsBuild durante build cuando se llama desde didChangeDependencies
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
    try {
      _debts = await _db.getDebtsByClient(clientId);
      _pendingByDebt.clear();
      if (_debts.isNotEmpty) {
        final ids = _debts.map((e) => e.id).toList(growable: false);
        final pendings = await _db.pendingAmountsForDebtIds(ids);
        _pendingByDebt.addAll(pendings);
      }
    } finally {
      _loading = false;
      if (hasListeners) notifyListeners();
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
    return id > 0;
  }

  Future<void> refreshDebtPending(int debtId) async {
    _pendingByDebt[debtId] = await _db.pendingAmountForDebt(debtId);
    if (hasListeners) notifyListeners();
  }

  Future<void> markPaidIfZero(int debtId) async {
    final pending = await _db.pendingAmountForDebt(debtId);
    if (pending <= 0.0) {
      await _db.updateDebtStatus(debtId, 'pagada');
    }
  }
}
