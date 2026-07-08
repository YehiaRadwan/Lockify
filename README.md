# Lockify (iPhone MVP)

Lockify is a local-only proof-of-work screen-time limiter MVP built with SwiftUI.

## What this MVP includes
- Locked home screen by default (daily reset re-locks the app)
- Proof submission flow (text/photo/document placeholders)
- Local unlock duration estimation from user-provided work estimate
- Timed unlock session with countdown and automatic re-lock
- Local unlock session history (stored in `UserDefaults`)
- Compile-safe Screen Time integration scaffolding (`FamilyControls`, `ManagedSettings`, `DeviceActivity`) behind abstractions/placeholders

## Run on iPhone (Xcode)
1. Open `/home/runner/work/Lockify/Lockify/Lockify.xcodeproj` in Xcode 15+.
2. In **Signing & Capabilities**, set your personal Team and a unique bundle identifier if needed.
3. Connect your iPhone, trust the developer certificate if prompted.
4. Select your iPhone as the run destination.
5. Build and Run.

> The app runs as a local-only demo without Screen Time entitlements.
> `ScreenTimeBridge.swift` is where entitlement-gated integration can be expanded later.
