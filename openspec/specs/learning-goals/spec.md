# learning-goals Specification

## Purpose
The learner's goal and daily rhythm: one active goal with a deadline and target accuracy, the daily quota of new kana it implies, the daily review cap, progress, the streak and the daily reminder.

## Requirements
### Requirement: One active SMART goal
The system SHALL let the learner set one active goal consisting of a target set of kana, a target accuracy, and a deadline in days. The target set SHALL be one of: basic hiragana (46), basic katakana (46), both basic sets (92), voiced and combination hiragana with the hiragana mark (59), voiced and combination katakana with the katakana marks (60), or all kana (211). Each choice SHALL show how many kana it covers. On first launch the system SHALL offer the preset "all 46 hiragana at 90% accuracy within 14 days", which the learner can accept or adjust.

A goal for basic kana set before voiced and combination kana existed SHALL keep covering exactly the kana it covered then.

#### Scenario: Accept the preset
- **WHEN** the learner accepts the preset on first launch
- **THEN** an active goal exists for 46 hiragana, 90% accuracy, with a deadline 14 days from today

#### Scenario: Adjust the goal
- **WHEN** the learner changes the deadline to 21 days and saves
- **THEN** the active goal has a deadline 21 days from the day it was created

#### Scenario: Invalid goal rejected
- **WHEN** the learner enters a deadline of zero days or an accuracy outside 50% to 100%
- **THEN** the goal is not saved and the reason is shown

#### Scenario: Existing goal after an update
- **WHEN** a learner with an active hiragana goal showing 10 of 46 introduced updates to a version with voiced and combination kana and marks
- **THEN** the goal still shows 10 of 46 and its daily quota is unchanged

#### Scenario: Goal for voiced and combination kana
- **WHEN** the learner starts a goal for voiced and combination hiragana
- **THEN** the goal covers 59 kana, including っ, and lessons offer only those kana

### Requirement: Daily quota of new kana
The system SHALL derive a daily quota of new kana from the active goal: the kana in the goal not yet introduced, divided by the days remaining, rounded up, and never less than one while any remain. The quota SHALL be recalculated each day.

#### Scenario: Even pace
- **WHEN** 46 kana remain and 14 days remain
- **THEN** today's quota is 4 new kana

#### Scenario: Falling behind raises the quota
- **WHEN** 40 kana remain and 5 days remain
- **THEN** today's quota is 8 new kana

#### Scenario: Everything introduced
- **WHEN** no kana in the goal remain to be introduced
- **THEN** today's quota is zero

### Requirement: Daily review cap
The system SHALL limit the number of reviews offered per day to a cap, 100 by default, which the learner can change. Cards beyond the cap SHALL stay due for the following days.

#### Scenario: Backlog after a break
- **WHEN** the learner returns after a week with 300 cards due and a cap of 100
- **THEN** at most 100 reviews are offered today and the rest remain due

### Requirement: Goal progress
The system SHALL show the progress of the active goal: kana introduced out of the target, current accuracy over the goal's kana for the last 7 days, days remaining, and whether the goal has been achieved. The goal is achieved when every kana in the target is introduced and the accuracy is at or above the target.

#### Scenario: Progress shown
- **WHEN** 20 of 46 hiragana have been introduced, accuracy is 85% and 8 days remain
- **THEN** the home screen shows 20 of 46, 85%, and 8 days remaining

#### Scenario: Goal achieved
- **WHEN** all 46 hiragana are introduced and accuracy over the last 7 days is 92% against a 90% target
- **THEN** the goal is shown as achieved and the learner is offered a new goal

#### Scenario: Deadline passed
- **WHEN** the deadline passes without the goal being achieved
- **THEN** the goal is shown as missed and the learner is offered to extend it or set a new one

### Requirement: Streak
The system SHALL count a streak of consecutive days on which the learner completed at least one lesson or reviewed at least one card.

#### Scenario: Streak continues
- **WHEN** the learner studied yesterday with a streak of 4 and reviews a card today
- **THEN** the streak is 5

#### Scenario: Streak broken
- **WHEN** the learner did not study yesterday and opens the app today
- **THEN** the streak is 0 until they study today

### Requirement: Daily reminder
The system SHALL let the learner turn on a daily reminder notification at a time they choose. The reminder SHALL work without a network connection. If notification permission is refused, the system SHALL keep working without reminders.

#### Scenario: Reminder enabled
- **WHEN** the learner enables the reminder for 19:00 and grants notification permission
- **THEN** a notification is delivered at 19:00 each day

#### Scenario: Permission refused
- **WHEN** the learner refuses notification permission
- **THEN** the reminder is shown as off and the rest of the app works normally

#### Scenario: Reminder disabled
- **WHEN** the learner turns the reminder off
- **THEN** no further reminder notifications are delivered

### Requirement: Reminder follows the stored setting
When the app starts, and after learning data is restored from a backup, the system SHALL make the daily reminder match the stored setting. If a reminder time is stored and notifications are allowed, the reminder SHALL be scheduled for that time. If a reminder time is stored and notifications are not allowed, the reminder SHALL be shown as off. The system SHALL NOT ask for notification permission at start-up or during a restore.

#### Scenario: Restored on a phone that allows notifications
- **WHEN** a backup with the reminder set to 19:00 is restored on a phone where notifications are allowed for the app
- **THEN** a notification is delivered at 19:00 each day and settings shows the reminder on at 19:00

#### Scenario: Restored on a phone that does not allow notifications
- **WHEN** a backup with the reminder set to 19:00 is restored on a phone where notifications are not allowed for the app
- **THEN** settings shows the reminder as off and no permission request appears

#### Scenario: Backup without a reminder
- **WHEN** a backup with the reminder off is restored on a phone that had a reminder scheduled
- **THEN** no reminder notification is delivered and settings shows the reminder as off

### Requirement: Next goal is suggested
When a goal has been achieved and the learner sets a new one, the system SHALL preselect the next step of the teaching path: voiced and combination hiragana after basic hiragana, basic katakana after those, and voiced and combination katakana after basic katakana. The learner SHALL be able to choose any other target set.

#### Scenario: After basic hiragana
- **WHEN** the learner has achieved a basic hiragana goal and opens the goal screen
- **THEN** voiced and combination hiragana is preselected for the new goal

#### Scenario: After all hiragana
- **WHEN** the learner has achieved a voiced and combination hiragana goal and opens the goal screen
- **THEN** basic katakana is preselected for the new goal

#### Scenario: Choosing differently
- **WHEN** basic katakana is preselected and the learner selects all kana and saves
- **THEN** the new goal covers all 208 kana

