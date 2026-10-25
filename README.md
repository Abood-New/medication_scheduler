# Medication Scheduler

A Flutter mobile app for managing recurring medication schedules with alternating-day patterns. Works completely offline with local storage and notifications.

## Features

- **Alternating-day schedule**: Take medication one day, skip the next, repeat indefinitely
- **Reference date calculation**: Set one known "taken" date, app calculates all past/future schedules
- **Multiple medications**: Architecture supports multiple medications (one active at a time in v1)
- **Offline-first**: No backend, no internet required, all data stored locally
- **Local notifications**: Reminders on medication days using flutter_local_notifications
- **History tracking**: Mark doses as Taken/Missed, separate from calculated schedule
- **Calendar views**: Weekly and monthly schedule views with visual indicators
- **Settings**: Dark mode, date format, notification preferences
- **First-launch setup**: Guided onboarding flow

## Architecture

```
lib/
├── core/
│   ├── constants/          # App-wide constants
│   ├── errors/             # Failure classes
│   ├── utils/              # Helper functions
│   ├── date/               # Date-only abstraction (DST-safe)
│   └── services/           # Notification service
│
├── features/
│   ├── medications/
│   │   ├── data/
│   │   │   ├── datasources/    # Hive local storage
│   │   │   ├── models/         # Hive models with adapters
│   │   │   └── repositories/   # Repository implementations
│   │   ├── domain/
│   │   │   ├── entities/       # Pure Dart entities
│   │   │   ├── repositories/   # Repository interfaces
│   │   │   └── usecases/       # Business logic
│   │   └── presentation/
│   │       ├── providers/      # Provider state management
│   │       ├── pages/          # UI screens
│   │       └── widgets/        # Reusable components
│   │
│   ├── schedule/
│   │   ├── domain/
│   │   │   ├── entities/       # ScheduleDay, ScheduleRange
│   │   │   └── services/       # MedicationScheduleService (core engine)
│   │   └── presentation/
│   │       ├── providers/
│   │       └── pages/
│   │
│   ├── history/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── settings/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── main.dart
```

## Data Model

### Medication
- `id`, `name`, `dosage`, `notes`
- `scheduleType` (EVERY_OTHER_DAY for v1)
- `referenceDate` (the anchor date)
- `reminderEnabled`, `reminderTime`
- `createdAt`, `updatedAt`

### MedicationRecord
- `id`, `medicationId`, `date`
- `scheduledStatus` (TAKE/SKIP - calculated)
- `actualStatus` (TAKEN/MISSED/NOT_RECORDED - user input)
- `createdAt`, `updatedAt`

## Schedule Algorithm

All calculations use **calendar dates only** (AppDate) to eliminate DST/timezone issues:

```dart
bool shouldTake(AppDate referenceDate, AppDate date) {
  final diff = date.differenceInDays(referenceDate);
  return diff % 2 == 0;  // Works for negative diffs (past dates)
}
```

### Edge Cases Handled
- ✅ Past dates (negative differences)
- ✅ Month boundaries (Jan 31 → Feb 1)
- ✅ Year boundaries (Dec 31 → Jan 1)
- ✅ Leap years (Feb 28/29 → Mar 1)
- ✅ Different month lengths
- ✅ DST transitions (normalized to midnight)

## Local Notifications

- Uses `flutter_local_notifications` with `timezone` package
- Schedules notifications for upcoming TAKE days (60 days ahead)
- Works completely offline
- Rescheduled on app launch and when settings change
- Android: exact alarms with boot receiver
- iOS: UNUserNotificationCenter

## Getting Started (Local Development)

```bash
# Install dependencies
flutter pub get

# Generate Hive adapters
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

## 🚀 Deploy to GitHub Pages (No Local Install Required)

You can build and deploy this as a **web app** using GitHub Actions — no Flutter installation needed on your machine!

### One-time Setup

1. **Create a GitHub repository** and push this code:
   ```bash
   git init
   git add .
   git commit -m "Initial commit: Medication Scheduler"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/medication-scheduler.git
   git push -u origin main
   ```

2. **Enable GitHub Pages** in your repository settings:
   - Go to **Settings → Pages**
   - Source: **"GitHub Actions"**
   - Save

3. **The workflow will auto-run** on every push to `main` and deploy to:
   ```
   https://YOUR_USERNAME.github.io/medication-scheduler/
   ```

### What the Workflow Does

The `.github/workflows/flutter-web.yml` file:
- ✅ Checks out your code
- ✅ Sets up Flutter 3.22 (stable) in the cloud
- ✅ Runs `flutter pub get` and `build_runner` for Hive adapters
- ✅ Runs all unit tests
- ✅ Builds Flutter Web with `--base-href "/medication-scheduler/"`
- ✅ Deploys to GitHub Pages automatically

### Custom Repository Name

If your repo is named differently, update the `base-href` in the workflow:
```yaml
- name: Build Flutter Web
  run: flutter build web --release --base-href "/YOUR_REPO_NAME/"
```

### Web-Specific Notes

- **Hive Web**: Uses `hive_flutter` with IndexedDB (works in browser)
- **Notifications**: Web uses Service Worker + Web Notifications API (requires HTTPS - GitHub Pages provides this)
- **Offline**: Service Worker caches the app for offline use
- **PWA**: `manifest.json` enables "Add to Home Screen" on mobile

### Manual Deploy (Optional)

If you want to trigger a deploy without code changes:
1. Go to **Actions** tab in GitHub
2. Select "Build and Deploy Flutter Web to GitHub Pages"
3. Click **"Run workflow"**

## Testing

```bash
# Run unit tests
flutter test
```

Tests cover:
- Schedule calculation (basic pattern, boundaries, leap years, negative diffs)
- AppDate utility functions
- ScheduleDay entity behavior

## Platform Support

- Android (API 21+)
- iOS (12.0+)

## Permissions

### Android
- `VIBRATE`
- `RECEIVE_BOOT_COMPLETED`
- `SCHEDULE_EXACT_ALARM`
- `USE_EXACT_ALARM`
- `POST_NOTIFICATIONS`

### iOS
- Notification permissions requested at runtime

## Medical Disclaimer

This app is a **scheduling and reminder tool only**. It does not:
- Provide medical advice
- Adjust dosages automatically
- Recommend taking additional doses
- Determine what to do after missed doses

Always follow your healthcare provider's instructions.