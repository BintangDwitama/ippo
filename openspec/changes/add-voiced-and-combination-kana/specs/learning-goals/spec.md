## MODIFIED Requirements

### Requirement: One active SMART goal
The system SHALL let the learner set one active goal consisting of a target set of kana, a target accuracy, and a deadline in days. The target set SHALL be one of: basic hiragana (46), basic katakana (46), both basic sets (92), voiced and combination hiragana (58), voiced and combination katakana (58), or all kana (208). Each choice SHALL show how many kana it covers. On first launch the system SHALL offer the preset "all 46 hiragana at 90% accuracy within 14 days", which the learner can accept or adjust.

A goal set before voiced and combination kana existed SHALL keep covering exactly the kana it covered then.

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
- **WHEN** a learner with an active hiragana goal showing 10 of 46 introduced updates to a version with voiced and combination kana
- **THEN** the goal still shows 10 of 46 and its daily quota is unchanged

#### Scenario: Goal for voiced and combination kana
- **WHEN** the learner starts a goal for voiced and combination hiragana
- **THEN** the goal covers 58 kana and lessons offer only those kana

## ADDED Requirements

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
