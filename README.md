# WorkoutApp — V0.7

Personal workout tracker built for a single user. The app focuses on selecting today's workout, following the exercise order, warm-up timers, set/rest timers, session history, streaks, sound alerts, and keeping the screen awake during training.

## Current V0.7 scope

- Push A / Push B / Pull A / Pull B / Legs A / Legs B / Rest
- Manual workout selection; no automatic day scheduling
- One-session exercise reordering before Start Workout
- Configurable sets per exercise
- Warm-up flow per workout family
- Countdown timer per set/time-based exercise
- Time's Up alert when a set timer reaches zero
- Complete Set → Rest → next Set flow
- Rest timer starts at 03:00 with +30 sec and +1 min controls
- Workout session pause/resume
- Exit confirmation while a workout is in progress
- Local workout history
- Streak screen including rest days
- Settings: system alert sound and Keep Screen Awake
- Dark/red visual direction

## Important prototype note

The exercise images currently included are provisional. They are intentionally kept in the project so the UI can be tested; they can be replaced later without changing the app flow.

## Build with GitHub Actions

The repository includes `.github/workflows/build-apk.yml`.

1. Push this project to GitHub.
2. Open the repository's **Actions** tab.
3. Select **Build WorkoutApp APK**.
4. Press **Run workflow** (or push to `main`).
5. Wait for the job to finish.
6. Open the workflow run and download the artifact named `WorkoutApp-v0.7-release`.

The workflow installs Flutter on the GitHub runner, regenerates valid Android/Gradle platform files, gets dependencies, runs `flutter analyze`, builds a release APK, and uploads it as an artifact.

The release APK is intended for personal sideloading. It is not configured for Google Play publishing/signing yet.
