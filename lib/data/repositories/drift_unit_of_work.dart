import 'package:ippo/data/repositories/unit_of_work.dart';
import 'package:ippo/data/services/app_database.dart';

/// [UnitOfWork] using a database transaction. Repository calls made
/// inside [run] join the transaction automatically.
class DriftUnitOfWork implements UnitOfWork {
  DriftUnitOfWork(this._db);

  final AppDatabase _db;

  @override
  Future<T> run<T>(Future<T> Function() action) => _db.transaction(action);
}
