import 'package:flutter_test/flutter_test.dart';
import 'package:ippo/domain/backup_codec.dart';
import 'package:ippo/ui/backup/backup_ui_state.dart';
import 'package:ippo/ui/backup/backup_view_model.dart';

import '../support/backup_builders.dart';
import '../support/builders.dart';
import '../support/fake_dependencies.dart';

void main() {
  const codec = BackupCodec();
  final now = DateTime(2026, 11, 21, 9, 15);

  FakeDependencies dependencies() =>
      FakeDependencies(items: kanaItems(hiraganaCount: 12), now: now);

  Future<BackupViewModel> create(FakeDependencies deps) async {
    final viewModel = BackupViewModel(deps.app);
    addTearDown(viewModel.dispose);
    await pumpEventQueue();
    return viewModel;
  }

  BackupIdle idle(BackupViewModel viewModel) => viewModel.uiState as BackupIdle;

  test('starts loading, then shows that nothing was exported yet', () async {
    final viewModel = BackupViewModel(dependencies().app);
    addTearDown(viewModel.dispose);
    expect(viewModel.uiState, isA<BackupLoading>());

    await pumpEventQueue();

    expect(idle(viewModel).lastExportAt, isNull);
    expect(idle(viewModel).notice, isNull);
  });

  test('shows the date of an earlier export', () async {
    final deps = dependencies();
    deps.settings.lastExportAt = DateTime.utc(2026, 11, 1);

    final viewModel = await create(deps);

    expect(idle(viewModel).lastExportAt, DateTime.utc(2026, 11, 1));
  });

  group('export', () {
    test('saves the backup and records when', () async {
      final deps = dependencies();
      deps.backups.current = fullSnapshot();
      final viewModel = await create(deps);

      await viewModel.export();

      expect(deps.backupFiles.saved.keys, ['ippo-backup-2026-11-21.json']);
      final saved = codec.decode(deps.backupFiles.saved.values.single);
      expect(saved.cards, hasLength(3));
      expect(idle(viewModel).notice, BackupNotice.exported);
      expect(idle(viewModel).lastExportAt, now);
      expect(deps.settings.lastExportAt, now);
      expect(deps.backups.replaced, isEmpty);
    });

    test('passes through a working state', () async {
      final viewModel = await create(dependencies());
      final states = <BackupUiState>[];
      viewModel.addListener(() => states.add(viewModel.uiState));

      await viewModel.export();

      expect(states.first, isA<BackupWorking>());
      expect((states.first as BackupWorking).work, BackupWork.exporting);
      expect(states.last, isA<BackupIdle>());
    });

    test('cancelled in the file dialog records nothing', () async {
      final deps = dependencies();
      deps.backupFiles.acceptSave = false;
      final viewModel = await create(deps);

      await viewModel.export();

      expect(idle(viewModel).notice, isNull);
      expect(idle(viewModel).lastExportAt, isNull);
      expect(deps.settings.lastExportAt, isNull);
    });
  });

  group('import', () {
    test('shows the file next to the phone and changes nothing yet', () async {
      final deps = dependencies();
      deps.backupFiles.fileToPick = codec.encode(fullSnapshot());
      final viewModel = await create(deps);

      await viewModel.pickImportFile();

      final state = viewModel.uiState as BackupConfirming;
      expect(state.inFile.introducedCount, 2);
      expect(state.inFile.cardCount, 3);
      expect(state.inFile.reviewCount, 2);
      expect(state.onPhone.cardCount, 0);
      expect(deps.backups.replaced, isEmpty);
    });

    test('confirmed replaces the data on the phone', () async {
      final deps = dependencies();
      deps.backupFiles.fileToPick = codec.encode(fullSnapshot());
      final viewModel = await create(deps);
      await viewModel.pickImportFile();

      await viewModel.confirmImport();

      expect(deps.backups.replaced, hasLength(1));
      expect(deps.backups.replaced.single.cards, hasLength(3));
      expect(idle(viewModel).notice, BackupNotice.restored);
    });

    test('cancelled at the summary changes nothing', () async {
      final deps = dependencies();
      deps.backupFiles.fileToPick = codec.encode(fullSnapshot());
      final viewModel = await create(deps);
      await viewModel.pickImportFile();

      await viewModel.cancelImport();
      // A stray confirm after cancelling must not restore anything.
      await viewModel.confirmImport();

      expect(deps.backups.replaced, isEmpty);
      expect(idle(viewModel).notice, isNull);
    });

    test('cancelled in the file dialog returns to idle', () async {
      final deps = dependencies();
      final viewModel = await create(deps);

      await viewModel.pickImportFile();

      expect(idle(viewModel).notice, isNull);
      expect(deps.backups.replaced, isEmpty);
    });

    test('does not change the date of the last export', () async {
      final deps = dependencies();
      deps.settings.lastExportAt = DateTime.utc(2026, 11, 1);
      deps.backupFiles.fileToPick = codec.encode(fullSnapshot());
      final viewModel = await create(deps);

      await viewModel.pickImportFile();
      await viewModel.confirmImport();

      expect(idle(viewModel).lastExportAt, DateTime.utc(2026, 11, 1));
      expect(deps.settings.lastExportAt, DateTime.utc(2026, 11, 1));
    });

    test('reports a failed restore and that nothing changed', () async {
      final deps = dependencies();
      deps.backupFiles.fileToPick = codec.encode(fullSnapshot());
      final viewModel = await create(deps);
      await viewModel.pickImportFile();
      deps.backups.failOnReplace = true;

      await viewModel.confirmImport();

      expect(idle(viewModel).notice, BackupNotice.restoreFailed);
      expect(deps.backups.replaced, isEmpty);
    });

    Future<BackupNotice?> noticeAfterPicking(
      void Function(FakeDependencies deps) arrange,
    ) async {
      final deps = dependencies();
      arrange(deps);
      final viewModel = await create(deps);

      await viewModel.pickImportFile();

      expect(deps.backups.replaced, isEmpty);
      return idle(viewModel).notice;
    }

    test('refuses a file that is not a backup', () async {
      expect(
        await noticeAfterPicking((d) => d.backupFiles.fileToPick = 'hello'),
        BackupNotice.notABackup,
      );
    });

    test('refuses a backup from a newer version', () async {
      const current = BackupCodec.formatVersion;
      final text = codec.encode(fullSnapshot()).replaceFirst(
            '"formatVersion":$current',
            '"formatVersion":${current + 1}',
          );
      expect(text, contains('"formatVersion":${current + 1}'));

      expect(
        await noticeAfterPicking((d) => d.backupFiles.fileToPick = text),
        BackupNotice.newerVersion,
      );
    });

    test('refuses a damaged backup', () async {
      final text = codec
          .encode(fullSnapshot())
          .replaceFirst('"phase":"review"', '"phase":"napping"');

      expect(
        await noticeAfterPicking((d) => d.backupFiles.fileToPick = text),
        BackupNotice.corrupt,
      );
    });

    test('refuses a backup with kana this app does not have', () async {
      final text = codec.encode(
        fullSnapshot(keys: ['hiragana:a', 'hiragana:kya']),
      );

      expect(
        await noticeAfterPicking((d) => d.backupFiles.fileToPick = text),
        BackupNotice.unknownItems,
      );
    });

    test('refuses a file too large to be a backup', () async {
      expect(
        await noticeAfterPicking((d) => d.backupFiles.pickTooLarge = true),
        BackupNotice.fileTooLarge,
      );
    });
  });

  test('a notice can be dismissed', () async {
    final deps = dependencies();
    deps.backupFiles.fileToPick = 'hello';
    final viewModel = await create(deps);
    await viewModel.pickImportFile();
    expect(idle(viewModel).notice, isNotNull);

    await viewModel.dismissNotice();

    expect(idle(viewModel).notice, isNull);
  });

  test('every refusal is marked as an error and successes are not', () {
    expect(BackupNotice.exported.isError, isFalse);
    expect(BackupNotice.restored.isError, isFalse);
    for (final notice in BackupNotice.values) {
      if (notice == BackupNotice.exported || notice == BackupNotice.restored) {
        continue;
      }
      expect(notice.isError, isTrue, reason: notice.name);
    }
  });
}
