## MODIFIED Requirements

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

## ADDED Requirements

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
