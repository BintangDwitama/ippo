# data-backup Specification

## Purpose
How the learner keeps their progress safe: exporting it to a file, importing it back, and the phone's automatic backup. The automatic backup requirement has not been verified on a device yet.
## Requirements
### Requirement: Export learning data to a file
The system SHALL let the learner export all their learning data as a single file, saved to a location the learner chooses with the system file picker. Export SHALL work without a network connection and SHALL NOT require a storage permission. Export SHALL NOT change any learning data.

#### Scenario: Successful export
- **WHEN** the learner chooses Export and picks a location
- **THEN** a file named with the current date is saved there
- **AND** the screen confirms the export and shows today as the date of the last export

#### Scenario: Export cancelled
- **WHEN** the learner chooses Export and then closes the file picker without choosing a location
- **THEN** no file is written and the date of the last export is unchanged

### Requirement: Backup file content
A backup file SHALL contain everything that belongs to the learner: which kana and which words have been introduced and when, the learner's own mnemonics, every review card with its scheduling state, the full review history, all goals, and the daily review cap, reminder time and appearance settings. It SHALL identify kana and words by their stable key and SHALL carry a format version and the time of export. It SHALL NOT depend on database row ids.

#### Scenario: Round trip preserves everything
- **WHEN** learning data is exported and the file is imported into a fresh install of the same app version
- **THEN** introduced kana, learner mnemonics, cards, review history, goals and the three settings are identical to the exported state
- **AND** the due cards, goal progress and streak shown are the same as before the export

#### Scenario: Seed improvements are kept
- **WHEN** a backup is imported into an app whose default mnemonic for a kana differs from the one at export time, and the learner had not edited that mnemonic
- **THEN** the app's current default mnemonic is shown

#### Scenario: Round trip preserves words
- **WHEN** the learner has learned words, exports, and imports the file into a fresh install of the same app version
- **THEN** the same words are introduced, with the same cards, schedules and review history

### Requirement: Import replaces learning data after confirmation
The system SHALL let the learner pick a backup file and SHALL show a summary of it before anything changes: when it was exported, and how many kana, cards and reviews it holds, next to the same counts for the data on the phone. Only after the learner confirms SHALL the file's data replace all learning data on the phone. Data SHALL NOT be merged. Screens that are open SHALL show the restored data without restarting the app.

#### Scenario: Confirmed import
- **WHEN** the learner picks a valid backup file, reads the summary and confirms
- **THEN** all learning data on the phone is replaced by the file's data
- **AND** the home screen shows the restored due cards, goal and streak

#### Scenario: Import cancelled at the summary
- **WHEN** the learner picks a valid backup file and then cancels at the summary
- **THEN** nothing on the phone changes

#### Scenario: Data not in the file is removed
- **WHEN** the phone has 20 introduced kana and the imported file has 10
- **THEN** after the import exactly those 10 kana are introduced and the cards of the other 10 no longer exist

### Requirement: Invalid backup files are refused
The system SHALL refuse a file that is not an Ippo backup, is damaged, was written by a newer version of the app, or names kana this app does not have. A refusal SHALL state the reason in plain words and SHALL leave all data on the phone unchanged. An import that fails part-way SHALL leave all data unchanged.

#### Scenario: Not a backup
- **WHEN** the learner picks a file that is not an Ippo backup
- **THEN** the screen says the file is not an Ippo backup and nothing changes

#### Scenario: Newer version
- **WHEN** the learner picks a backup written by a newer version of the app
- **THEN** the screen says the backup needs a newer version of Ippo and nothing changes

#### Scenario: Failure during import
- **WHEN** an error occurs after an import has started writing
- **THEN** every change of that import is undone and the data is as it was before

### Requirement: Last export is shown
The Backup screen SHALL show when the learner last exported, or that they never have. This date SHALL describe exports made from this phone and SHALL NOT be taken from an imported file.

#### Scenario: Never exported
- **WHEN** the learner opens the Backup screen before any export
- **THEN** it says no export has been made yet

#### Scenario: Import does not change the date
- **WHEN** the learner imports a backup that was exported last month
- **THEN** the date of the last export is unchanged

### Requirement: Automatic device backup
On Android, the app's learning data SHALL be included in the device's automatic backup when the learner has backup turned on for the device. After the app is reinstalled on a device restored from that backup, the learner's data SHALL be present without any action in the app. Notification schedules and other device-specific platform state SHALL be excluded from the automatic backup.

#### Scenario: Reinstall restores progress
- **WHEN** the device has completed an automatic backup, the app is uninstalled, and it is installed again on a device with the same account and backup turned on
- **THEN** the introduced kana, cards, review history and goals from the backup are present on first launch

#### Scenario: Backup turned off
- **WHEN** the device has automatic backup turned off
- **THEN** the app works normally and manual export and import remain available

### Requirement: Backup screen is reachable from settings
The settings screen SHALL give access to a Backup screen that offers export and import and explains that the phone also backs up automatically when device backup is turned on.

#### Scenario: Open the Backup screen
- **WHEN** the learner selects "Backup and restore" in settings
- **THEN** the Backup screen opens with the Export and Import actions and the date of the last export

### Requirement: Backups from earlier versions stay importable
The system SHALL import backup files written by earlier versions of the app. A backup written before voiced and combination kana existed SHALL restore the learner's goals with the same kana they covered when exported. A backup written before words existed SHALL import with no words introduced.

#### Scenario: Import a version 1 backup
- **WHEN** the learner imports a backup written by the version of the app that had 92 kana
- **THEN** the import succeeds and the introduced kana, cards, reviews and goals of the file are present

#### Scenario: Goal keeps its size
- **WHEN** an imported version 1 backup holds an active hiragana goal
- **THEN** the goal covers the 46 basic hiragana

#### Scenario: Older app and newer file
- **WHEN** a backup written after this change is imported into the earlier version of the app
- **THEN** it is refused with the message that it needs a newer version of Ippo, and nothing changes

#### Scenario: Import a backup from before words
- **WHEN** the learner imports a backup written by the version of the app that had no words
- **THEN** the import succeeds, the kana data of the file is present and no word is introduced

### Requirement: Words missing from the app are skipped on import
When a backup names words that the importing app's word list does not have, the system SHALL import the rest of the file and leave those words out, together with their cards and review history. The summary shown before the learner confirms SHALL state how many words will be left out. A backup that names kana the app does not have SHALL still be refused.

#### Scenario: A word no longer in the list
- **WHEN** the learner picks a backup holding 40 words, two of which this app's list does not have
- **THEN** the summary states that 2 words in the file are not in this version and will be left out
- **AND** after confirming, 38 words are introduced with their cards and history

#### Scenario: Unknown kana still refused
- **WHEN** the learner picks a backup that names a kana this app does not have
- **THEN** the file is refused and nothing changes

### Requirement: Import summary counts words
The summary shown before an import SHALL state how many words the file holds, next to the count for the data on the phone, in addition to the counts of kana, cards and reviews.

#### Scenario: Summary with words
- **WHEN** the learner picks a backup holding 46 kana and 30 words
- **THEN** the summary shows 46 kana and 30 words for the file, beside the phone's own counts

