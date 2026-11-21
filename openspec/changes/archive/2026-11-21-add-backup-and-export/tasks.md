## 1. Early checks

- [x] 1.1 Spike: with `file_picker`, save a text file to a chosen location and read it back on the Android phone; record the result in design.md, and switch to `flutter_file_dialog` if saving does not work
- [x] 1.2 Find where the database file and its write-ahead files are stored on the phone (debug build, `adb shell run-as`), and record the folder in design.md
- [x] 1.3 Run `flutter analyze` and `flutter test` to confirm a clean baseline

## 2. Backup model and codec

- [x] 2.1 Define `BackupSnapshot` and its parts (introduced item, learner mnemonic, card with reviews, goal, settings) and `BackupSummary` in `lib/domain/models/`
- [x] 2.2 Implement `BackupCodec` (encode, decode, format version 1) and `BackupFormatException` with the reasons notABackup, newerVersion and corrupt
- [x] 2.3 Unit tests: round trip of a full snapshot, each decode failure reason, UTC times, and a version 1 fixture file saved in `test/fixtures/`

## 3. Data layer

- [x] 3.1 Define the `BackupRepository` interface and `UnknownItemKeyException`
- [x] 3.2 Implement `DriftBackupRepository.readSnapshot` with row-to-domain mapping
- [x] 3.3 Implement `DriftBackupRepository.replaceWith` in one transaction: resolve keys, clear learner data, write the snapshot and the three settings
- [x] 3.4 Test: fill every table, snapshot, apply to a second seeded database, compare all tables
- [x] 3.5 Test: every table in `AppDatabase.allTables` is in the list of tables the backup covers
- [x] 3.6 Tests: an unknown key changes nothing; a failure part-way rolls back; data not in the snapshot is removed; streams emit after a restore; an unedited mnemonic keeps the app's current default
- [x] 3.7 Add `getLastExportAt` and `setLastExportAt` to `SettingsRepository` (key `last_export_at`), with the drift implementation, the fake and tests
- [x] 3.8 Add `FakeBackupRepository` to `test/fakes/`

## 4. Files

- [x] 4.1 Add the file picker package chosen in task 1.1 to `pubspec.yaml`
- [x] 4.2 Define `BackupFileRepository` and implement it with the system save and open dialogs, refusing files over 50 MB
- [x] 4.3 Add `FakeBackupFileRepository` (save, cancel, pick a given text, pick nothing)

## 5. Reminder reconciliation

- [x] 5.1 Add `rescheduleIfPermitted` to `ReminderRepository`; implement it in `LocalNotificationReminderRepository` and `NotificationService` without requesting permission; update `FakeReminderRepository`
- [x] 5.2 Implement the `ReconcileReminder` use case with tests for permitted, not permitted and no reminder stored
- [x] 5.3 Run `ReconcileReminder` at app start in `main.dart`

## 6. Use cases

- [x] 6.1 Implement `ExportBackup` (snapshot, encode, suggested file name) with tests
- [x] 6.2 Implement `ReadBackup` (decode and summarise, no writes) with tests
- [x] 6.3 Implement `RestoreBackup` (replace, then reconcile the reminder) with tests
- [x] 6.4 Wire the new repositories and use cases into `AppDependencies`, `main.dart` and `FakeDependencies`

## 7. Backup screen

- [x] 7.1 Define the sealed `BackupUiState`, `BackupNotice` and `BackupWork`
- [x] 7.2 Implement `BackupViewModel`: export, pick a file, confirm, cancel, dismiss the notice
- [x] 7.3 ViewModel tests: export saved, export cancelled, each refusal reason, confirm replaces data, cancel changes nothing, last export date is not changed by an import
- [x] 7.4 Build `BackupScreen` from the shared widgets: last export, Export, Import, the side-by-side summary with "Replace data on this phone" and Cancel, notices, and the note about the phone's automatic backup
- [x] 7.5 Add the route `/settings/backup` and the "Backup and restore" entry in settings
- [x] 7.6 Widget tests: settings opens the Backup screen; the screen shows no overflow in each theme at 360 by 640 logical pixels and text scale 1.3

## 8. Android automatic backup

- [x] 8.1 Add `res/xml/data_extraction_rules.xml` and `res/xml/backup_rules.xml` that include only the database folder from task 1.2 and exclude everything else
- [x] 8.2 Set `android:allowBackup`, `android:dataExtractionRules` and `android:fullBackupContent` on the application in `AndroidManifest.xml`

## 9. Verification

- [x] 9.1 Run `flutter analyze` and `flutter test`; fix all issues
- [x] 9.2 Update README.md: the Backup screen, the backup file, and the rule to export before installing a build that may need an uninstall
- [x] 9.3 Manual, on the phone: export to Downloads; do a lesson or some reviews; import the file; confirm the state is the exported one and the app did not need a restart
- [x] 9.4 Manual, on the phone: import a text file that is not a backup and confirm it is refused with nothing changed
- [ ] 9.5 Copy the verified export file off the phone, then, with the owner's go-ahead: force an Android backup (`adb shell bmgr backupnow`), uninstall, reinstall, and confirm the data including the most recent review is back; record the result in design.md
- [x] 9.6 Manual, on the phone: with the reminder on, restore a backup and confirm the notification still arrives; with notifications blocked, confirm settings shows the reminder as off and no permission request appears
- [x] 9.7 Build a release APK and confirm it installs over the existing app and starts with data intact
