import 'dart:async';

import 'package:ippo/app_dependencies.dart';
import 'package:ippo/data/repositories/backup_file_repository.dart';
import 'package:ippo/domain/backup_codec.dart';
import 'package:ippo/domain/models/backup_snapshot.dart';
import 'package:ippo/ui/backup/backup_ui_state.dart';
import 'package:ippo/ui/core/view_model.dart';

class BackupViewModel extends ViewModel {
  BackupViewModel(this._deps) {
    unawaited(_showIdle());
  }

  final AppDependencies _deps;

  /// The backup waiting for confirmation, if any.
  BackupSnapshot? _pending;

  BackupUiState _uiState = const BackupLoading();
  BackupUiState get uiState => _uiState;

  /// Saves all learner data to a file the learner places.
  Future<void> export() async {
    if (_uiState is! BackupIdle) return;
    _show(const BackupWorking(BackupWork.exporting));
    try {
      final now = _deps.clock();
      final export = await _deps.exportBackup(now: now);
      final saved = await _deps.backupFileRepository.saveFile(
        suggestedName: export.fileName,
        text: export.text,
      );
      if (!saved) return _showIdle();
      await _deps.settingsRepository.setLastExportAt(now);
      await _showIdle(BackupNotice.exported);
    } on Object {
      await _showIdle(BackupNotice.exportFailed);
    }
  }

  /// Lets the learner pick a backup file and, if it can be restored,
  /// shows what it holds. Changes no data.
  Future<void> pickImportFile() async {
    if (_uiState is! BackupIdle) return;
    _show(const BackupWorking(BackupWork.reading));
    try {
      final text = await _deps.backupFileRepository.pickFile();
      if (text == null) return _showIdle();
      final preview = await _deps.readBackup(text: text, now: _deps.clock());
      _pending = preview.snapshot;
      _show(
        BackupConfirming(
          inFile: preview.inFile,
          onPhone: preview.onPhone,
          skippedWords: preview.skippedWords,
        ),
      );
    } on BackupFormatException catch (error) {
      await _showIdle(switch (error.problem) {
        BackupFormatProblem.notABackup => BackupNotice.notABackup,
        BackupFormatProblem.newerVersion => BackupNotice.newerVersion,
        BackupFormatProblem.corrupt => BackupNotice.corrupt,
        BackupFormatProblem.unknownItems => BackupNotice.unknownItems,
      });
    } on BackupFileTooLargeException {
      await _showIdle(BackupNotice.fileTooLarge);
    } on Object {
      await _showIdle(BackupNotice.notABackup);
    }
  }

  /// Replaces the data on the phone with the backup being confirmed.
  ///
  /// Whatever goes wrong, the restore is all or nothing, so a failure is
  /// reported as "nothing changed".
  Future<void> confirmImport() async {
    final snapshot = _pending;
    if (_uiState is! BackupConfirming || snapshot == null) return;
    _pending = null;
    _show(const BackupWorking(BackupWork.restoring));
    try {
      await _deps.restoreBackup(snapshot);
      await _showIdle(BackupNotice.restored);
    } on Object {
      await _showIdle(BackupNotice.restoreFailed);
    }
  }

  Future<void> cancelImport() async {
    if (_uiState is! BackupConfirming) return;
    _pending = null;
    await _showIdle();
  }

  Future<void> dismissNotice() async {
    if (_uiState is BackupIdle) await _showIdle();
  }

  Future<void> _showIdle([BackupNotice? notice]) async {
    _show(
      BackupIdle(
        lastExportAt: await _deps.settingsRepository.getLastExportAt(),
        notice: notice,
      ),
    );
  }

  void _show(BackupUiState state) {
    _uiState = state;
    notify();
  }
}
