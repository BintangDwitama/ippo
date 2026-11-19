# speech-audio Specification

## Purpose
TBD - created by archiving change add-kana-trainer. Update Purpose after archive.
## Requirements
### Requirement: Speak a kana
The system SHALL be able to play the spoken sound of any kana using a Japanese voice, without a network connection when the device has an offline Japanese voice installed.

#### Scenario: Play on request
- **WHEN** the learner taps the audio button for か
- **THEN** the sound "ka" is spoken in a Japanese voice

#### Scenario: New request interrupts
- **WHEN** a sound is playing and another kana's sound is requested
- **THEN** the first sound stops and the new one plays

### Requirement: Fallback when no Japanese voice is available
The system SHALL detect when no Japanese voice is available on the device. In that case it SHALL tell the learner once how to install one, SHALL keep lessons and reviews usable, and SHALL leave sound-to-character cards out of review sessions without rescheduling them.

#### Scenario: No Japanese voice
- **WHEN** the device has no Japanese text-to-speech voice
- **THEN** the learner sees a message explaining how to install one, and lessons and character-to-sound reviews still work

#### Scenario: Listening cards skipped
- **WHEN** a session is built while no Japanese voice is available
- **THEN** sound-to-character cards are left out of the session and remain due

### Requirement: Replaceable audio source
Audio playback SHALL sit behind a repository interface so that device text-to-speech can be replaced by bundled recordings without changes to the UI layer.

#### Scenario: Fake audio in tests
- **WHEN** a fake speech repository is supplied
- **THEN** lessons and review sessions run without calling the device's text-to-speech

