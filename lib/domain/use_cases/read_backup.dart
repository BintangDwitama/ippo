import 'package:ippo/data/repositories/backup_repository.dart';
import 'package:ippo/data/repositories/item_repository.dart';
import 'package:ippo/domain/backup_codec.dart';
import 'package:ippo/domain/models/backup_snapshot.dart';
import 'package:ippo/domain/models/item.dart';

/// A backup that has been read and checked, with what the learner needs
/// to decide whether to restore it.
typedef BackupPreview = ({
  BackupSnapshot snapshot,
  BackupSummary inFile,
  BackupSummary onPhone,

  /// Words named by the file that this app's word list does not have.
  /// They are left out of [snapshot] and [inFile].
  int skippedWords,
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
    final decoded = _codec.decode(text);

    final known = {for (final item in await _items.getItems()) item.key};
    final unknown = decoded.itemKeys.difference(known);
    // The word list changes between versions of the app, so a word may
    // be gone; the rest of the backup is still good. Kana never go, so
    // an unknown kana means the file is not for this app.
    final unknownWords = {
      for (final key in unknown)
        if (key.startsWith(wordKeyPrefix)) key,
    };
    final others = unknown.difference(unknownWords);
    if (others.isNotEmpty) {
      throw BackupFormatException(
        BackupFormatProblem.unknownItems,
        others.first,
      );
    }
    final snapshot = decoded.without(unknownWords);

    return (
      snapshot: snapshot,
      inFile: BackupSummary.of(snapshot),
      onPhone: BackupSummary.of(await _backups.readSnapshot(now)),
      skippedWords: unknownWords.length,
    );
  }
}
