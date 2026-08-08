import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/fleet/data/models/vehicle_model.dart';
import 'package:byte_beam/features/fleet/domain/entities/reading.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:byte_beam/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:byte_beam/features/fleet/domain/rules/reading_bounds.dart';
import 'package:byte_beam/features/fleet/domain/rules/staleness_evaluator.dart';
import 'package:byte_beam/features/fleet/domain/rules/status_resolver.dart';
import 'package:byte_beam/features/fleet/presentation/bloc/fleet_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FleetRepository])
import 'fleet_bloc_test.mocks.dart';

/// Test-only clock with a fixed [now] value ("app launch" instant).
class FakeClock implements Clock {
  FakeClock(this._fixed);

  DateTime _fixed;

  @override
  DateTime now() => _fixed;

  void advance(Duration d) => _fixed = _fixed.add(d);
}

/// Seed fleet at a fixed launch clock — statuses via [resolveStatus]:
///   VIN0001 moving, VIN0002 idle, VIN0003 moving, VIN0004 stopped,
///   VIN0005 moving, VIN0006 stopped, VIN0007 offline, VIN0008 stopped
///
/// Live counts over the full set: moving=3, idle=1, stopped=3, offline=1.
List<Vehicle> seedFleet(Clock launchClock) {
  const models = [
    VehicleModel(
      vin: 'VIN0001',
      reg: 'KA 01 AB 1234',
      model: 'eCargo 55',
      socPercent: 78,
      rangeKm: 414.96,
      speedKmh: 42,
      ignitionOn: true,
      batteryTempC: 31,
      odometerKm: 45210,
      lastPingSecondsAgo: 3,
    ),
    VehicleModel(
      vin: 'VIN0002',
      reg: 'KA 05 CD 5678',
      model: 'eCargo 55',
      socPercent: 64,
      rangeKm: 340.48,
      speedKmh: 0,
      ignitionOn: true,
      batteryTempC: 29,
      odometerKm: 82977,
      lastPingSecondsAgo: 8,
    ),
    VehicleModel(
      vin: 'VIN0003',
      reg: 'MH 12 EF 9012',
      model: 'eVan 30',
      socPercent: 17,
      rangeKm: 90.44,
      speedKmh: 38,
      ignitionOn: true,
      batteryTempC: 33,
      odometerKm: 12780,
      lastPingSecondsAgo: 5,
    ),
    VehicleModel(
      vin: 'VIN0004',
      reg: 'KA 53 GH 3456',
      model: 'eVan 30',
      socPercent: 91,
      rangeKm: 484.12,
      speedKmh: 0,
      ignitionOn: false,
      batteryTempC: 27,
      odometerKm: 30455,
      lastPingSecondsAgo: 40,
    ),
    VehicleModel(
      vin: 'VIN0005',
      reg: 'TN 09 IJ 7890',
      model: 'eCargo 55',
      socPercent: 52,
      rangeKm: 276.64,
      speedKmh: 12,
      ignitionOn: true,
      batteryTempC: 47,
      odometerKm: 67002,
      lastPingSecondsAgo: 6,
    ),
    VehicleModel(
      vin: 'VIN0006',
      reg: 'KA 02 KL 2468',
      model: 'eVan 30',
      socPercent: 44,
      speedKmh: 0,
      ignitionOn: false,
      odometerKm: 55890,
      lastPingSecondsAgo: 95,
    ),
    VehicleModel(
      vin: 'VIN0007',
      reg: 'AP 16 MN 1357',
      model: 'eCargo 55',
      socPercent: 8,
      rangeKm: 42.56,
      speedKmh: 0,
      ignitionOn: true,
      batteryTempC: 36,
      odometerKm: 91004,
      lastPingSecondsAgo: 720,
    ),
    VehicleModel(
      vin: 'VIN0008',
      reg: 'KA 41 PQ 8642',
      model: 'eVan 30',
      speedKmh: 0,
      ignitionOn: false,
      batteryTempC: 25,
      odometerKm: 23100,
      lastPingSecondsAgo: 55,
    ),
  ];

  return [for (final model in models) model.toDomain(launchClock)];
}

