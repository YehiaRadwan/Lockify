# Lockify (Flutter Android MVP)

Lockify is a local-only proof-of-work screen-time limiter MVP built with Flutter for Android.

## MVP features
- Locked home screen by default
- Proof-of-work submission flow (text/photo/document placeholders)
- Local unlock duration estimation from user work estimate
- Timed unlock session countdown with automatic re-lock
- Daily reset that re-locks the app
- Local unlock session history (`SharedPreferences`)
- Restriction integration scaffold (`NoopRestrictionBridge`) for future platform APIs

## Project setup
This repository contains Flutter source files. If `android/` is missing, generate platform files first:

```bash
cd /home/runner/work/Lockify/Lockify
flutter create . --platforms=android
```

Then fetch dependencies:

```bash
cd /home/runner/work/Lockify/Lockify
flutter pub get
```

## Run on Android device
```bash
cd /home/runner/work/Lockify/Lockify
flutter run
```

## Run on BlueStacks (Windows)
1. Install Flutter SDK + Android SDK on Windows.
2. Start BlueStacks and enable ADB from BlueStacks settings.
3. Verify emulator connection:
   ```bash
   adb devices
   ```
4. Build debug APK:
   ```bash
   cd /home/runner/work/Lockify/Lockify
   flutter build apk --debug
   ```
5. Install APK to BlueStacks:
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```
6. Open **Lockify** inside BlueStacks.

## Optional direct emulator run (if Flutter detects BlueStacks)
```bash
flutter devices
flutter run -d <device-id>
```
