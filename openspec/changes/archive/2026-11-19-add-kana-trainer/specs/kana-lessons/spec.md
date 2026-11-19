## ADDED Requirements

### Requirement: Lessons introduce kana in small batches
The system SHALL introduce new kana in batches of at most five, in gojūon order within a script. Hiragana SHALL be introduced before katakana. A lesson SHALL only be offered while the learner's daily quota of new kana has not been used up.

#### Scenario: First lesson
- **WHEN** the learner starts their first lesson
- **THEN** the lesson contains あ, い, う, え, お

#### Scenario: Next lesson continues the order
- **WHEN** the learner has been introduced to the first five hiragana and starts another lesson
- **THEN** the lesson contains the next five hiragana in gojūon order

#### Scenario: Quota used up
- **WHEN** the learner has already been introduced to their daily quota of new kana today
- **THEN** no further lesson is offered until the next day

#### Scenario: Katakana after hiragana
- **WHEN** all 46 hiragana have been introduced and the learner starts a lesson
- **THEN** the lesson contains the first katakana

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
