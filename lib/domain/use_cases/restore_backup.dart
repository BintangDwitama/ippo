import 'package:ippo/data/repositories/backup_repository.dart';
import 'package:ippo/domain/models/backup_snapshot.dart';
import 'package:ippo/domain/use_cases/reconcile_reminder.dart';

/// Replaces all learner data with a backup, then brings the reminder in
/// line with the restored setting.
class RestoreBackup {
  const RestoreBackup({
    required BackupRepository backupRepository,
    required this._reconcileReminder,
  }) : _backups = backupRepository;

  final BackupRepository _backups;
  final ReconcileReminder _reconcileReminder;

  /// If replacing fails, nothing has changed and the error is rethrown.
  Future<void> call(BackupSnapshot snapshot) async {
    await _backups.replaceWith(snapshot);
    await _reconcileReminder();
  }
}
