# review-sessions Specification

## Purpose
TBD - created by archiving change add-kana-trainer. Update Purpose after archive.
## Requirements
### Requirement: Review session from due cards
The system SHALL let the learner start a review session whenever at least one card is due. The session SHALL contain due cards, most overdue first, up to the remaining daily review cap.

#### Scenario: Cards due
- **WHEN** 12 cards are due and the remaining daily review cap is 100
- **THEN** a session of 12 cards can be started

#### Scenario: Nothing due
- **WHEN** no cards are due
- **THEN** no session can be started and the learner is told when the next card is due

#### Scenario: Cap reached
- **WHEN** 150 cards are due and the remaining daily review cap is 100
- **THEN** the session contains the 100 most overdue cards

### Requirement: Interleaved ordering
Within a session, the system SHALL mix scripts and prompt types instead of grouping them, and SHALL NOT show two cards of the same kana consecutively unless no other card remains.

#### Scenario: Mixed session
- **WHEN** a session contains hiragana and katakana cards of several prompt types
- **THEN** the cards are presented in a mixed order, not grouped by script or by prompt type

#### Scenario: Same kana not back to back
- **WHEN** a session contains two cards for the same kana and cards for other kana
- **THEN** the two cards of that kana are not presented one directly after the other

### Requirement: Prompt types
The system SHALL support these prompt types for kana:
- character to sound, multiple choice: show the character, choose the romaji from four options;
- sound to character, multiple choice: play the sound, choose the character from four options;
- character to sound, typed: show the character, type the romaji.

Wrong options in multiple-choice prompts SHALL be kana from the same script as the correct answer, with a different reading, and SHALL be kana the learner has already been introduced to whenever at least three such kana exist. Among those, the system SHALL prefer kana that are easy to confuse with the correct answer, in this order: its voiced, half-voiced or unvoiced partners; kana that look like it; kana from its row; then any other. The choice within each of these SHALL vary between presentations.

#### Scenario: Character to sound, multiple choice
- **WHEN** a character-to-sound multiple-choice card for か is presented
- **THEN** か is shown with four romaji options, exactly one of which is "ka"

#### Scenario: Sound to character
- **WHEN** a sound-to-character card is presented
- **THEN** the sound is played, no romaji is shown, and four characters from the same script are offered

#### Scenario: Typed answer
- **WHEN** a typed card for し is presented and the learner types "shi"
- **THEN** the answer is accepted as correct

#### Scenario: Partner offered as a wrong option
- **WHEN** a multiple-choice card for が is presented and か and the rest of the が row have been introduced
- **THEN** "ka" is one of the options and the other two wrong options are from the が row

#### Scenario: Look-alike offered as a wrong option
- **WHEN** a multiple-choice card for ぬ is presented and め has been introduced
- **THEN** め is one of the options

#### Scenario: Only kana the learner has met
- **WHEN** a multiple-choice card for か is presented and が has not been introduced
- **THEN** "ga" is not among the options

#### Scenario: Same reading is never a wrong option
- **WHEN** a sound-to-character card for じ is presented and ぢ has been introduced
- **THEN** ぢ is not among the options

### Requirement: Typed answer checking
For typed prompts, the system SHALL compare answers ignoring letter case and surrounding whitespace, and SHALL accept the common alternative romanisations of a kana (for example "si" for し, "tu" for つ, "hu" for ふ, "ti" for ち).

#### Scenario: Case and whitespace ignored
- **WHEN** the learner types " KA " for か
- **THEN** the answer is accepted as correct

#### Scenario: Alternative romanisation
- **WHEN** the learner types "tu" for つ
- **THEN** the answer is accepted as correct

#### Scenario: Wrong answer
- **WHEN** the learner types "ki" for か
- **THEN** the answer is marked wrong

### Requirement: Feedback and grading
After each answer the system SHALL show whether it was correct. On a wrong answer it SHALL show the correct answer and the kana's mnemonic and play its sound. The system SHALL grade the card automatically: a correct answer is rated good and a wrong answer is rated again. A card answered wrongly SHALL be shown again later in the same session until it is answered correctly.

#### Scenario: Correct answer
- **WHEN** the learner answers a card correctly
- **THEN** the card is rated good, rescheduled, and the session moves to the next card

#### Scenario: Wrong answer
- **WHEN** the learner answers a card wrongly
- **THEN** the correct answer and mnemonic are shown, the sound is played, the card is rated again, and it reappears later in the session

### Requirement: Graduation to typed answers
When the character-to-sound multiple-choice card of a kana has been answered correctly in three consecutive reviews, the system SHALL create the typed card for that kana. The multiple-choice cards SHALL remain scheduled.

#### Scenario: Third consecutive correct answer
- **WHEN** the learner answers a kana's character-to-sound multiple-choice card correctly for the third review in a row
- **THEN** a typed card for that kana is created and scheduled

#### Scenario: Streak broken
- **WHEN** the learner answers that card wrongly after two correct reviews
- **THEN** the consecutive count restarts and no typed card is created

### Requirement: Session summary and interruption
When a session ends, the system SHALL show the number of cards reviewed and the accuracy. Each answer SHALL be saved as it is given, so that leaving a session early loses nothing already answered.

#### Scenario: Session finished
- **WHEN** the learner answers the last card of a session
- **THEN** a summary shows the number of cards reviewed and the percentage answered correctly at first attempt

#### Scenario: Session left early
- **WHEN** the learner leaves a session after answering 5 of 12 cards
- **THEN** those 5 reviews are saved and the remaining 7 cards are still due

