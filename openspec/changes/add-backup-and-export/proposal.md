## Why

All learning progress lives in one database on one phone. A lost phone, an uninstall, or a development build signed with a different key wipes it, and daily use is about to start, so from now on there is real data to lose. The first change named backup as the next candidate; this change delivers it before any later change touches the schema.

## What Changes

- Add a manual **export**: the learner saves all their learning data as one JSON file, to a location they choose with the system file picker.
- Add a manual **import**: the learner picks a backup file, sees a summary of what it holds next to what is on the phone, confirms, and the file's data replaces everything on the phone. There is no merging.
- A file that is malformed, not an Ippo backup, or written by a newer version of the app is refused and nothing on the phone changes.
- The backup file refers to kana by their stable key, not by database row id, and carries a format version, so it stays readable across app versions.
- Add a **Backup and restore** screen, opened from settings, showing the export and import actions, the date of the last export, and a note about the phone's automatic backup.
- Declare **Android's automatic backup** explicitly: the database is included, device-only state is excluded. This is the automatic layer; it restores when the app is reinstalled on a phone with the same Google account.
- Keep the **daily reminder in step with the stored setting**: after an import, an automatic restore, or any app start, a reminder that is stored as on is scheduled again if notifications are allowed, and shown as off if they are not.
- Not included: automatic export to a folder, a reminder to export, encryption of the file, merging two histories, cloud sync, iOS.

## Capabilities

### New Capabilities

- `data-backup`: Exporting learning data to a file, importing it back, the content and versioning of the backup file, the phone's automatic backup, and which state is never restored.

### Modified Capabilities

- `learning-goals`: adds a requirement that the daily reminder follows the stored setting when the app starts and after data is restored. Existing reminder requirements are unchanged.

## Impact

- **Code**: new domain model and codec for a backup snapshot; new `BackupRepository` (reads and replaces learner data in one transaction) and `BackupFileRepository` (system file picker); new export and import use cases; a new Backup screen with its ViewModel; one new route; one new settings entry; `ReminderRepository` gains a way to reschedule without asking for permission; a start-up step reconciles the reminder.
- **Dependencies**: one new package for the system save and open dialogs (`file_picker`, to be confirmed by a spike).
- **Android**: `AndroidManifest.xml` gains explicit backup attributes and two small XML rule files. No new permission.
- **Data**: no schema change. One new settings key for the date of the last export.
- **Tests**: codec round trip, a test that fails when a database table is not covered by the backup, import validation and rollback, reminder reconciliation, ViewModel and navigation tests, and the new screen added to the per-theme layout test.
- **Manual verification**: an export and import round trip on the phone, and a real automatic-backup restore (back up, uninstall, reinstall). The second one removes the app's data from the phone, so it is done only after a manual export and with the owner's go-ahead.
