# speech-audio Specification

## Purpose
Spoken Japanese in the app: speaking a kana or a word with the phone's Japanese voice, what happens when no voice is installed, the adjustable speaking speed, and an audio source that can be replaced.
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
The system SHALL tell apart three states of the device's Japanese voice: ready, when a voice is downloaded and works without a network connection; online only, when a Japanese voice exists but none is downloaded; and missing, when there is no Japanese voice.

When the voice is missing the system SHALL tell the learner once how to get one, SHALL keep lessons and reviews usable, and SHALL leave sound-to-character cards out of review sessions without rescheduling them.

When the voice is online only the system SHALL tell the learner once that sound may be late, or absent without an internet connection, and that downloading the voice fixes it. Sound SHALL still be played and no card SHALL be left out.

In both states the message SHALL offer an action that opens the device's screen for downloading voice data. Where the device cannot open that screen, the message SHALL describe where to find it in the device's settings. The settings screen SHALL always show the current state, with the same action when the voice is not ready.

#### Scenario: No Japanese voice
- **WHEN** the device has no Japanese text-to-speech voice
- **THEN** the learner sees a message explaining how to install one, and lessons and character-to-sound reviews still work

#### Scenario: Listening cards skipped
- **WHEN** a session is built while no Japanese voice is available
- **THEN** sound-to-character cards are left out of the session and remain due

#### Scenario: Voice not downloaded
- **WHEN** the device has a Japanese voice that needs a network connection and none that is downloaded
- **THEN** the learner sees a message that sound may be late or missing without internet, with an action to download the voice
- **AND** sound is still played and listening cards stay in review sessions

#### Scenario: Voice ready
- **WHEN** the device has a downloaded Japanese voice
- **THEN** no message about the voice is shown

#### Scenario: Open the download screen
- **WHEN** the learner chooses the download action
- **THEN** the device's screen for installing voice data opens

#### Scenario: Download screen cannot be opened
- **WHEN** the learner chooses the download action and the device has no such screen
- **THEN** the learner is told where to find voice data in the device's settings

#### Scenario: Message dismissed
- **WHEN** the learner dismisses the message on the home screen
- **THEN** it is not shown there again, and the settings screen still shows the state of the voice

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

### Requirement: Voice state is rechecked
The system SHALL check the state of the Japanese voice again whenever the home screen or the settings screen is shown, so that a voice downloaded while the app is open is recognised without restarting the app.

#### Scenario: Voice downloaded while the app is open
- **WHEN** the learner downloads the Japanese voice from the screen the app opened and returns to the app
- **THEN** the message about the voice is gone and the settings screen shows the voice as ready

#### Scenario: Listening cards return
- **WHEN** a missing voice has been installed and the learner starts a review
- **THEN** due sound-to-character cards are included

### Requirement: A downloaded voice is preferred
When the device has a downloaded Japanese voice, the system SHALL speak with a downloaded voice, not with one that needs a network connection.

#### Scenario: Both kinds of voice exist
- **WHEN** the device offers a Japanese voice that needs the network and one that is downloaded
- **THEN** sound is produced with the downloaded voice

#### Scenario: Only an online voice
- **WHEN** the device offers only a Japanese voice that needs the network
- **THEN** that voice is used

### Requirement: The first sound is not delayed by setup
The system SHALL prepare the speech engine when the app starts, so that the first sound of a session does not wait for the engine to be set up. Preparing SHALL NOT delay the app's first screen and SHALL NOT fail the app when no voice is available.

#### Scenario: First sound of a session
- **WHEN** the learner opens a lesson shortly after starting the app
- **THEN** the engine has already been given its language and voice before the first sound is requested

#### Scenario: No voice at start
- **WHEN** the app starts on a device with no Japanese voice
- **THEN** the app starts normally

