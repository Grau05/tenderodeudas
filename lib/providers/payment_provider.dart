import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' show Value;
import '../core/db/app_database.dart';

class PaymentProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  List<Payment> _payments = [];
  bool _loading = false;

  List<Payment> get payments => _payments;
  bool get loading => _loading;

  Future<void> loadByDebt(int debtId) async {
    _loading = true;
    notifyListeners();
    try {
      _payments = await _db.getPaymentsByDebt(debtId);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addPayment({
    required int debtId,
    required double amount,
    String? note,
  }) async {
    final id = await _db.insertPayment(PaymentsCompanion.insert(
      debtId: debtId,
      amount: amount,
      note: Value(note),
    ));
    await loadByDebt(debtId);
    return id > 0;
  }

  Future<bool> deletePayment(int id, int debtId) async {
    final res = await _db.deletePayment(id);
    await loadByDebt(debtId);
    return res > 0;
  }
}
