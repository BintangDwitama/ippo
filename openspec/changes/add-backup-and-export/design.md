## Context

The database (`AppDatabase`, schema version 1) has six tables. Most of `items` and the default text in `mnemonics` ship with the app and are re-seeded on every launch by `KanaSeedLoader`, which only inserts keys that are missing. What belongs to the learner is: `items.introducedAt`, `mnemonics.learnerText`, all of `cards`, `review_records` and `goals`, and three settings (daily review cap, reminder time, appearance). Every item has a stable key such as `hiragana:ka`.

Repositories expose single-row operations (`createCard`, `addReview`, `markIntroduced`); none can clear or bulk-load a table. `UnitOfWork` gives transactions across repositories. The reminder is scheduled by `ReminderRepository.enableReminder`, which also asks for notification permission.

The manifest sets no backup attribute, so Android's default applies; it has never been tested. Decisions taken in exploration: JSON as the file format, import replaces everything, Android's automatic backup is the automatic layer, automatic export to a folder is left for later.

## Goals / Non-Goals

**Goals:**
- A learner can get all their data out of the app and back in, on the same or another phone.
- A backup written today can be read by later versions of the app.
- A failed or refused import changes nothing.
- It is impossible to add a table later and silently leave it out of the backup.
- Android's automatic backup is a deliberate, tested feature and not an accident of defaults.

**Non-Goals:**
- Merging a backup with existing data.
- Automatic export to a folder, cloud sync, or an account.
- Encrypting the file. It holds study history and the learner's own mnemonic text.
- Backing up seed content (kana, readings, default mnemonics).
- iOS.

## Decisions

### 1. The backup file is JSON, keyed by item key, with a format version

```json
{
  "format": "ippo-backup",
  "formatVersion": 1,
  "exportedAt": "2026-11-21T02:15:00Z",
  "items": [{ "key": "hiragana:ka", "introducedAt": "2026-11-20T11:02:00Z" }],
  "mnemonics": [{ "key": "hiragana:ka", "learnerText": "a kite cutting the air" }],
  "cards": [{
    "key": "hiragana:ka", "promptType": "charToSoundChoice",
    "phase": "review", "step": null, "due": "...", "stability": 4.2,
    "difficulty": 5.1, "lastReview": "...", "reps": 6, "lapses": 1,
    "consecutiveCorrect": 3, "createdAt": "...",
    "reviews": [{ "reviewedAt": "...", "rating": "good", "wasCorrect": true,
                  "phaseBefore": "learning", "elapsedDays": 0 }]
  }],
  "goals": [{ "targetSet": "hiragana", "targetAccuracy": 0.9,
              "createdAt": "...", "deadline": "...", "status": "active" }],
  "settings": { "dailyReviewCap": 100, "reminderTime": "19:00",
                "appearanceMode": "automatic" }
}
```

Only introduced items and edited mnemonics are listed. Reviews are nested under their card, so no database id appears anywhere. All times are UTC in ISO 8601. Enum values are written by name.

Alternative considered: copying the SQLite file. Export is trivial and exact, but restore means closing the database, swapping the file and restarting the app; old default mnemonics come back over improved ones; and the file is tied to row ids and the schema. JSON's one real risk, a forgotten table, is closed by decision 7.

### 2. A `BackupSnapshot` domain model and a pure codec

`BackupSnapshot` (in `domain/models/`) holds the content above as immutable Dart objects using existing domain types (`SchedulingState`, `PromptType`, `Rating`, `GoalTargetSet`, `ReminderTime`, `AppearanceMode`). `BackupCodec` (in `domain/`) turns a snapshot into a JSON string and back. It has no Flutter or database dependency.

Decoding throws a typed `BackupFormatException` with a reason: `notABackup` (not JSON, or `format` is missing or different), `newerVersion` (`formatVersion` above the one this app writes), or `corrupt` (a field is missing or has the wrong type). When the format changes later, the codec upgrades older versions on read.

### 3. `BackupRepository` reads and replaces learner data in one transaction

```dart
abstract interface class BackupRepository {
  Future<BackupSnapshot> readSnapshot(DateTime now);

  /// Replaces all learner data with [snapshot]. All or nothing.
  /// Throws [UnknownItemKeyException] if the snapshot names a kana this
  /// app does not have; nothing is changed in that case.
  Future<void> replaceWith(BackupSnapshot snapshot);
}
```

