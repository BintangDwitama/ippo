## MODIFIED Requirements

### Requirement: Seeded kana set
The system SHALL ship with 211 kana available without any network access: for each of hiragana and katakana, the 46 basic kana, the 25 voiced kana (including the 5 half-voiced), and the 33 combination kana; and three marks: the small っ in hiragana, and the small ッ and the long mark ー in katakana. Each kana SHALL have its character, its script, its group (basic, voiced, combination or mark), its row, its romaji reading or, for a mark, its name, its position in the teaching order, and a default mnemonic. Kana that share a reading within a script (for example じ and ぢ) SHALL both be present.

Seeding SHALL add kana that are missing and SHALL bring the reading, group, row, teaching order and default mnemonic of existing kana up to date with the app. Seeding SHALL NOT change which kana the learner has been introduced to, their cards, their review history, their goals or their own mnemonics.

#### Scenario: First launch offline
- **WHEN** the app is launched for the first time with no network connection
- **THEN** all 211 kana are available with character, reading or name, group and default mnemonic

#### Scenario: Seeding happens once
- **WHEN** the app is launched again after the kana have been seeded
- **THEN** no kana are duplicated and existing learner progress is unchanged

#### Scenario: Update from the basic set
- **WHEN** a learner with 10 basic hiragana introduced, 20 cards and 30 reviews updates from a version with 92 kana
- **THEN** 211 kana exist, the same 10 are introduced, and the cards and reviews are unchanged

#### Scenario: Update adds the marks
- **WHEN** a learner updates from a version with 208 kana
- **THEN** 211 kana exist and the learner's introduced kana, cards and reviews are unchanged

#### Scenario: Same reading, different kana
- **WHEN** the kana have been seeded
- **THEN** both じ and ぢ exist as separate hiragana, each read "ji"

#### Scenario: Improved default mnemonic
- **WHEN** the app is updated with a different default mnemonic for a kana whose mnemonic the learner has not edited
- **THEN** the new default is shown for that kana
- **AND** a kana whose mnemonic the learner has edited still shows the learner's text

### Requirement: Kana grid
The system SHALL show a grid of all kana for each script, divided into sections: basic, voiced, combination and marks, each in order. Each kana SHALL be marked by learning status: not started, learning, or known. A kana SHALL be "not started" until it has been introduced in a lesson, "known" when all its cards have reached the review state with a stability of at least 21 days, and "learning" otherwise. A mark, which has no cards, SHALL be "known" as soon as it has been introduced.

#### Scenario: Fresh install
- **WHEN** the learner opens the hiragana grid before taking any lesson
- **THEN** all 105 hiragana are shown as not started, in four sections of 46, 25, 33 and 1

#### Scenario: Katakana marks
- **WHEN** the learner opens the katakana grid
- **THEN** the marks section shows ッ and ー

#### Scenario: Status after a lesson
- **WHEN** the learner completes a lesson introducing five kana and opens the grid
- **THEN** those five kana are shown as learning and the rest as not started

#### Scenario: A learned mark
- **WHEN** the learner has completed the lesson for っ and opens the grid
- **THEN** っ is shown as known

#### Scenario: Open kana detail
- **WHEN** the learner taps a kana in the grid
- **THEN** the character, reading, current mnemonic and an audio button are shown

## ADDED Requirements

### Requirement: Marks are taught as rules with a spoken example
The default mnemonic of a mark SHALL explain what the mark does to the kana next to it, with a written example. Wherever the sound of a mark is played, the system SHALL play a spoken pair that differs only by the mark, so the learner hears its effect.

A mark SHALL NOT have review cards, and SHALL NOT be offered as an option in any multiple-choice question.

#### Scenario: The small っ
- **WHEN** っ is presented in a lesson
- **THEN** its mnemonic says that it doubles the consonant that follows
- **AND** the sound played is きて followed by きって

#### Scenario: The long mark
- **WHEN** the learner plays the sound of ー on its detail screen
- **THEN** a pair of words is spoken that differs only by the long mark

#### Scenario: Never an answer option
- **WHEN** a multiple-choice question about a katakana is shown to a learner who has learned ッ and ー
- **THEN** neither mark is among the options
