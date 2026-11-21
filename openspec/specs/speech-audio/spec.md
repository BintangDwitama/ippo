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

### Requirement: Adjustable speaking speed
The system SHALL let the learner choose how fast kana are spoken, from three speeds: Normal, Slow and Very slow. Slow SHALL be the default. The chosen speed SHALL apply to every spoken kana, in lessons, reviews and the kana detail view, from the next sound played and without restarting the app. The settings screen SHALL offer a sample so the learner can hear the chosen speed.

The chosen speed SHALL be stored on the device. It SHALL NOT be written to a backup file, and importing a backup SHALL NOT change it.

#### Scenario: Default speed
- **WHEN** the learner has never chosen a speed and a kana is spoken
- **THEN** it is spoken at the Slow speed

#### Scenario: Choosing a speed
- **WHEN** the learner selects Very slow in settings
- **THEN** the sample is played at the Very slow speed
- **AND** the next kana spoken in a lesson or review is spoken at the Very slow speed

#### Scenario: Speed is remembered
- **WHEN** the learner selects Normal, closes the app and opens it again
- **THEN** kana are spoken at the Normal speed and settings shows Normal as selected

#### Scenario: Playing the sample
- **WHEN** the learner selects "Play a sample" in settings
- **THEN** a short sequence of kana is spoken at the selected speed

#### Scenario: No Japanese voice
- **WHEN** no Japanese voice is available on the device
- **THEN** the speed can still be chosen and the sample action is unavailable

#### Scenario: Importing a backup
- **WHEN** the learner has selected Very slow and imports a backup file
- **THEN** the speaking speed is still Very slow