`DriftBackupRepository` works on the tables directly, inside one drift transaction: it resolves every key to an item id first (failing before any write if one is unknown), deletes all `review_records`, `cards` and `goals`, clears `introducedAt` and `learnerText` everywhere, then writes the snapshot and the three settings. Row types stay inside the data layer.

Because writes go through drift, every `get…Stream` re-emits, so open screens update without a restart.

Alternative considered: doing the restore from a use case through the existing repositories inside `UnitOfWork`. Rejected: it needs delete-all and bulk-insert methods on five repository interfaces that nothing else would use.

### 4. Use cases

- `ExportBackup`: reads the snapshot, encodes it, returns the text and a suggested file name `ippo-backup-YYYY-MM-DD.json`.
- `ReadBackup`: decodes text into a snapshot and builds a `BackupSummary` (export date, kana introduced, cards, reviews) for the confirm step. Changes nothing.
- `RestoreBackup`: applies a snapshot with `BackupRepository.replaceWith`, then reconciles the reminder (decision 6).

Splitting read from restore is what makes "show a summary, then confirm" possible without touching the database first.

### 5. Files go through the system file picker, behind `BackupFileRepository`

```dart
abstract interface class BackupFileRepository {
  /// Asks the learner where to save. Returns false if they cancel.
  Future<bool> saveFile({required String suggestedName, required String text});

  /// Asks the learner to pick a file. Returns null if they cancel.
  Future<String?> pickFile();
}
```

The implementation uses Android's document picker through a package, so the app needs no storage permission and the learner can save to Downloads, Google Drive or anywhere a provider exists. The planned package is `file_picker`; a spike (task 1.1) confirms that it can save text to a location chosen on Android 16 and read it back. If it cannot, `flutter_file_dialog` is the fallback behind the same interface.

A picked file larger than 50 MB is refused before decoding, so a wrong file cannot exhaust memory.

### 6. The reminder follows the stored setting

`ReminderRepository` gains:

```dart
/// Schedules the reminder if notifications are already allowed.
/// Never asks for permission. Returns false if they are not allowed.
Future<bool> rescheduleIfPermitted(ReminderTime time);
```

A `ReconcileReminder` use case reads the stored reminder time. If there is one, it calls `rescheduleIfPermitted`; if that returns false it stores the reminder as off, so settings never claims a reminder that cannot fire. If there is none, it cancels any schedule. It runs at app start and at the end of `RestoreBackup`.

Running it at every start is deliberate: the app cannot tell that Android has just restored its data, and rescheduling an existing reminder is harmless. It never prompts, because a permission dialog at launch or in the middle of an import would be out of place; the learner turns the reminder back on in settings, which asks as it does today.

### 7. A test that fails when a table is not covered

A repository test fills every table with distinct data, takes a snapshot, applies it to a second, freshly seeded database, and compares the two databases table by table. A second test lists `AppDatabase.allTables` and fails if a table name is not in an explicit list of tables the backup handles, with a message that says to extend the backup. Adding a table without deciding its place in the backup therefore breaks the build.

### 8. Android automatic backup is declared and limited to the database

`AndroidManifest.xml` sets `android:allowBackup="true"`, `android:dataExtractionRules="@xml/data_extraction_rules"` (Android 12 and later) and `android:fullBackupContent="@xml/backup_rules"` (earlier). Both rule files include only the folder that holds the database and exclude everything else, in particular shared preferences, where the notification plugin keeps its schedules.

The exact folder is confirmed on the device first (task 1.2), because it depends on where `drift_flutter` places the file. The whole folder is included, not only `ippo.sqlite`, so that SQLite's write-ahead files travel with it.

Device state inside the database (the "voice notice shown" setting) does come back through this route. That is accepted: the worst case is one notice not shown again on a new phone, and settings always shows the voice status.

### 9. A Backup screen with its own ViewModel

Settings gets one entry, "Backup and restore", opening `/settings/backup`. The flow has too many states to fold into `SettingsUiState`.

```dart
sealed class BackupUiState
  BackupIdle        { DateTime? lastExportAt; BackupNotice? notice }
  BackupWorking     { BackupWork work }          // exporting, reading, restoring
  BackupConfirming  { BackupSummary file; BackupSummary onPhone }
```

`BackupNotice` covers: exported, restored, and each refusal reason. `BackupViewModel` methods: `export()`, `pickImportFile()`, `confirmImport()`, `cancelImport()`, `dismissNotice()`. The file dialogs are opened by `BackupFileRepository`, so the ViewModel holds no `BuildContext`.