/// Counts computed over the unfiltered fleet (brief "live counts").
const seedCounts = FleetStatusCounts(
  all: 8,
  moving: 3,
  idle: 1,
  stopped: 3,
  offline: 1,
);

void main() {
  final launchAt = DateTime(2026, 8, 7, 12);

  late MockFleetRepository mockRepository;
  late FakeClock clock;
  late List<Vehicle> fleet;

  setUp(() {
    mockRepository = MockFleetRepository();
    clock = FakeClock(launchAt);
    fleet = seedFleet(clock);
    when(mockRepository.watchFleet()).thenAnswer((_) => Stream.value(fleet));
  });

  FleetBloc buildBloc() => FleetBloc(
        repository: mockRepository,
        clock: clock,
      );

  group('FleetBloc', () {
    blocTest<FleetBloc, FleetState>(
      'initial load emits FleetLoaded with all 8 vehicles, filter=all, '
      'and correct per-status counts',
      build: buildBloc,
      act: (bloc) => bloc.add(const FleetStarted()),
      expect: () => [
        isA<FleetLoaded>()
            .having((s) => s.filter, 'filter', FleetFilter.all)
            .having((s) => s.items, 'items', hasLength(8))
            .having(
              (s) => s.items.map((i) => i.vehicle.vin).toList(),
              'vins',
              [
                'VIN0001',
                'VIN0002',
                'VIN0003',
                'VIN0004',
                'VIN0005',
                'VIN0006',
                'VIN0007',
                'VIN0008',
              ],
            )
            .having((s) => s.counts, 'counts', seedCounts),
      ],
      verify: (bloc) {
        final loaded = bloc.state as FleetLoaded;

        // Sanity-check status breakdown against resolveStatus.
        final byStatus = <VehicleStatus, int>{};
        for (final item in loaded.items) {
          byStatus[item.status] = (byStatus[item.status] ?? 0) + 1;
          expect(item.status, resolveStatus(item.vehicle, clock));
          expect(
            item.socVerdict,
            evaluateStaleness(item.vehicle.soc, kSocBounds, clock),
          );
          expect(
            item.rangeVerdict,
            evaluateStaleness(item.vehicle.range, kRangeBounds, clock),
          );
        }
        expect(byStatus[VehicleStatus.moving], 3);
        expect(byStatus[VehicleStatus.idle], 1);
        expect(byStatus[VehicleStatus.stopped], 3);
        expect(byStatus[VehicleStatus.offline], 1);

        // VIN0007 is offline + stale SOC (not alert-red for low SOC).
        final vin7 = loaded.items.singleWhere(
          (i) => i.vehicle.vin == 'VIN0007',
        );
        expect(vin7.status, VehicleStatus.offline);
        expect(vin7.socVerdict, Verdict.stale);
      },
    );

    blocTest<FleetBloc, FleetState>(
      'FilterChanged(moving) emits only moving vehicles; '
      'live counts stay over the full set (unchanged)',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FleetStarted());
        await pumpEventQueue();
        bloc.add(const FilterChanged(FleetFilter.moving));
      },
      expect: () => [
        isA<FleetLoaded>().having((s) => s.filter, 'filter', FleetFilter.all),
        isA<FleetLoaded>()
            .having((s) => s.filter, 'filter', FleetFilter.moving)
            .having((s) => s.items, 'items', hasLength(3))
            .having(
              (s) => s.items.map((i) => i.vehicle.vin).toList(),
              'moving vins',
              ['VIN0001', 'VIN0003', 'VIN0005'],
            )
            .having(
              (s) => s.items.every((i) => i.status == VehicleStatus.moving),
              'all filtered items are moving',
              isTrue,
            )
            // Live counts are always over the full fleet, not the
            // filtered list.
            .having((s) => s.counts, 'counts', seedCounts)
            .having((s) => s.counts.moving, 'counts.moving', 3)
            .having((s) => s.counts.all, 'counts.all', 8)
            .having(
              (s) => s.counts.moving == s.items.length,
              'moving count equals filtered length only by coincidence here',
              isTrue,
            )
            .having(
              (s) => s.counts.all > s.items.length,
              'all count remains full-set size while list is filtered',
              isTrue,
            ),
      ],
    );

    blocTest<FleetBloc, FleetState>(
      'filter with zero matches emits FleetLoaded with an empty items list '
      '(counts still reflect the full unfiltered set)',
      build: () {
        // Fleet with no idle vehicles → FilterChanged(idle) yields [].
        final noIdle = fleet
            .where((v) => resolveStatus(v, clock) != VehicleStatus.idle)
            .toList();
        when(mockRepository.watchFleet())
            .thenAnswer((_) => Stream.value(noIdle));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const FleetStarted());
        await pumpEventQueue();
        bloc.add(const FilterChanged(FleetFilter.idle));
      },
      expect: () => [
        isA<FleetLoaded>()
            .having((s) => s.filter, 'filter', FleetFilter.all)
            .having((s) => s.items, 'items', hasLength(7))
            .having(
              (s) => s.counts,
              'counts over full (no-idle) set',
              const FleetStatusCounts(
                all: 7,
                moving: 3,
                idle: 0,
                stopped: 3,
                offline: 1,
              ),
            ),
        isA<FleetLoaded>()
            .having((s) => s.filter, 'filter', FleetFilter.idle)
            .having((s) => s.items, 'items', isEmpty)
            .having(
              (s) => s.counts,
              'counts unchanged vs full set when filter matches nothing',
              const FleetStatusCounts(
                all: 7,
                moving: 3,
                idle: 0,
                stopped: 3,
                offline: 1,
              ),
            )
            .having((s) => s.counts.idle, 'idle count', 0),
      ],
    );

    test(
      'live status counts update when the fleet stream ticks with a new mix '
      '(not frozen at initial load)',
      () async {
        final fleetStream = StreamController<List<Vehicle>>();
        addTearDown(() async {
          await fleetStream.close();
        });
        when(mockRepository.watchFleet()).thenAnswer((_) => fleetStream.stream);

        final bloc = buildBloc();
        addTearDown(bloc.close);

        final states = <FleetState>[];
        final sub = bloc.stream.listen(states.add);
        addTearDown(sub.cancel);

        bloc.add(const FleetStarted());
        fleetStream.add(fleet);
        await pumpEventQueue();

        expect(states, hasLength(1));
        expect((states.single as FleetLoaded).counts, seedCounts);

        // Second tick: VIN0001 stops (was moving) → moving 3→2, stopped 3→4.
        final stoppedVin0001 = _withSpeedAndIgnition(
          fleet.singleWhere((v) => v.vin == 'VIN0001'),
          clock: clock,
          speed: 0,
          ignitionOn: false,
        );
        fleetStream.add([
          for (final vehicle in fleet)
            if (vehicle.vin == 'VIN0001') stoppedVin0001 else vehicle,
        ]);
        await pumpEventQueue();

        expect(states, hasLength(2));
        expect(
          (states.last as FleetLoaded).counts,
          const FleetStatusCounts(
            all: 8,
            moving: 2,
            idle: 1,
            stopped: 4,
            offline: 1,
          ),
        );
      },
    );
  });
}

/// Copies [vehicle] with a fresh speed reading and ignition (for status ticks).
Vehicle _withSpeedAndIgnition(
  Vehicle vehicle, {
  required Clock clock,
  required double speed,
  required bool ignitionOn,
}) {
  return Vehicle(
    vin: vehicle.vin,
    reg: vehicle.reg,
    model: vehicle.model,
    soc: vehicle.soc,
    range: vehicle.range,
    speed: Reading<double>(
      clock: clock,
      value: speed,
      lastPingAt: vehicle.lastPingAt,
    ),
    batteryTemp: vehicle.batteryTemp,
    odometer: vehicle.odometer,
    lastPingAt: vehicle.lastPingAt,
    ignitionOn: ignitionOn,
  );
}
