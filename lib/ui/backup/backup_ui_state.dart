import 'package:flutter/foundation.dart';
import 'package:ippo/domain/models/backup_snapshot.dart';

/// The outcome of the last action, told to the learner.
enum BackupNotice {
  exported,
  restored,
  exportFailed,
  restoreFailed,
  notABackup,
  newerVersion,
  corrupt,
  unknownItems,
  fileTooLarge;

  bool get isError => this != exported && this != restored;
}

/// What the screen is busy with.
enum BackupWork { exporting, reading, restoring }

@immutable
sealed class BackupUiState {
  const BackupUiState();
}

class BackupLoading extends BackupUiState {
  const BackupLoading();
}

/// Waiting for the learner to export or import.
class BackupIdle extends BackupUiState {
  const BackupIdle({this.lastExportAt, this.notice});

  /// When this phone last exported; null if it never has.
  final DateTime? lastExportAt;
  final BackupNotice? notice;
}

class BackupWorking extends BackupUiState {
  const BackupWorking(this.work);

  final BackupWork work;
}

/// A backup file has been read; the learner decides whether it replaces
/// the data on the phone.
class BackupConfirming extends BackupUiState {
  const BackupConfirming({
    required this.inFile,
    required this.onPhone,
    this.skippedWords = 0,
  });

  final BackupSummary inFile;
  final BackupSummary onPhone;

  /// Words in the file that this version of the app does not have; they
  /// will be left out.
  final int skippedWords;
}
