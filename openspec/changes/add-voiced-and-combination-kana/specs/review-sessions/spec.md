## MODIFIED Requirements

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
