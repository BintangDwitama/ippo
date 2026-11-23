## 1. Confirm the platform behaviour

- [x] 1.1 Read the Android documentation for `UiModeManager.setApplicationNightMode` and the Android 12 launch screen; record in design.md the constant that means "follow the system" and anything that differs from the design
- [x] 1.2 Read the adaptive icon documentation for the layer sizes, safe zone and the monochrome layer; correct design.md if needed

## 2. Icon artwork

- [x] 2.1 Write `tool/icon/generate_icon_test.dart`: render 歩 from the bundled Klee One font, centred by its ink, to the foreground images and the legacy icons at five densities
- [x] 2.2 Run it; add `mipmap-anydpi-v26/ic_launcher.xml` with background, foreground and monochrome layers and the background colour resource
- [ ] 2.3 Show the owner the rendered icon (full size and at launcher size) and adjust size or weight if asked
- [x] 2.4 Add `test/tool/icon_files_test.dart`: files exist at the right sizes, the foreground's ink lies inside the safe circle, the XML names all three layers, and regenerating gives the same pixels

## 3. Launch screen

- [x] 3.1 Add the light and dark `launch_background` colours and use them in `NormalTheme`
- [x] 3.2 Android 12 and later: set `windowSplashScreenBackground` in `values-v31` and `values-night-v31`
- [x] 3.3 Before Android 12: colour plus centred mark in `drawable/launch_background.xml`, light and dark

## 4. Follow the chosen appearance

- [x] 4.1 Add `LaunchAppearanceRepository`, its method-channel implementation that ignores a missing platform side, and a fake
- [x] 4.2 Register the channel in `MainActivity` and set the app's night mode on Android 12 and later
- [x] 4.3 Report the appearance from `AppViewModel` at start and on every change; wire it in `main.dart` and `AppDependencies`
- [x] 4.4 Tests: the mapping for all four appearances; reported at start, on change and after a restore; a failing channel does not surface

## 5. Checks on the phone

- [x] 5.1 Run `flutter analyze` and `flutter test`; build and install the release
- [ ] 5.2 Verify that reporting the night mode does not change the app's look: Automatic still follows the phone in both modes; Daylight, Night and Paper show correctly with the phone in either mode. If not, stop and revisit decision 5
- [ ] 5.3 The owner checks: the icon on the home screen and in the app drawer, with themed icons on and off; the launch screen for each appearance; no white flash in Night
- [ ] 5.4 Record what the check found in design.md, fix what it turns up, and update the README
