## ADDED Requirements

### Requirement: App icon
The app SHALL have its own launcher icon: the character 歩 in the app's kana font, in white on the Daylight theme's blue. The mark SHALL remain whole under every icon shape a launcher may apply.

#### Scenario: Icon on the home screen
- **WHEN** the app is installed
- **THEN** the launcher shows the 歩 icon with the name Ippo, not the default Flutter icon

#### Scenario: Any launcher shape
- **WHEN** a launcher crops icons to a circle, a rounded square or a squircle
- **THEN** no part of the character is cut off

#### Scenario: Older Android
- **WHEN** the app is installed on an Android version without adaptive icons
- **THEN** the launcher shows the same mark on the same blue

### Requirement: Icon can be tinted by the system
The icon SHALL provide a one-colour version of its mark so that, where the system offers themed icons, the icon is tinted to match the learner's wallpaper.

#### Scenario: Themed icons turned on
- **WHEN** the learner turns on themed icons on a phone that supports them
- **THEN** the Ippo icon is drawn in the system's tint with the 歩 mark visible

### Requirement: Launch screen
While the app starts, the screen SHALL show the app's icon centred on a plain background, light or dark, and SHALL NOT show a blank white screen in dark mode.

#### Scenario: Light launch
- **WHEN** the app is opened and the launch screen is light
- **THEN** the icon is shown on a light background until the app appears

#### Scenario: Dark launch
- **WHEN** the app is opened and the launch screen is dark
- **THEN** the icon is shown on a dark background, with no white flash before the app appears

### Requirement: Launch screen follows the chosen appearance
On Android 12 and later the launch screen SHALL match the appearance chosen in the app: light when Daylight or Paper is chosen, dark when Night is chosen, and the phone's own light or dark mode when Automatic is chosen. A change of the setting SHALL take effect from the next launch. On earlier Android versions the launch screen SHALL follow the phone's mode.

#### Scenario: Night chosen on a light phone
- **WHEN** the learner has chosen Night, the phone is in light mode, and the app is opened
- **THEN** the launch screen is dark

#### Scenario: Daylight chosen on a dark phone
- **WHEN** the learner has chosen Daylight, the phone is in dark mode, and the app is opened
- **THEN** the launch screen is light

#### Scenario: Paper chosen
- **WHEN** the learner has chosen Paper and the app is opened
- **THEN** the launch screen is light

#### Scenario: Automatic
- **WHEN** the learner has chosen Automatic and the app is opened with the phone in dark mode
- **THEN** the launch screen is dark

#### Scenario: Back to Automatic
- **WHEN** the learner changes from Night to Automatic and next opens the app with the phone in light mode
- **THEN** the launch screen is light

#### Scenario: Setting restored from a backup
- **WHEN** an imported backup changes the appearance to Night
- **THEN** the next launch screen is dark

### Requirement: Reporting the appearance does not change the app's look
Telling the system which launch screen to use SHALL NOT change which theme the app shows. With Automatic chosen, the app SHALL keep following the phone's light or dark mode.

#### Scenario: Automatic still follows the phone
- **WHEN** Automatic is chosen and the phone switches from light to dark mode
- **THEN** the app switches from Daylight to Night

#### Scenario: Explicit theme unaffected
- **WHEN** Paper is chosen and the phone is in dark mode
- **THEN** the app shows Paper

### Requirement: Icon artwork is reproducible
The icon images SHALL be produced by a tool in the repository from the bundled font and stated colours, so that running the tool again produces the same images.

#### Scenario: Regenerating
- **WHEN** the tool is run without changing its inputs
- **THEN** the icon images are identical to the committed ones
