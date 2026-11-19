# kana-content Specification

## Purpose
TBD - created by archiving change add-kana-trainer. Update Purpose after archive.
## Requirements
### Requirement: Seeded kana set
The system SHALL ship with the 46 basic hiragana and the 46 basic katakana available without any network access. Each kana SHALL have its character, its script (hiragana or katakana), its romaji reading, its position in the gojūon table, and a default mnemonic.

#### Scenario: First launch offline
- **WHEN** the app is launched for the first time with no network connection
- **THEN** all 92 kana are available with character, reading and default mnemonic

#### Scenario: Seeding happens once
- **WHEN** the app is launched again after the kana have been seeded
- **THEN** no kana are duplicated and existing learner progress is unchanged

### Requirement: Learner-edited mnemonics
The system SHALL let the learner replace the default mnemonic of any kana with their own text, and SHALL let them restore the default. The learner's mnemonic SHALL be shown in place of the default wherever a mnemonic is displayed.

#### Scenario: Replace a mnemonic
- **WHEN** the learner edits the mnemonic for a kana and saves it
- **THEN** the learner's text is shown for that kana in lessons, reviews and the kana detail view

#### Scenario: Restore the default
- **WHEN** the learner chooses to restore the default mnemonic for a kana they edited
- **THEN** the default mnemonic is shown again and the learner's text is removed

#### Scenario: Empty mnemonic rejected
- **WHEN** the learner tries to save a mnemonic that is empty or only whitespace
- **THEN** the mnemonic is not saved and the previous mnemonic remains

### Requirement: Kana grid
The system SHALL show a grid of all kana for each script in gojūon order, with each kana marked by learning status: not started, learning, or known. A kana SHALL be "not started" until it has been introduced in a lesson, "known" when all its cards have reached the review state with a stability of at least 21 days, and "learning" otherwise.

#### Scenario: Fresh install
- **WHEN** the learner opens the kana grid before taking any lesson
- **THEN** all 46 kana of the selected script are shown as not started

#### Scenario: Status after a lesson
- **WHEN** the learner completes a lesson introducing five kana and opens the grid
- **THEN** those five kana are shown as learning and the rest as not started

#### Scenario: Open kana detail
- **WHEN** the learner taps a kana in the grid
- **THEN** the character, reading, current mnemonic and an audio button are shown

