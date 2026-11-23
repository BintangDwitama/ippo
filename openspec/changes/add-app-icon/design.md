## Context

The Android project is as Flutter generated it: `mipmap-*/ic_launcher.png` at five densities, `LaunchTheme` with a white (`values`) or black (`values-night`) window background, and a `MainActivity` with no code. `minSdk` is 24. The owner's phone runs Android 16.

The app has three themes and an appearance setting (Automatic, Daylight, Night, Paper) stored in the settings table and exposed as a stream that `AppViewModel` already listens to. The app title on the home screen is 一歩 in Klee One.

On Android 12 and later the system draws the launch screen itself, before any app code runs: the launcher icon centred on `windowSplashScreenBackground`. Which variant it draws depends on the night mode the system holds for the app.

Decisions made with the owner: one icon that does not change with the theme; a tintable version; the launch screen follows the Ippo setting for light and dark; Paper accepts the light screen.

## Goals / Non-Goals

**Goals:**

- A recognisable icon that is safe under every launcher shape.
- No white flash when the app is used in Night.
- The launch screen matches the chosen appearance without the learner doing anything.

**Non-Goals:**

- An icon that changes with the theme, or an exact Paper launch screen (both need launcher-entry switching; declined).
- An animated launch screen, or keeping it up while the app loads.
- iOS, web or desktop icons.
- Changing the in-app themes.

## Decisions

### 1. The mark

歩 from `assets/fonts/KleeOne-SemiBold.ttf`, white (`#FFFFFF`) on the Daylight blue (`#2459E0`). One character, because two (一歩) halve in size inside the adaptive icon's safe zone and blur at small sizes. Klee One, because it is the lettering the app already uses for its name and its kana.

The adaptive icon canvas is 108 × 108 dp, of which only the central 66 dp circle is guaranteed visible. The character is sized so its ink fits within about 56 dp, leaving margin inside the safe circle, and is centred by its ink bounds, not its font metrics, since a glyph's box is rarely centred on its ink.

### 2. Icon files

- `mipmap-anydpi-v26/ic_launcher.xml`: `<adaptive-icon>` with `background` a colour resource, `foreground` an image, and `monochrome` the same image (the system uses only its alpha).
- `mipmap-*/ic_launcher_foreground.png` at five densities (108 dp: 108, 162, 216, 324, 432 px), white mark on transparent.
- `mipmap-*/ic_launcher.png` at five densities (48 dp) for Android 7: the mark on a blue rounded square, replacing the Flutter images.
- `values/colors.xml`: `ic_launcher_background`.

Images, not a vector drawable. A vector would be a single crisp file, but turning a font glyph into path data needs a font-parsing library the project does not have; rendering to images needs only Flutter.

### 3. Generating the artwork

`tool/icon/generate_icon_test.dart`, run with `flutter test tool/icon/generate_icon_test.dart`. It loads the bundled font, lays out the character with Flutter's own text engine, draws each image on a canvas and writes the PNG files into `android/app/src/main/res/`. It is written as a test file only because `flutter test` is the simplest way to get Flutter's text and image engine without a device; it is not part of the normal test run (it lives under `tool/`, not `test/`).

A normal test (`test/tool/icon_files_test.dart`) checks the committed files: each exists at the expected pixel size, the foreground has transparent corners and ink only inside the safe circle, and the adaptive icon XML names all three layers.

Alternative: a Python script with an imaging library. Rejected: a second toolchain to install, for something Flutter already does.

Whether images written this way are byte-identical across machines is not known. The reproducibility requirement is tested on the pixels (decoded), not the file bytes.

### 4. Launch screen resources

- `values/colors.xml`: `launch_background` light; `values-night/colors.xml`: dark.
  - Light: `#F2F2F0`, a near-white between Daylight's cool page (`#EEF2F9`) and Paper's cream (`#F6F1E7`), so it clashes with neither.
  - Dark: `#0F1218`, the Night page colour.
- Android 12 and later (`values-v31/styles.xml`, and `values-night-v31`): `LaunchTheme` sets `windowSplashScreenBackground` to `launch_background`. The system supplies the icon.
- Before Android 12: `drawable/launch_background.xml` becomes the colour plus the foreground mark centred, tinted blue in light and white in dark, so it resembles the newer screen.
- `NormalTheme`'s window background also uses `launch_background`, so the gap between the launch screen and Flutter's first frame has the same colour.

### 5. Following the chosen appearance

Android 12 added `UiModeManager.setApplicationNightMode`, which stores a night mode for the app in the system; the system uses it for the launch screen from then on. This is the only supported way to make the launch screen differ from the phone's mode.

| Appearance | Night mode reported |
|---|---|
| Automatic | follow the system |
| Daylight | no |
| Night | yes |
| Paper | no |

The exact constant for "follow the system" is to be confirmed from the platform documentation in the first task (the API offers `MODE_NIGHT_AUTO` and `MODE_NIGHT_CUSTOM` beside yes and no, and which of them clears an override is easy to get wrong).

Wiring, in the project's layers:

- `LaunchAppearanceRepository` (interface, data layer): `Future<void> setLaunchAppearance(AppearanceMode mode)`.
- `MethodChannelLaunchAppearanceRepository`: calls channel `ippo/launch_appearance`, method `setNightMode`. A missing implementation (tests, other platforms) is ignored: this is cosmetic and must never stop the app.
- `MainActivity.configureFlutterEngine` registers the channel; on API 31 and later it calls `UiModeManager.setApplicationNightMode`; below that it does nothing.
- `AppViewModel` already receives every appearance change, including one restored from a backup; it reports each to the repository, and once at start. Reporting an unchanged value is harmless.
- A fake repository records calls for tests.

No new package: the channel is a dozen lines of Kotlin.

### 6. The side effect on Flutter

Once the app's night mode is forced, the app's configuration says dark or light regardless of the phone, and Flutter's `platformBrightness` follows it. The themes are selected explicitly for Daylight, Night and Paper, so they should not care. Automatic reports "follow the system", so it should keep tracking the phone.

"Should" is not enough: this is checked on the phone for all four settings in both phone modes (task group 5), and if Automatic stops tracking the phone the approach is wrong and is revisited before anything else is built on it.

### 7. Testing

- **Unit**: the mapping from appearance to reported night mode; `AppViewModel` reports at start and on each change; a failing or missing channel does not surface.
- **Files**: the committed icon images and XML (decision 3).
- **On the phone**: the icon in the launcher and with themed icons on; the launch screen for each appearance in both phone modes; Automatic still follows the phone; no white flash in Night.

## Risks / Trade-offs

- **Forcing night mode breaks Automatic or the in-app themes** → Verified on the phone first (decision 6); the fallback is to follow the phone's mode only, which still removes the white flash for most use.
- **The first launch after choosing a theme shows the old launch screen** if the system applies the mode late → Accepted; it corrects itself from the next launch.
- **Paper shows a light, not cream, launch screen** → Agreed with the owner; the light colour is chosen to sit between the two light themes.
- **A dense character blurs at small sizes** → Checked at 48 px in the file test's output and on the phone; the fallback is a heavier stroke or a larger glyph.
- **Launchers cache icons**, so the old icon may linger after an update → Clears on reboot or reinstall; noted for the phone check.
- **Glyph rendering differs slightly between Flutter versions** → The images are committed; regeneration is deliberate.

## Migration Plan

None for data. Installing the update replaces the icon and launch screen. Rollback is reverting the commit.

## Open Questions

- Whether the light launch colour reads well next to both Daylight and Paper is judged on the phone; it is one resource value.
