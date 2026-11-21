## MODIFIED Requirements

### Requirement: Lessons introduce kana in small batches
The system SHALL introduce new kana in lessons made of whole rows, of at most six kana. A lesson SHALL start with the kana not yet introduced from the next row in teaching order, and SHALL add following rows of the same script and group while the lesson stays at six kana or fewer. A lesson SHALL NOT mix scripts or groups.

The teaching order SHALL be: basic hiragana, voiced hiragana, combination hiragana, then basic, voiced and combination katakana. A lesson SHALL only be offered while the learner's daily quota of new kana has not been used up.

#### Scenario: First lesson
- **WHEN** the learner starts their first lesson
- **THEN** the lesson contains あ, い, う, え, お

#### Scenario: Next lesson continues the order
- **WHEN** the learner has been introduced to the first five hiragana and starts another lesson
- **THEN** the lesson contains か, き, く, け, こ

#### Scenario: A short row is not merged with a full one
- **WHEN** every basic hiragana before や has been introduced and the learner starts a lesson
- **THEN** the lesson contains や, ゆ, よ and nothing else

#### Scenario: Short rows are taught together
- **WHEN** every basic hiragana before わ has been introduced and the learner starts a lesson
- **THEN** the lesson contains わ, を, ん

#### Scenario: Combination rows are paired
- **WHEN** all basic and voiced hiragana have been introduced and the learner starts a lesson
- **THEN** the lesson contains きゃ, きゅ, きょ, しゃ, しゅ, しょ

#### Scenario: Voiced kana follow basic kana of the same script
- **WHEN** all 46 basic hiragana have been introduced, no goal is active, and the learner starts a lesson
- **THEN** the lesson contains が, ぎ, ぐ, げ, ご

#### Scenario: Quota used up
- **WHEN** the learner has already been introduced to their daily quota of new kana today
- **THEN** no further lesson is offered until the next day

#### Scenario: Katakana after hiragana
- **WHEN** all 104 hiragana have been introduced, no goal is active, and the learner starts a lesson
- **THEN** the lesson contains ア, イ, ウ, エ, オ

#### Scenario: A goal limits lessons to its kana
- **WHEN** the active goal is basic hiragana, all 46 have been introduced, and the learner looks for a lesson
- **THEN** no lesson is offered
