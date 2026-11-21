## ADDED Requirements

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
