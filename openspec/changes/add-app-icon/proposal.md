## Why

The app still has the default Flutter icon and a blank white launch screen. On the home screen it is indistinguishable from any unfinished app, and at night it opens with a white flash before the dark theme appears. An app meant to be opened every day deserves to be recognisable and to open calmly.

## What Changes

- **App icon**: the character 歩 ("step", the second half of 一歩) in the app's kana font, white on the Daylight blue. Built as an Android adaptive icon (background layer and foreground mark, safe under any launcher's shape), with a one-colour layer so Android 13 and later can tint it to match the wallpaper, and plain icons for older Android.
- **Launch screen**: the icon centred on a plain background, light or dark, replacing the blank white screen.
- **The launch screen follows the appearance chosen in Ippo** on Android 12 and later: light for Daylight and Paper, dark for Night, and the phone's own mode for Automatic. The app tells the system which to use whenever the setting changes, so the next launch already matches.
- **The icon artwork is generated**, not hand-drawn: a small tool renders it from the bundled font, so it can be regenerated when the character or colour changes.

Decided with the owner, and not part of this change:

- The icon does not change with the theme. Android can only fake that by swapping launcher entries, which removes the icon from where the learner placed it.
- Paper gets the light launch screen, not its own cream one. The system knows only light and dark before the app starts.
- iOS icon and launch screen. The app is Android first.

## Capabilities

### New Capabilities

- `app-identity`: the app's icon and its launch screen, and how the launch screen follows the chosen appearance.

### Modified Capabilities

None. The appearance setting itself is unchanged; this change only reports it to the system.

## Impact

- **Android resources**: new adaptive icon files, replaced launcher images at five densities, launch backgrounds and colours for light and dark, launch themes for Android 12 and later.
- **Android code**: `MainActivity` gains a small method channel that sets the app's night mode through the system (Android 12 and later; a no-op before).
- **Dart**: a `LaunchAppearanceRepository` interface with a method-channel implementation and a fake; called at start and when the appearance setting changes.
- **Tool**: `tool/icon/` renders the icon images from `assets/fonts/KleeOne-SemiBold.ttf` (SIL Open Font License, which permits this use).
- **Side effect to verify**: setting the app's night mode changes the brightness Flutter reports for the platform. The themes Daylight, Night and Paper are chosen explicitly and must be unaffected; Automatic must keep following the phone.
- No new package dependencies. No data, backup or permission changes.
