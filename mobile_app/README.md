# ForgeTrack Mobile

A Flutter mobile application version of the ForgeTrack ticketing system.

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
- [Node.js](https://nodejs.org/) (for Firebase CLI).
- A Firebase project (same as the web app).

## Setup

1. **Generate Platform Code**
   Since this repository contains only the Dart source code, you need to generate the platform-specific folders (android, ios, etc.).
   ```bash
   cd mobile_app
   flutter create .
   ```
   *Note: This command might overwrite `pubspec.yaml` or `README.md`. If it prompts, choose not to overwrite or backup these files first. It is safer to create a new project and copy the `lib` folder and `pubspec.yaml` content.*

   **Alternative Safer Approach:**
   1. Create a new flutter project elsewhere: `flutter create forge_track_mobile`
   2. Copy the `lib` folder and `pubspec.yaml` from this directory to the new project.

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   Ensure you have the Firebase CLI installed and logged in.
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

   Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

   Run configure command:
   ```bash
   flutterfire configure
   ```
   Select your project (`forge-track-...`) and the platforms you want to support (Android, iOS). This will overwrite `lib/firebase_options.dart` with valid keys.

4. **Run the App**
   ```bash
   flutter run
   ```

## Architecture

- **Models**: `lib/models/` - Data classes (User, Ticket, Comment).
- **Services**: `lib/services/` - `FirebaseService` handles all backend logic.
- **Providers**: `lib/providers/` - State management (AuthProvider).
- **Screens**: `lib/screens/` - UI pages.
- **Widgets**: `lib/widgets/` - Reusable components.

## Notes

- This app shares the same Firestore database as the web version.
- Ensure Firestore Security Rules and Indexes are deployed.
