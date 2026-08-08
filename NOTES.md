# Byte-Beam: Design Notes

These notes explain the main architecture decisions, assumptions, trade-offs, and how AI was used during the take-home build.

## Architecture rationale

### Feature-first structure with a clean domain layer

The code is organized by feature under `lib/features/{fleet,alerts,vehicle_detail}`. Each feature follows a `data`, `domain`, and `presentation` structure. There is also a small `lib/core` layer for shared concerns such as the clock, dependency injection, routing, theme, and reusable widgets.

The main reason for this structure was to keep the business rules independent from Flutter.

The domain layer handles things like status resolution, stale data checks, reading boundaries, and alert evaluation. These are framework-independent functions and entities. Widgets and blocs consume those results instead of deciding thresholds themselves.

The feature-first structure also keeps responsibilities separated. Fleet list behavior, alert session behavior, and vehicle detail composition can evolve independently. Cross-feature communication is intentionally limited. For example, the detail screen listens to `AlertsCubit`, while fleet cards receive their alert badge summary from the alert state.

The presentation layer is mainly responsible for displaying already-resolved data. `FleetBloc` emits `FleetListItem`, which already contains the vehicle status and SOC/range verdicts. `VehicleDetailBloc` does the same for individual parameter verdicts and VIN-specific alerts. This keeps the UI relatively simple and avoids duplicating business logic inside widgets.

### Why Bloc

Bloc felt like a good fit because the application is largely driven by streams and state changes.

It gives a clear place to handle events such as fleet telemetry ticks, filter changes, alert dismissal, and undo actions.

It also worked well with testing. Using `bloc_test` together with `fakeAsync` made things like the five-second undo window and telemetry updates deterministic.

I kept `AlertsCubit` app-scoped because alerts need to survive navigation between the fleet and detail screens. `VehicleDetailBloc` is route-scoped because its lifecycle belongs to a specific vehicle detail screen. This avoided introducing a larger global state-management solution than the assignment needed.

### Why get_it

`get_it` keeps dependency wiring in one place.

The main dependencies are the `Clock`, telemetry data source, repository, and blocs. It is also straightforward to override dependencies in tests using something like `configureDependencies(clock: ..., seed: ...)`.

The lifetime also maps nicely to the application:

• Fleet and alert dependencies are lazy singletons.

• `VehicleDetailBloc` is created as a factory with the vehicle VIN.

This keeps the dependency setup simple without introducing unnecessary abstractions.

### Why go_router

`go_router` provides a simple declarative route structure:

`/`

`/vehicle/:vin`

The required blocs can be created through the route builders, and the route structure also gives us a clean deep-link shape for the assignment.

Another useful part is the lifecycle behavior. When navigating back from the vehicle detail screen, the detail subscriptions are disposed correctly. This is covered by the navigation lifecycle test.

## Explicit assumptions

A few behaviors were not completely specified in the brief. I made the following decisions and documented them in the code and tests.

### 1. `ignitionOn == null` means STOPPED

The brief defines IDLE as speed `0` with the ignition on, but it does not specify what should happen when `ignitionOn` is null.

I treated null as "ignition is not confirmed to be on."

Therefore, when the vehicle is online and not moving:

`ignitionOn ?? false`

results in `STOPPED`.

This decision is documented and covered by `status_resolver_test.dart`.

### 2. A resolve and later rebreach creates a new alert

The brief explains how dismissal applies to an alert instance or session, but it does not explicitly define what should happen if the condition clears and then happens again.

I chose the following behavior:

If an alert is dismissed and the same condition continues, it should not keep coming back.

If the condition resolves and later breaches again, that is treated as a new alert with a new ID.

This behavior is marked as `SIGN-OFF` in `alerts_cubit_test.dart`.

### 3. Age is recalculated on telemetry ticks

Age and stale/offline decisions are calculated using the injected `Clock.now()` against `lastPingAt` and reading timestamps.

The mock telemetry source updates `lastPingSecondsAgo` every three seconds for online vehicles. VIN0007 is intentionally frozen to simulate an offline vehicle.

The domain mapping then recalculates the absolute timestamps on each emission.

I deliberately did not add a separate UI-only timer just to update the displayed age.

This means the displayed age and staleness state advance when the fleet stream emits a new value, or when the injected clock advances during tests. There is no independent animation timer trying to keep the UI clock in sync.

This keeps the behavior tied to the actual telemetry model rather than creating two separate concepts of time.

### 4. Mock telemetry uses `Random(42)`

The mock telemetry source uses `Random(42)` by default.

This makes SOC drain and speed jitter deterministic. As a result, tests can assert the exact values from the first telemetry tick instead of simply checking that "something changed."

This behavior is documented in `mock_telemetry_data_source_test.dart`.


## How AI was used

The project was developed in Cursor using a test-first, phased approach.

The general loop was:

1. Write or review the failing test.
2. Ask AI to implement the smallest production change needed.
3. Run `flutter test`.
4. Run `flutter analyze`.
5. Review the implementation and test output.
6. Make any required corrections before moving on.

AI was used heavily for implementation and test scaffolding, but the product decisions, assumptions, and final review remained mine.

### Prompt and phase breakdown

| Prompt / phase                                 | Main focus                                                                                                                 |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| Early clock and `Reading` prompts              | `Clock.now()` as a method, age calculation, and stale data being strictly greater than five minutes                        |
| Prompt 4                                       | Boundary-condition tests such as offline at 9:59 versus 10:00, stale at 4:59 versus 5:00, and inclusive threshold behavior |
| Status, staleness, and model prompts           | Pure `resolveStatus`, `evaluateStaleness`, and `VehicleModel.toDomain` using Freezed                                       |
| Mock telemetry prompts                         | Three-second telemetry ticks, VIN0007 freezing, and the deterministic `Random(42)` sequence                                |
| Repository, FleetBloc, and AlertsCubit prompts | Stream fan-out, filters, live counts, dismissal and undo behavior, and the rebreach rules                                  |
| Prompt 11                                      | Alert engine behavior when stale data should block new alerts while existing alerts remain flagged                         |
| Phase 4 UI and Phase 5 shell                   | Shared theme and widgets, `get_it`, `go_router`, and application wiring                                                    |
| Detail, lifecycle, and verification            | Detail bloc projections, navigation disposal, checklist review, analysis, and coverage                                     |
| SOLID follow-ups                               | Making `VehicleCard` a dumb presentation widget and having the home screen bind `FleetListItem` and `badgeSummaryFor`      |
| Documentation                                  | `README.md` and these design notes                                                                                         |

## Manual review before accepting AI output

I did not treat the AI-generated tests as automatically correct.

I specifically reviewed the two areas where a small mistake could change the business behavior.

### 1. Boundary-condition tests

The tests from Prompt 4 cover cases such as:

• Offline at 9:59 versus 10:00

• Stale at 4:59 versus 5:00

• Strict `>` behavior for the stale threshold

• SOC boundaries such as 19.9 versus 20

• Temperature boundaries such as 9.9 versus 10 and 45 versus 45.1

I reviewed these line by line against the original brief before accepting them.

### 2. Alert engine and stale data behavior

Prompt 11 covered an important distinction:

A stale SOC reading should not create a new alert.

However, if an alert already exists and the underlying reading later becomes stale, that existing alert should remain and be marked with `isBasedOnStaleData`.

These two behaviors may look similar at first, but they are intentionally different.

I verified both cases separately in `alert_engine_test.dart` before accepting the implementation.

Everything else also went through local CI-style checks using `flutter test` and `flutter analyze` with `very_good_analysis`.

The two areas above were the ones I considered high risk enough to require explicit human review before acceptance.
