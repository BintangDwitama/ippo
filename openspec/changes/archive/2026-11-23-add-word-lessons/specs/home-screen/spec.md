## MODIFIED Requirements

### Requirement: One primary action
The home screen SHALL present exactly one primary action, chosen in this order: start a review when cards are due and the daily review cap is not reached; otherwise start a kana lesson when one is available; otherwise start a word lesson when one is available; otherwise no action, with a rest message. The primary action SHALL be the most prominent element on the screen.

#### Scenario: Cards are due
- **WHEN** 12 cards are due and a lesson is also available
- **THEN** the primary action is "Start review" and it states that 12 cards are due

#### Scenario: Nothing due, lesson available
- **WHEN** no cards are due and a lesson of 5 kana is available
- **THEN** the primary action is "Start lesson"

#### Scenario: Only a word lesson is available
- **WHEN** no cards are due, today's kana lesson is done and a word lesson is available
- **THEN** the primary action starts the word lesson

#### Scenario: Nothing to do
- **WHEN** no cards are due and no kana or word lesson is available today
- **THEN** no primary action button is shown
- **AND** the screen states when the next card is due, or that the daily review limit has been reached

## ADDED Requirements

### Requirement: Word lesson preview
When a word lesson is available, the home screen SHALL show the words it will introduce, as readings, and how many there are. When the word lesson is not the primary action, it SHALL be offered as a secondary action below the review and kana lesson actions.

#### Scenario: Word lesson shown as secondary
- **WHEN** a kana lesson and a word lesson of five words are both available
- **THEN** the screen shows the five readings and a secondary action to start the word lesson, below the kana lesson

#### Scenario: No word lesson today
- **WHEN** today's quota of new words is used up, or no unlearned word is readable yet
- **THEN** no word lesson preview or action is shown