The screen is built from the shared widgets and is added to the per-theme layout test. The confirm step is part of the screen, not a dialog, so the summary has room: two columns, "In the file" and "On this phone", then a destructive-styled confirm button and a cancel button. The restore button's label states the consequence: "Replace data on this phone".

The date of the last export is stored under the settings key `last_export_at`. It is never written into a backup or restored from one.

### 10. Testing

- **Domain**: codec round trip; each decode failure reason; an older-version fixture file kept in `test/fixtures/` from this change on.
- **Data**: the two tests of decision 7; unknown key leaves the database unchanged; a failure part-way rolls back; streams emit after a restore.
- **Use cases**: `ReconcileReminder` for permitted, not permitted and no reminder; `RestoreBackup` calls it.
- **UI**: `BackupViewModel` with `FakeBackupFileRepository` and `FakeBackupRepository` for export, cancel, each refusal, confirm and cancel; navigation from settings; the screen in each theme at 360 by 640 with large text.
- **Manual**: on the phone, export, study, import, and confirm the state is the exported one; then the automatic-backup restore.

### 11. Notes from implementation

- **File picker (task 1.1, not yet run on the phone).** `file_picker` 13.4.0 is used. Its source shows `FilePicker.saveFile(fileName, bytes, mimeType)` returning the saved location or null on cancel, and `FilePicker.pickFile()` returning a file that is read with `readAsBytes()`. That matches `BackupFileRepository`. Whether the dialogs behave on the phone is still to be confirmed.
- **Database folder (task 1.2, not yet confirmed on the phone).** `drift_flutter` 0.3.1 places the file in the application documents directory as `ippo.sqlite`, which on Android is the `app_flutter` folder under the app's data root. The backup rules include `domain="root" path="app_flutter"`. This is read from the package source, not from the device.
- **Settings go through `SettingsRepository`.** `DriftBackupRepository` takes the settings repository of the same database and calls it inside its transaction, so the setting keys and their encoding stay in one place.
- **Unknown kana are caught twice.** `ReadBackup` refuses the file before the confirm step (reason `unknownItems`), and `DriftBackupRepository.replaceWith` checks again before its first write.
- **The same card twice in a file is treated as damage** by the codec. The database would also reject it, and that path is what the rollback test uses.
- **The notice sits above the list, not in it.** Flutter restores a list's scroll position, so a notice at the top of the list was off screen after an import started from lower down. A test on a small screen found this.
- **The reminder is reconciled after the first frame**, not before it, so start-up does not wait for the notification plugin. A failure there is ignored.
- **The confirm button uses the theme's error colours**, which were added to the contrast test.
- **Goal dates and time zones.** A goal's deadline is stored as an instant. Restoring on a phone in another time zone keeps the instant, so the deadline's local time of day shifts. Accepted.

## Risks / Trade-offs

- **Android's automatic backup may not restore on this phone** (backup switched off, or Samsung-specific behaviour) → It is tested with a real uninstall and reinstall. If it fails and cannot be fixed, the screen's note is changed to say so and a reminder to export is proposed as a follow-up.
- **The restore test wipes the phone's data** → It runs only after a manual export has been saved off the phone and verified by an import, and with the owner's go-ahead.
- **A reinstall signed with a different key may not get its data restored** → Not tested in this change. Until known, the rule for development is: export before installing a build that could require an uninstall.
- **The write-ahead file may hold changes not yet in the main database file when Android backs up** → The whole folder is included; the restore test checks that the most recent review is present.
- **The file picker package may not support saving on Android 16** → Spike first; a fallback package sits behind the same interface.
- **Import is destructive and cannot be undone** → It needs an explicit confirm after a side-by-side summary. An automatic pre-import snapshot was considered and left out; exporting first is the documented way to keep the current state.
- **Review history grows without bound in one JSON string** → About 4 MB a year at 100 reviews a day by estimate. Acceptable; compression can be added under a new format version.
- **A backup taken on a phone with more kana than this app has** (after the voiced-kana change, restored into an older build) → Refused as a whole with a clear message. The format version is raised when the kana set grows, so the normal refusal is "made by a newer version".

## Migration Plan

No data migration. Existing installs gain the new screen and the manifest attributes with the update. The first automatic backup happens on Android's own schedule after the update is installed. Rollback is reverting the change; the extra settings key is ignored by older code.

## Open Questions

- Whether Android restores app data when the reinstalled build is signed with a different key.
- Whether the export should later be compressed, once real files exist to measure.
