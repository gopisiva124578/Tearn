# Travel & Earn App - Build Instructions

Since I cannot build the APK directly in this environment, follow these steps to build it on your machine.

## Prerequisites
- [Flutter SDK API](https://docs.flutter.dev/get-started/install) installed.
- Android Studio or VS Code set up for Flutter.
- An Android device or emulator.

## Steps

1. **Create the Project**
   Open your terminal/command prompt and run:
   ```bash
   flutter create travel_earn_app
   ```

2. **Replace Files**
   Copy the files I generated in the `flutter_app_source` folder to your new project:
   
   - Copy `flutter_app_source/pubspec.yaml` -> `travel_earn_app/pubspec.yaml` (Replace existing)
   - Copy `flutter_app_source/main.dart` -> `travel_earn_app/lib/main.dart` (Replace existing)
   - Copy `flutter_app_source/AndroidManifest.xml` -> `travel_earn_app/android/app/src/main/AndroidManifest.xml` (Replace existing)
     *Note: If your package name is different, you might need to adjust the directory or Manifest slightly, but the permissions `<uses-permission ...>` are the key part to copy.*

3. **Install Dependencies**
   In the terminal, inside the `travel_earn_app` folder, run:
   ```bash
   flutter pub get
   ```

4. **Build APK**
   Connect your Android phone and run:
   ```bash
   flutter run
   ```
   Or to generate an installable APK file:
   ```bash
   flutter build apk --release
   ```
   The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`
