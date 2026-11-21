/// The picked file is too large to be a backup.
class BackupFileTooLargeException implements Exception {
  const BackupFileTooLargeException();
}

/// Saves and opens backup files at places the learner chooses.
abstract interface class BackupFileRepository {
  /// Asks the learner where to save [text], offering [suggestedName].
  /// Returns false if they cancel.
  Future<bool> saveFile({required String suggestedName, required String text});

  /// Asks the learner to pick a file and returns its text, or null if
  /// they cancel.
  ///
  /// Throws [BackupFileTooLargeException] for a file too large to be a
  /// backup, without reading it.
  Future<String?> pickFile();
}
