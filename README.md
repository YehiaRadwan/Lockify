# Lockify (Flutter Android MVP)

Lockify is a local-first proof-of-work screen-time limiter MVP built with Flutter for Android, created during my time at my AWS work experience.

## MVP features

- Locked home screen by default
- Focus work-session timer before proof submission
- Proof-of-work submission flow (text/photo/document placeholders)
- Mock proof-quality scoring for local AI-style evaluation
- Work-to-screen-time balance (currently 30 minutes of work earns 5 minutes)
- Timed unlock session countdown with automatic re-lock
- Daily reset that re-locks the app
- Local active-session persistence and unlock history (`SharedPreferences`)
- Android restriction integration through a native service and permission flow

> **note:** Proof evaluation is currently a local mock, not a connected AI service. Review the Android permission and background-service behaviour on your target devices before relying on it as a system-wide blocker.

## Requirements

- Flutter SDK installed and available on your PATH
- Android Studio with the Flutter and Dart plugins installed
- Android SDK and an Android emulator, or a physical Android device with USB debugging enabled
- A compatible Java/Android Gradle toolchain configured through Android Studio

## Open and run in Android Studio

1. Clone or download this repository.
2. Open Android Studio and choose **Open**.
3. Select the repository's root `Lockify` folder — the folder containing `pubspec.yaml` (do not select the `android` subfolder).
4. If prompted, configure the Flutter SDK location in Android Studio under **Settings → Languages & Frameworks → Flutter**.
5. Wait for Android Studio to finish loading the project. If dependencies are not fetched automatically, open the terminal at the project root and run:

   ```bash
   flutter pub get
   ```

6. Start an Android emulator from **Tools → Device Manager**, or connect an Android device.
7. Select the device in the Android Studio toolbar and press **Run**.
8. On first launch, follow Lockify's prompts to grant Usage access and Display over other apps permissions.


## Run from a terminal

From the repository root (the directory containing `pubspec.yaml`):

```bash
flutter pub get
flutter devices
flutter run
```

## Run tests

```bash
flutter test
```

## Build a debug APK

```bash
flutter build apk --debug
```

The APK is created at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Project structure

```text
Lockify/
├── android/       # Native Android project and Gradle wrapper
├── lib/           # Flutter application source
│   ├── models/    # Application data models
│   ├── services/  # Application logic and Android bridge
│   └── views/     # User interface screens
├── test/          # Flutter tests
├── pubspec.yaml   # Dependencies and Flutter configuration
└── README.md
```
