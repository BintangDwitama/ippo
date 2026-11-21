## ADDED Requirements

### Requirement: Backups from earlier versions stay importable
The system SHALL import backup files written by earlier versions of the app. A backup written before voiced and combination kana existed SHALL restore the learner's goals with the same kana they covered when exported.

#### Scenario: Import a version 1 backup
- **WHEN** the learner imports a backup written by the version of the app that had 92 kana
- **THEN** the import succeeds and the introduced kana, cards, reviews and goals of the file are present

#### Scenario: Goal keeps its size
- **WHEN** an imported version 1 backup holds an active hiragana goal
- **THEN** the goal covers the 46 basic hiragana

#### Scenario: Older app and newer file
- **WHEN** a backup written after this change is imported into the earlier version of the app
- **THEN** it is refused with the message that it needs a newer version of Ippo, and nothing changes
