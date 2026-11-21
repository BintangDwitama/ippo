import 'package:ippo/domain/models/backup_snapshot.dart';

/// A snapshot names an item this install does not have.
class UnknownItemKeyException implements Exception {
  const UnknownItemKeyException(this.key);

  final String key;

  @override
  String toString() => 'UnknownItemKeyException($key)';
}

/// Reads and replaces everything that belongs to the learner as a whole.
abstract interface class BackupRepository {
  /// All learner data as it is now. [now] becomes the snapshot's time.
  Future<BackupSnapshot> readSnapshot(DateTime now);

  /// Replaces all learner data with [snapshot]: data not in the snapshot
  /// is removed. All or nothing.
  ///
  /// Throws [UnknownItemKeyException], changing nothing, if the snapshot
  /// names an item this install does not have.
  Future<void> replaceWith(BackupSnapshot snapshot);
}
