import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:ippo/data/repositories/backup_file_repository.dart';

/// [BackupFileRepository] using the system's save and open dialogs, so
/// the app needs no storage permission.
class FilePickerBackupFileRepository implements BackupFileRepository {
  const FilePickerBackupFileRepository();

  /// Far above any real backup; guards against picking the wrong file.
  static const int maxBytes = 50 * 1024 * 1024;

  @override
  Future<bool> saveFile({
    required String suggestedName,
    required String text,
  }) async {
    final saved = await FilePicker.saveFile(
      fileName: suggestedName,
      bytes: utf8.encode(text),
      mimeType: 'application/json',
    );
    return saved != null;
  }

  @override
  Future<String?> pickFile() async {
    // No file-type filter: some storage providers report backups with a
    // generic type and would grey them out.
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    final length = await file.length();
    if (length != null && length > maxBytes) {
      throw const BackupFileTooLargeException();
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > maxBytes) throw const BackupFileTooLargeException();
    // Malformed bytes become replacement characters, which the decoder
    // then rejects as not a backup.
    return utf8.decode(bytes, allowMalformed: true);
  }
}
