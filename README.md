# Byte-Beam

A Flutter fleet ops demo: live vehicle status, honest telemetry readings, and dismissible alerts — seeded from local mock data (no backend required).

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) with SDK matching `pubspec.yaml` (`^3.12.2`)
- A simulator/emulator or a physical device for `flutter run`

## Setup

```bash
flutter pub get
```

Generate Freezed / JSON / Mockito code (needed after cloning or changing annotated models/mocks):

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Run the app

```bash
flutter run
```

The app loads eight vehicles from `assets/seed_fleet.json` and ticks mock telemetry while it is open.

## Test

Unit and widget tests:

```bash
flutter test
```

With coverage:

```bash
flutter test --coverage
```

Integration tests (when present under `integration_test/`):

```bash
flutter test integration_test/
```

Static analysis (Very Good Analysis):

```bash
flutter analyze
```

## 30-second feature tour (for reviewers)

1. **Open the app** — you land on the fleet list: eight vehicles with status chips (Moving / Idle / Stopped / Offline) and live SOC/range.
2. **Scan the chips at the top** — tap **Moving**, **Idle**, etc. to filter; counts update as vehicles change status. Empty filters show a clear “nothing matches” message.
3. **Spot problems at a glance** — alert badges appear on vehicles that need attention (e.g. low battery). Dimmed values with “data X min old” mean the reading is stale, not an alarm by itself; offline vehicles stay frozen.
4. **Open a vehicle** (try the one with low SOC or a badge) — see the full readings register, status, and any active alerts.
5. **Dismiss an alert** — pick a reason; a short undo snackbar lets you reverse the dismiss. After the window closes, the same continuous issue will not pop back until the condition clears and breaches again.
6. **Go back to the list** — filters and badges stay in sync with the live mock stream.
