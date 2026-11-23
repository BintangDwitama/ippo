## ADDED Requirements

### Requirement: Speak a word
The system SHALL be able to speak any word of the word list using a Japanese voice, at the learner's chosen speaking speed, without a network connection when the device has an offline Japanese voice installed. The word SHALL be spoken from its reading in kana, so that the pronunciation does not depend on how the voice reads kanji.

#### Scenario: Play on request
- **WHEN** the learner taps the audio control for the word 雨
- **THEN** "ame" is spoken in a Japanese voice

#### Scenario: Speed setting applies
- **WHEN** the speaking speed is set to Very slow and a word is spoken
- **THEN** it is spoken at that speed

#### Scenario: New request interrupts
- **WHEN** a word is being spoken and another sound is requested
- **THEN** the first stops and the new one plays
