## ADDED Requirements

### Requirement: Words unlock with their kana
A word SHALL be available to learn only when every kana needed to read it has been introduced by a kana lesson. Marks (the small tsu and the long mark) count as kana for this purpose.

#### Scenario: All kana known
- **WHEN** あ and い have been introduced
- **THEN** あい is available

#### Scenario: One kana missing
- **WHEN** あ has been introduced and か has not
- **THEN** あか is not available

#### Scenario: A word with a mark
- **WHEN** き and て have been introduced and the small っ has not
- **THEN** きって is not available

### Requirement: Word lessons introduce a few words a day
The system SHALL offer a word lesson when available words remain that have not been introduced and today's quota of new words is not used up. The quota SHALL be five new words a day. A lesson SHALL introduce up to five words, never more than the quota leaves, taking available words in the list's learning order. The word quota SHALL be independent of the quota of new kana.

#### Scenario: A full lesson
- **WHEN** 14 words are available, none introduced today
- **THEN** a lesson of the first five in learning order is offered

#### Scenario: Quota used
- **WHEN** five words were introduced today
- **THEN** no word lesson is offered until tomorrow

#### Scenario: Few words available
- **WHEN** only two available words remain
- **THEN** a lesson of those two words is offered

#### Scenario: No words yet
- **WHEN** no kana has been introduced
- **THEN** no word lesson is offered

#### Scenario: Kana lesson does not use the word quota
- **WHEN** the learner has finished today's kana lesson and introduced no words today
- **THEN** a word lesson is still offered if words are available

### Requirement: Word presentation
A word lesson SHALL present its words one at a time. For each word it SHALL show the reading in kana as the largest element, the written form in smaller type when the word has one, the meanings, and the part of speech; it SHALL speak the word when it is shown and again on request. The learner SHALL be able to go back to an earlier word of the lesson.

#### Scenario: A word written with kanji
- **WHEN** the lesson presents the word read あめ meaning "rain"
- **THEN** あめ is shown large, 雨 smaller, with "rain" and "noun", and the word is spoken

#### Scenario: A word written in kana
- **WHEN** the lesson presents a word with no written form
- **THEN** only its reading, meanings and part of speech are shown

#### Scenario: Hear it again
- **WHEN** the learner taps the audio control
- **THEN** the word is spoken again

#### Scenario: No Japanese voice
- **WHEN** the device has no Japanese voice
- **THEN** the lesson can still be completed and the audio control explains that no voice is available

### Requirement: Word lesson check before completion
After presenting its words, a word lesson SHALL ask one question per word: the word is shown and the learner chooses its meaning from four options. A word answered wrongly SHALL be asked again until it is answered correctly. The lesson is complete only when every word has been answered correctly. Answers in the check SHALL NOT be recorded as reviews.

#### Scenario: All correct
- **WHEN** the learner answers every word of the check correctly
- **THEN** the lesson completes

#### Scenario: A wrong answer
- **WHEN** the learner answers a word wrongly
- **THEN** the correct meaning is shown and the word is asked again later in the check

#### Scenario: Leaving early
- **WHEN** the learner leaves the lesson before the check is complete
- **THEN** no word of the lesson is introduced and the same lesson is offered again

### Requirement: Completing a word lesson creates review cards
When a word lesson is completed the system SHALL mark its words as introduced and SHALL create two review cards for each: word to meaning, and meaning to word. Both happen together or not at all.

#### Scenario: Lesson of five words
- **WHEN** a lesson of five words is completed
- **THEN** five words are introduced and ten cards exist and are due

#### Scenario: Words count toward today's quota
- **WHEN** a lesson of five words is completed
- **THEN** no further word lesson is offered today
