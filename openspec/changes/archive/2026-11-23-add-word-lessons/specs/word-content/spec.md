## ADDED Requirements

### Requirement: Bundled word list
The app SHALL ship with the project's beginner word list and SHALL make every word in it a learnable item, identified by a stable key derived from the word's identifier in the list. Each word item SHALL carry its reading, its written form if it has one, its meanings, its part of speech, its level, its position in the learning order and the kana needed to read it. The app SHALL work without a network connection.

#### Scenario: First launch
- **WHEN** the app is started for the first time
- **THEN** every word of the bundled list exists as an item and none is introduced

#### Scenario: A word's content
- **WHEN** the item for 雨 is read
- **THEN** it has the reading あめ, the written form 雨, the meaning "rain" and the kana あ and め

### Requirement: Words follow the bundled list
On every launch the app SHALL bring its word items in line with the bundled list: adding words that are missing and updating the content and order of words already stored. It SHALL NOT change which words the learner has been introduced to, their review cards or their review history, and SHALL NOT remove a word.

#### Scenario: A meaning is corrected in a newer version
- **WHEN** the app is updated to a version whose list gives a different meaning for a word the learner has already learned
- **THEN** the word shows the new meaning
- **AND** its review cards and their schedules are unchanged

#### Scenario: New words in a newer version
- **WHEN** the app is updated to a version whose list has words the stored data lacks
- **THEN** those words exist as items that are not yet introduced

#### Scenario: A word dropped from the list
- **WHEN** the app is updated to a version whose list no longer has a word the learner has learned
- **THEN** the word and its review cards remain

### Requirement: Words do not appear among kana
Word items SHALL NOT be shown in the kana grid, counted in kana totals, offered in kana lessons or counted toward a kana goal.

#### Scenario: Kana grid
- **WHEN** the learner opens the kana grid after learning ten words
- **THEN** the grid shows the same kana as before and no words

#### Scenario: Goal progress
- **WHEN** the learner has an active hiragana goal and learns words
- **THEN** the goal's count of kana and its accuracy are calculated from kana only
