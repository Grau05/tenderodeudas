import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';

part 'app_database.g.dart';

class Clients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get address => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get clientId => integer().references(Clients, #id)();
  RealColumn get amount => real()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pendiente'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debtId => integer().references(Debts, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get note => text().nullable()();
}

@DriftDatabase(tables: [Clients, Debts, Payments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ========= Clients =========
  Future<int> insertClient(ClientsCompanion entry) => into(clients).insert(entry);
  Future<List<Client>> getAllClients() => (select(clients)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  Future<Client?> getClientById(int id) => (select(clients)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<List<Client>> searchClients(String query) async {
    final q = '%${query.toLowerCase()}%';
    return (select(clients)
          ..where((t) => t.name.lower().like(q) | t.phone.lower().like(q))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }
  Future<int> updateClientEntry(ClientsCompanion entry) => update(clients).write(entry);
  Future<int> archiveClient(int id) => (update(clients)..where((t) => t.id.equals(id))).write(const ClientsCompanion(active: Value(false)));
  Future<int> deleteClientById(int id) => (delete(clients)..where((t) => t.id.equals(id))).go();

  // ========= Debts =========
  Future<int> insertDebt(DebtsCompanion entry) => into(debts).insert(entry);
  Future<List<Debt>> getDebtsByClient(int clientId) =>
      (select(debts)..where((t) => t.clientId.equals(clientId))..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  Future<int> updateDebtStatus(int debtId, String status) =>
      (update(debts)..where((t) => t.id.equals(debtId))).write(DebtsCompanion(status: Value(status)));
  Future<Debt?> getDebtById(int id) => (select(debts)..where((t) => t.id.equals(id))).getSingleOrNull();

  // ========= Payments =========
  Future<int> insertPayment(PaymentsCompanion entry) => into(payments).insert(entry);
  Future<List<Payment>> getPaymentsByDebt(int debtId) =>
      (select(payments)..where((t) => t.debtId.equals(debtId))..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
  Future<int> deletePayment(int id) => (delete(payments)..where((t) => t.id.equals(id))).go();

  // ========= Aggregations =========
  Future<double> sumPaymentsForDebt(int debtId) async {
    final expr = payments.amount.sum();
    final q = await (selectOnly(payments)..addColumns([expr])..where(payments.debtId.equals(debtId))).getSingle();
    final v = q.read(expr) ?? 0.0;
    return v;
  }

  Future<double> pendingAmountForDebt(int debtId) async {
    final d = await getDebtById(debtId);
    if (d == null) return 0;
    final paid = await sumPaymentsForDebt(debtId);
    return (d.amount - paid).clamp(0, double.infinity);
  }

  Future<double> totalPending() async {
    final all = await select(debts).get();
    double total = 0;
    for (final d in all) {
      final pending = await pendingAmountForDebt(d.id);
      if (pending > 0) total += pending;
    }
    return total;
  }

  Future<double> totalPaid() async {
    final expr = payments.amount.sum();
    final q = await (selectOnly(payments)..addColumns([expr])).getSingle();
    return q.read(expr) ?? 0.0;
  }

  Future<double> totalOverdue() async {
    final now = DateTime.now();
    final overdue = await (select(debts)..where((t) => t.dueDate.isSmallerThanValue(now))).get();
    double total = 0;
    for (final d in overdue) {
      final pending = await pendingAmountForDebt(d.id);
      if (pending > 0) total += pending;
    }
    return total;
  }

  Future<bool> hasPendingDebtsForClient(int clientId) async {
    final list = await getDebtsByClient(clientId);
    for (final d in list) {
      final pending = await pendingAmountForDebt(d.id);
      if (pending > 0) return true;
    }
    return false;
  }

  Future<double> clientTotalPending(int clientId) async {
    final list = await getDebtsByClient(clientId);
    double total = 0;
    for (final d in list) {
      final pending = await pendingAmountForDebt(d.id);
      total += pending;
    }
    return total;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return SqfliteQueryExecutor.inDatabaseFolder(
      path: 'me_debe.sqlite',
      logStatements: false,
      singleInstance: true,
    );
  });
}
