# home-screen Specification

## Purpose
What the home screen puts in front of the learner: one primary action, the next lesson, and the goal and streak summary.
## Requirements
### Requirement: One primary action
The home screen SHALL present exactly one primary action, chosen in this order: start a review when cards are due and the daily review cap is not reached; otherwise start a lesson when one is available; otherwise no action, with a rest message. The primary action SHALL be the most prominent element on the screen.

#### Scenario: Cards are due
- **WHEN** 12 cards are due and a lesson is also available
- **THEN** the primary action is "Start review" and it states that 12 cards are due

#### Scenario: Nothing due, lesson available
- **WHEN** no cards are due and a lesson of 5 kana is available
- **THEN** the primary action is "Start lesson"

#### Scenario: Nothing to do
- **WHEN** no cards are due and no lesson is available today
- **THEN** no primary action button is shown
- **AND** the screen states when the next card is due, or that the daily review limit has been reached

### Requirement: Next lesson preview
When a lesson is available, the home screen SHALL show the kana that the lesson will introduce, as characters. When reviews are the primary action, the lesson SHALL be offered as a secondary action below it.

#### Scenario: Lesson shown as secondary
- **WHEN** cards are due and the next lesson introduces た, ち, つ, て and と
- **THEN** the screen shows those five characters and a secondary "Start lesson" action below the review action

#### Scenario: No lesson today
- **WHEN** the daily quota of new kana is used up
- **THEN** no lesson preview or lesson action is shown

### Requirement: Goal and streak summary
The home screen SHALL show a compact summary of the active goal (kana introduced out of the target, days remaining, and accuracy against the target) and the current streak in days. Selecting the goal summary SHALL open the goal screen. When there is no goal, the first-launch goal setup SHALL be shown in place of the summary.

#### Scenario: Active goal
- **WHEN** the learner has introduced 15 of 46 hiragana with 11 days left and a 3-day streak
- **THEN** the summary shows 15 of 46, 11 days left, the accuracy and its target, and a streak of 3 days

#### Scenario: Opening the goal
- **WHEN** the learner selects the goal summary
- **THEN** the goal screen opens

#### Scenario: Goal ended
- **WHEN** the goal has been achieved or its deadline has passed
- **THEN** the summary says so and invites the learner to set the next goal

### Requirement: Access to the kana grid and settings
The home screen SHALL give direct access to the kana grid and to settings.

#### Scenario: Open settings
- **WHEN** the learner selects the settings control on the home screen
- **THEN** the settings screen opens

