import 'package:ippo/data/repositories/backup_repository.dart';
import 'package:ippo/domain/backup_codec.dart';

/// The text of a backup file and the name to offer for it.
typedef BackupExport = ({String fileName, String text});

/// Produces a backup of all learner data. Changes nothing.
class ExportBackup {
  const ExportBackup({
    required BackupRepository backupRepository,
    this._codec = const BackupCodec(),
  }) : _backups = backupRepository;

  final BackupRepository _backups;
  final BackupCodec _codec;

  Future<BackupExport> call({required DateTime now}) async {
    final snapshot = await _backups.readSnapshot(now);
    final local = now.toLocal();
    final date =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    return (fileName: 'ippo-backup-$date.json', text: _codec.encode(snapshot));
  }
}
