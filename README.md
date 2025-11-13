# LamaPlay

A Flutter + Firebase party game scaffold. Targets Android, iOS, and Web with live Firebase (no emulators, no Cloud Functions).

## Prerequisites
- Flutter SDK (stable channel)
- Firebase CLI
- Dart SDK (bundled with Flutter)

## 1) Use Flutter stable channel
```powershell
flutter channel stable
flutter upgrade
flutter --version
```

## 2) Configure Firebase for Android, iOS, Web
Use FlutterFire to generate `lib/firebase_options.dart` for all three platforms.

```powershell
flutter pub get
flutterfire configure --project=<YOUR_FIREBASE_PROJECT_ID> --platforms=android,ios,web
```
This creates/updates:
- `lib/firebase_options.dart`
- Android config (`android/app/google-services.json`)
- iOS config (via Xcode project changes)
- Web config embedded in `firebase_options.dart`

Note: Do not check secrets into source control if you use additional keys.

## 3) Initialize Firestore and Realtime Database (no Functions)
Use the Firebase CLI to set up rules only for Firestore and Realtime Database. Do not enable emulators or Cloud Functions.

```powershell
firebase login
firebase init firestore database --project <YOUR_FIREBASE_PROJECT_ID>
```
- When prompted for emulators: choose "No"
- When prompted for Functions/Hosting: choose "No"
- This repository expects the following files to exist and be referenced by `firebase.json`:
	- `firestore.rules`
	- `database.rules.json`

If you already have a project, you can just ensure the rules files exist and your `.firebaserc` has the default project.

## 4) Running the app
- Mobile (Android/iOS):
```powershell
flutter run
```
- Web (Chrome):
```powershell
flutter run -d chrome
```

## Architecture Overview
- `lib/main.dart`: Initializes Firebase using `DefaultFirebaseOptions` and ensures anonymous sign-in via `AuthService`, then loads the router.
- `lib/core/app_theme.dart`: Light/Dark theme definitions.
- `lib/core/router.dart`: Named routes for Home, Lobby, Round Intro, Game Shell, Results, Leaderboard.
- `lib/services/auth_service.dart`: Anonymous auth helper.
- `lib/services/presence_service.dart`: Realtime Database presence per room/player using `onDisconnect` with `online` + `lastSeen`.
- `lib/services/firestore_refs.dart`: Centralized Firestore paths for rooms, players, rounds, submissions, votes, secrets, drawing.
- `lib/screens/*`: Placeholder screens for navigation.
- `lib/widgets/*`: Reusable UI widgets (timer bar, player chip, score ticker).
- `lib/models/*`: Data models and constants for rooms, players, rounds, etc.
- `lib/games/*`: Mini-game placeholders with JSON packs.
- `lib/state/*`: Controllers (room/round/playlist) scaffolding for future logic.

## Acceptance test
Use two real clients (e.g., two browsers, or phone + browser) with a live Firebase project:
1. Launch the app on both clients.
2. On launch, the app initializes Firebase and signs in anonymously.
3. From Home, tap "Go to Lobby"; both clients should navigate to the Lobby placeholder.
4. Presence behavior is implemented in `PresenceService` (connect/disconnect outline). Wire to your room lifecycle when ready.

## Notes
- No emulators and no Cloud Functions are used in this scaffold.
- Before building iOS, open the Xcode workspace after running `flutterfire configure`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
