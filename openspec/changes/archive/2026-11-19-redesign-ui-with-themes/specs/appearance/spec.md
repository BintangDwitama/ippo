## ADDED Requirements

### Requirement: Selectable themes
The app SHALL provide three visual themes: Daylight (light), Night (dark) and Paper (light). The settings screen SHALL offer an Appearance choice with exactly four options: Automatic, Daylight, Night and Paper, and SHALL indicate which one is selected.

#### Scenario: Options are listed
- **WHEN** the learner opens the settings screen
- **THEN** the Appearance choice shows Automatic, Daylight, Night and Paper, with the current one marked

#### Scenario: Choosing a fixed theme
- **WHEN** the learner selects Paper
- **THEN** the app is shown in the Paper theme regardless of the device's light or dark setting

### Requirement: Automatic appearance follows the device
When Appearance is Automatic, the app SHALL use Daylight while the device is in light mode and Night while the device is in dark mode. Automatic SHALL be the default for a learner who has never chosen.

#### Scenario: First launch
- **WHEN** the app is launched for the first time on a device in dark mode
- **THEN** the app is shown in the Night theme and the Appearance choice shows Automatic

#### Scenario: Device mode changes
- **WHEN** Appearance is Automatic and the device switches from light mode to dark mode
- **THEN** the app changes from Daylight to Night without being restarted

### Requirement: Theme changes apply immediately
A change to the Appearance choice SHALL take effect on all screens without restarting the app and without losing the learner's place.

#### Scenario: Change from settings
- **WHEN** the learner selects Night on the settings screen
- **THEN** the settings screen is redrawn in the Night theme at once
- **AND** returning to the home screen shows it in the Night theme

### Requirement: Appearance choice is remembered
The Appearance choice SHALL be stored on the device and restored on the next launch. The first frame shown at launch SHALL already use the stored choice. A stored value the app does not recognise SHALL be treated as Automatic.

#### Scenario: Restart keeps the choice
- **WHEN** the learner selects Paper, closes the app and opens it again
- **THEN** the app opens in the Paper theme with no visible flash of another theme

#### Scenario: Unrecognised stored value
- **WHEN** the stored Appearance value does not match any option
- **THEN** the app behaves as if Automatic were selected

### Requirement: Themes share one layout
A theme SHALL change only visual treatment: colours, fonts, corner shapes, and whether surfaces are filled or outlined. Every screen SHALL present the same content, the same wording, the same controls and the same arrangement in every theme.

#### Scenario: Same controls in every theme
- **WHEN** the home screen is shown in Daylight, then Night, then Paper with the same learning state
- **THEN** the same texts and the same buttons are present in the same order each time

### Requirement: Kana are shown in a textbook-style font
Kana characters SHALL be drawn with a bundled textbook-style Japanese font in every theme, on every screen where they appear. Fonts SHALL be bundled with the app and SHALL NOT be downloaded.

#### Scenario: Kana offline on first launch
- **WHEN** the app is launched for the first time with no network connection
- **THEN** kana are drawn in the bundled textbook-style font

#### Scenario: Same kana font across themes
- **WHEN** the same kana is shown in Daylight, Night and Paper
- **THEN** its letterform is the same in all three

### Requirement: Legible in every theme
In every theme, text SHALL have a contrast ratio of at least 4.5:1 against the surface it sits on. Controls the learner taps SHALL be at least 44 by 44 logical pixels. Screens SHALL remain usable, with no clipped or overlapping content, on a 360 by 640 logical pixel screen and with the system text size increased to 130%.

#### Scenario: Contrast of theme colours
- **WHEN** the text and surface colour pairs defined by each theme are measured
- **THEN** every pair has a contrast ratio of at least 4.5:1

#### Scenario: Small screen with large text
- **WHEN** the home screen, a review question and the kana grid are shown at 360 by 640 logical pixels with text scaled to 130%, in each theme
- **THEN** no content is clipped or overlaps

### Requirement: Answer feedback does not rely on colour alone
Feedback after an answer SHALL distinguish correct from wrong with an icon and a text label in addition to colour, in every theme. Decorative motion SHALL be omitted when the device requests reduced motion.

#### Scenario: Wrong answer
- **WHEN** the learner answers a review question wrongly
- **THEN** the feedback shows a wrong-answer icon, a text label saying the answer was not correct, and the correct answer in text

#### Scenario: Reduced motion
- **WHEN** the device has animations turned off and the learner answers a question
- **THEN** the feedback appears without animation
