# Build APK

## GitHub Actions (recommended for this project)

Use the included workflow:

`.github/workflows/build-apk.yml`

It builds the APK on GitHub's runner, so Flutter and Android SDK do not need to be installed on your phone.

### Output

Artifact name:

`WorkoutApp-v0.7-release`

APK filename:

`WorkoutApp-v0.7-release.apk`

## Local build

If Flutter is working locally:

```bash
flutter pub get
flutter analyze
flutter build apk --release
```

APK output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

If the Android platform files are incomplete, regenerate them with:

```bash
flutter create --platforms=android --org com.workout --project-name workout_app .
```

Then run `flutter pub get` and build again.
