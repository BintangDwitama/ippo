## ADDED Requirements

### Requirement: Word prompt types
The system SHALL support these prompt types for words:
- word to meaning, multiple choice: show the word, choose its meaning from four options;
- meaning to word, multiple choice: show the meaning, choose the word from four options.

Wherever a word is shown, as the question or as an option, its reading SHALL be shown in kana with its written form in smaller type when it has one. Wherever a meaning is shown, all of the word's meanings SHALL be shown together.

Wrong options SHALL be other words. A word SHALL NOT be offered as a wrong option when it has the same reading as the correct word or shares any meaning with it. Wrong options SHALL be words the learner has been introduced to whenever at least three suitable ones exist; otherwise the remainder SHALL be other words the learner can read. Among suitable words the system SHALL prefer those with the same part of speech as the correct word. The choice SHALL vary between presentations.

Word cards SHALL NOT require a Japanese voice.

#### Scenario: Word to meaning
- **WHEN** a word-to-meaning card for 雨 is presented
- **THEN** あめ is shown with 雨 in smaller type, and four meanings are offered, exactly one of which is "rain"

#### Scenario: Meaning to word
- **WHEN** a meaning-to-word card for 雨 is presented
- **THEN** "rain" is shown and four words are offered, each as reading with written form, exactly one of which is あめ 雨

#### Scenario: Same reading is never a wrong option
- **WHEN** a card for 雨 (あめ) is presented and 飴 (あめ) has been introduced
- **THEN** 飴 is not among the options

#### Scenario: Shared meaning is never a wrong option
- **WHEN** a card for a word meaning "hot" is presented and another introduced word also has the meaning "hot"
- **THEN** that other word is not among the options

#### Scenario: Same part of speech preferred
- **WHEN** a card for a verb is presented and at least three other suitable verbs have been introduced
- **THEN** all three wrong options are verbs

#### Scenario: Few words learned
- **WHEN** a card is presented and only two other suitable words have been introduced
- **THEN** four options are still offered, the remainder being words the learner can read

#### Scenario: No voice installed
- **WHEN** the device has no Japanese voice and word cards are due
- **THEN** the word cards are included in the session

## MODIFIED Requirements

### Requirement: Interleaved ordering
Within a session, the system SHALL mix kana and word cards, scripts and prompt types instead of grouping them, and SHALL NOT show two cards of the same kana or the same word consecutively unless no other card remains.

#### Scenario: Mixed session
- **WHEN** a session contains hiragana and katakana cards of several prompt types
- **THEN** the cards are presented in a mixed order, not grouped by script or by prompt type

#### Scenario: Same kana not back to back
- **WHEN** a session contains two cards for the same kana and cards for other kana
- **THEN** the two cards of that kana are not presented one directly after the other

#### Scenario: Kana and words together
- **WHEN** kana cards and word cards are due
- **THEN** one session contains both, in a mixed order

#### Scenario: Same word not back to back
- **WHEN** a session contains both cards of a word and cards for other items
- **THEN** the two cards of that word are not presented one directly after the other

### Requirement: Feedback and grading
After each answer the system SHALL show whether it was correct. On a wrong answer to a kana card it SHALL show the correct answer and the kana's mnemonic and play its sound. After any answer to a word card it SHALL show the word with its reading, written form and meanings, and speak the word. The system SHALL grade the card automatically: a correct answer is rated good and a wrong answer is rated again. A card answered wrongly SHALL be shown again later in the same session until it is answered correctly.

#### Scenario: Correct answer
- **WHEN** the learner answers a card correctly
- **THEN** the card is rated good, rescheduled, and the session moves to the next card

#### Scenario: Wrong answer
- **WHEN** the learner answers a card wrongly
- **THEN** the correct answer and mnemonic are shown, the sound is played, the card is rated again, and it reappears later in the session

#### Scenario: Word answered correctly
- **WHEN** the learner answers a word card correctly
- **THEN** the word is spoken, the card is rated good and rescheduled

#### Scenario: Word answered wrongly
- **WHEN** the learner answers a word card wrongly
- **THEN** the word's reading, written form and meanings are shown, the word is spoken, the card is rated again, and it reappears later in the session
