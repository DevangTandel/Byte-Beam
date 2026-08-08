# Byte-Beam

A Flutter fleet operations demo: live vehicle list, status filters, honesty-aware SOC/range display, and session alerts with undo.

For architecture decisions and assumptions, see [NOTES.md](NOTES.md).

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) with Dart SDK matching `pubspec.yaml` (`^3.12.2`)
- An iOS Simulator, Android emulator, or a connected device for `flutter run`

## Setup

From the project root:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

`build_runner` generates Freezed / JSON / Mockito outputs. Re-run it after changing annotated models or `@GenerateMocks` tests.

## Run the app

```bash
flutter run
```

The app loads a seeded fleet from `assets/seed_fleet.json` and updates telemetry every few seconds via an in-memory mock (no backend required).

## Test

Unit and widget tests:

```bash
flutter test
```

Integration tests (device or emulator):

```bash
flutter test integration_test/
```

Optional static analysis:

```bash
flutter analyze
```

## 30-second feature tour (for reviewers)

1. **Open the app** — You land on the **Fleet** screen: a list of vehicles with registration, model, status (moving / idle / stopped / offline), and battery/range readings.
2. **Watch it update** — Values refresh on their own every few seconds (mock live telemetry). Some cards may show warning or critical **alert badges**.
3. **Use the filter chips** — Tap **Moving**, **Idle**, **Stopped**, or **Offline** to narrow the list. Counts on the chips reflect the whole fleet, not only the filtered rows. Tap **All** to reset.
4. **Open a vehicle** — Tap any card to open **detail**: full readings, status, and alerts for that vehicle only.
5. **Handle an alert** — On detail (when alerts are present), dismiss one and use **Undo** within a few seconds if you change your mind. Dismissals are session-only (they are not saved across app restarts).
6. **Go back** — Return to the fleet list; filters and live updates continue as before.

That’s the product surface: a live fleet list, honest “stale/missing” readings, and short-lived operator alerts—not a production backend console.
