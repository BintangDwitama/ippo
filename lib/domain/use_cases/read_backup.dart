import 'package:ippo/data/repositories/backup_repository.dart';
import 'package:ippo/data/repositories/item_repository.dart';
import 'package:ippo/domain/backup_codec.dart';
import 'package:ippo/domain/models/backup_snapshot.dart';

/// A backup that has been read and checked, with what the learner needs
/// to decide whether to restore it.
typedef BackupPreview = ({
  BackupSnapshot snapshot,
  BackupSummary inFile,
  BackupSummary onPhone,
});

/// Reads the text of a backup file and checks that this app can restore
/// it. Changes nothing.
class ReadBackup {
  const ReadBackup({
    required BackupRepository backupRepository,
    required ItemRepository itemRepository,
    this._codec = const BackupCodec(),
  }) : _backups = backupRepository,
       _items = itemRepository;

  final BackupRepository _backups;
  final ItemRepository _items;
  final BackupCodec _codec;

  /// Throws [BackupFormatException] if [text] cannot be restored here.
  Future<BackupPreview> call({
    required String text,
    required DateTime now,
  }) async {
    final snapshot = _codec.decode(text);

    final known = {for (final item in await _items.getItems()) item.key};
    final unknown = snapshot.itemKeys.difference(known);
    if (unknown.isNotEmpty) {
      throw BackupFormatException(
        BackupFormatProblem.unknownItems,
        unknown.first,
      );
    }

    return (
      snapshot: snapshot,
      inFile: BackupSummary.of(snapshot),
      onPhone: BackupSummary.of(await _backups.readSnapshot(now)),
    );
  }
}
