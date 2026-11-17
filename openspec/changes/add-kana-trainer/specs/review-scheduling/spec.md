## ADDED Requirements

### Requirement: Generic card model
The system SHALL model a review card as a combination of a learning item and a prompt type, with its own scheduling state. The card model SHALL NOT be specific to kana, so that other item kinds can be added later without changing the scheduler.

#### Scenario: Several cards per item
- **WHEN** a kana has both a character-to-sound card and a sound-to-character card
- **THEN** each card has its own due date and scheduling state

#### Scenario: Scheduler is independent of item kind
- **WHEN** the scheduler computes the next due date of a card
- **THEN** it uses only the card's scheduling state, the rating and the current time

### Requirement: Spaced-repetition scheduling
The system SHALL schedule each card with a spaced-repetition algorithm targeting 90% retention. After each review, the system SHALL update the card's scheduling state and next due date according to the rating given.

#### Scenario: Correct answer lengthens the interval
- **WHEN** a card in the review state is rated as good
- **THEN** its next due date is later than its previous interval would have given

#### Scenario: Wrong answer brings the card back soon
- **WHEN** a card is rated as again
- **THEN** it becomes due again within the same day and its lapse count increases

#### Scenario: New card
- **WHEN** a card is created
- **THEN** it is due immediately and has no review history

### Requirement: Due cards
The system SHALL treat a card as due when its due date is at or before the current time, and SHALL be able to report the due cards and their count at any time.

#### Scenario: Card not yet due
- **WHEN** a card's due date is tomorrow
- **THEN** it is not included in today's due cards

#### Scenario: Overdue card
- **WHEN** a card's due date was three days ago
- **THEN** it is included in the due cards

### Requirement: Review history
The system SHALL record every review with the card, the time, the rating, whether the answer was correct, and the card's state before the review.

#### Scenario: Review recorded
- **WHEN** the learner answers a card
- **THEN** a review record is stored with the card, time, rating and correctness

#### Scenario: History survives restart
- **WHEN** the app is closed and reopened
- **THEN** all card states and review records are unchanged

### Requirement: Replaceable scheduling algorithm
The scheduling algorithm SHALL sit behind an interface so that it can be replaced without changes to the UI layer or the data layer.

#### Scenario: Alternative algorithm in tests
- **WHEN** a fake scheduler is supplied in place of the default one
- **THEN** review sessions run using the fake scheduler's due dates
