## MODIFIED Requirements

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

## ADDED Requirements

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
