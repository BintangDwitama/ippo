# kana-lessons Specification

## Purpose
TBD - created by archiving change add-kana-trainer. Update Purpose after archive.
## Requirements
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

### Requirement: Mnemonic-first presentation
For each kana in a lesson, the system SHALL present the character, its romaji reading and its mnemonic together, and SHALL play its sound, before the learner is asked any question about it.

#### Scenario: Presenting a kana
- **WHEN** a kana is presented in a lesson
- **THEN** the character, reading and mnemonic are shown and the sound is played

#### Scenario: Replay the sound
- **WHEN** the learner taps the audio button on a presented kana
- **THEN** the sound is played again

### Requirement: Lesson check before completion
After all kana in a lesson have been presented, the system SHALL quiz the learner on each of them with multiple-choice questions. A kana answered wrongly SHALL be asked again until it has been answered correctly once.

#### Scenario: All answered correctly
- **WHEN** the learner answers every lesson question correctly
- **THEN** the lesson is completed

#### Scenario: Wrong answer repeats
- **WHEN** the learner answers a lesson question wrongly
- **THEN** the correct answer and mnemonic are shown, and that kana is asked again later in the same lesson

### Requirement: Completing a lesson creates review cards
When a lesson is completed, the system SHALL mark each of its kana as introduced and SHALL create the multiple-choice review cards for each. A lesson that is abandoned before completion SHALL introduce nothing.

#### Scenario: Lesson completed
- **WHEN** the learner completes a lesson of five kana
- **THEN** those five kana are marked as introduced, their multiple-choice cards exist and are scheduled, and they count against today's quota of new kana

#### Scenario: Lesson abandoned
- **WHEN** the learner leaves a lesson before completing it
- **THEN** no kana are marked as introduced and no cards are created

