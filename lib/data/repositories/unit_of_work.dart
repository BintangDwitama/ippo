/// Runs several repository writes as one all-or-nothing operation.
abstract interface class UnitOfWork {
  /// Runs [action]; if it throws, every write made inside it is undone.
  Future<T> run<T>(Future<T> Function() action);
}
