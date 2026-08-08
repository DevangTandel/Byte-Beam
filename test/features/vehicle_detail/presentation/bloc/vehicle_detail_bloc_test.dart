import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/alerts/domain/alert_persistence.dart';
import 'package:byte_beam/features/alerts/domain/entities/alert.dart';
import 'package:byte_beam/features/alerts/presentation/bloc/alerts_cubit.dart';
import 'package:byte_beam/features/fleet/data/models/vehicle_model.dart';
import 'package:byte_beam/features/fleet/domain/entities/reading.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:byte_beam/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:byte_beam/features/fleet/domain/rules/staleness_evaluator.dart';
import 'package:byte_beam/features/fleet/domain/rules/status_resolver.dart';
import 'package:byte_beam/features/vehicle_detail/presentation/bloc/vehicle_detail_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FleetRepository, AlertPersistence])
import 'vehicle_detail_bloc_test.mocks.dart';

/// Test-only clock with a fixed [now] value.
class FakeClock implements Clock {
  FakeClock(this._fixed);

  DateTime _fixed;

  @override
  DateTime now() => _fixed;

  void advance(Duration d) => _fixed = _fixed.add(d);
}

void main() {
  final now = DateTime(2026, 8, 7, 12, 10, 0);
  const vin = 'VIN0003';
  const otherVin = 'VIN0001';

  late FakeClock clock;
  late MockFleetRepository mockRepository;
  late MockAlertPersistence mockPersistence;
  late StreamController<List<Vehicle>> fleetController;
  late StreamController<List<Vehicle>> alertsVehicleController;
  late AlertsCubit alertsCubit;

  Vehicle buildVehicle({
    required String vehicleVin,
    double? soc = 50,
    double? range = 100,
    double speed = 38,
    double? batteryTemp = 30,
    double odometer = 12780,
    Duration readingAge = const Duration(minutes: 1),
    bool? ignitionOn = true,
  }) {
    final ping = now.subtract(readingAge);
    Reading<double> reading(double? value) => Reading<double>(
          clock: clock,
          value: value,
          lastPingAt: ping,
        );

    return Vehicle(
      vin: vehicleVin,
      reg: 'REG-$vehicleVin',
      model: 'eVan 30',
      soc: reading(soc),
      range: reading(range),
      speed: reading(speed),
      batteryTemp: reading(batteryTemp),
      odometer: reading(odometer),
      lastPingAt: ping,
      ignitionOn: ignitionOn,
    );
  }

  VehicleDetailBloc buildBloc() => VehicleDetailBloc(
        vin: vin,
        repository: mockRepository,
        alertsCubit: alertsCubit,
        clock: clock,
      );

  setUp(() {
    clock = FakeClock(now);
    mockRepository = MockFleetRepository();
    mockPersistence = MockAlertPersistence();
    fleetController = StreamController<List<Vehicle>>.broadcast();
    alertsVehicleController = StreamController<List<Vehicle>>.broadcast();
    when(mockRepository.watchFleet())
        .thenAnswer((_) => fleetController.stream);
    alertsCubit = AlertsCubit(
      vehicleStream: alertsVehicleController.stream,
      clock: clock,
      persistence: mockPersistence,
    );
  });

  tearDown(() async {
    await alertsCubit.close();
    await fleetController.close();
    await alertsVehicleController.close();
  });

  group('VehicleDetailBloc', () {
    blocTest<VehicleDetailBloc, VehicleDetailState>(
      'loads the matching vin with status, per-parameter verdicts, and alerts',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const VehicleDetailStarted());
        final vehicle = buildVehicle(vehicleVin: vin, soc: 50, speed: 38);
        // Alerts first so cubit.state is ready before the fleet emission.
        alertsVehicleController.add([vehicle]);
        await pumpEventQueue();
        fleetController.add([
          buildVehicle(vehicleVin: otherVin, soc: 78, speed: 42),
          vehicle,
        ]);
        await pumpEventQueue();
      },
      expect: () => [
        isA<VehicleDetailLoaded>()
            .having((s) => s.vehicle.vin, 'vin', vin)
            .having((s) => s.status, 'status', VehicleStatus.moving)
            .having((s) => s.verdicts.soc, 'soc verdict', Verdict.normal)
            .having((s) => s.verdicts.range, 'range verdict', Verdict.normal)
            .having((s) => s.verdicts.speed, 'speed verdict', Verdict.normal)
            .having(
              (s) => s.verdicts.batteryTemp,
              'batteryTemp verdict',
              Verdict.normal,
            )
            .having(
              (s) => s.verdicts.odometer,
              'odometer verdict',
              Verdict.normal,
            )
            .having((s) => s.alerts, 'alerts', isEmpty),
      ],
    );

    blocTest<VehicleDetailBloc, VehicleDetailState>(
      'SOC below threshold yields alert verdict; null SOC yields null verdict',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const VehicleDetailStarted());
        final lowSoc = buildVehicle(vehicleVin: vin, soc: 15);
        alertsVehicleController.add([lowSoc]);
        await pumpEventQueue();
        fleetController.add([lowSoc]);
        await pumpEventQueue();

        final missingSoc = buildVehicle(vehicleVin: vin, soc: null);
        alertsVehicleController.add([missingSoc]);
        await pumpEventQueue();
        fleetController.add([missingSoc]);
        await pumpEventQueue();
      },
      expect: () => [
        isA<VehicleDetailLoaded>()
            .having((s) => s.verdicts.soc, 'soc alert', Verdict.alert)
            .having(
              (s) => s.alerts.any((a) => a.kind == AlertKind.lowBattery),
              'has lowBattery alert',
              isTrue,
            ),
        // Alerts clear on null SOC (alerts stream), then fleet updates verdicts.
        isA<VehicleDetailLoaded>()
            .having(
              (s) => s.alerts.where((a) => a.kind == AlertKind.lowBattery),
              'lowBattery cleared',
              isEmpty,
            ),
        isA<VehicleDetailLoaded>()
            .having((s) => s.verdicts.soc, 'soc null verdict', isNull)
            .having(
              (s) => s.alerts.where((a) => a.kind == AlertKind.lowBattery),
              'lowBattery still cleared',
              isEmpty,
            ),
      ],
    );

    blocTest<VehicleDetailBloc, VehicleDetailState>(
      'stale battery temp yields stale verdict regardless of value',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const VehicleDetailStarted());
        final staleHot = buildVehicle(
          vehicleVin: vin,
          batteryTemp: 99,
          readingAge: const Duration(minutes: 5, seconds: 1),
          speed: 0,
          ignitionOn: false,
        );
        alertsVehicleController.add([staleHot]);
        await pumpEventQueue();
        fleetController.add([staleHot]);
        await pumpEventQueue();
      },
      expect: () => [
        isA<VehicleDetailLoaded>().having(
          (s) => s.verdicts.batteryTemp,
          'stale batteryTemp',
          Verdict.stale,
        ),
      ],
    );

    blocTest<VehicleDetailBloc, VehicleDetailState>(
      'exposes only alerts for the detail vin from AlertsCubit',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const VehicleDetailStarted());
        final target = buildVehicle(vehicleVin: vin, soc: 15);
        final other = buildVehicle(vehicleVin: otherVin, soc: 8, speed: 0);
        alertsVehicleController.add([target, other]);
        await pumpEventQueue();
        fleetController.add([target, other]);
        await pumpEventQueue();
      },
      expect: () => [
        isA<VehicleDetailLoaded>()
            .having((s) => s.vehicle.vin, 'vin', vin)
            .having(
              (s) => s.alerts.every((a) => a.vin == vin),
              'alerts only for detail vin',
              isTrue,
            )
            .having(
              (s) => s.alerts.any((a) => a.vin == otherVin),
              'no foreign alerts',
              isFalse,
            )
            .having((s) => s.alerts, 'alerts', isNotEmpty),
      ],
    );

    test(
      'VIN0007 from seed_fleet.json: SOC 8% at lastPingSecondsAgo 720 '
      'is STALE not ALERT (staleness overrides critical SOC breach)',
      () {
        final decoded =
            jsonDecode(File('assets/seed_fleet.json').readAsStringSync())
                as List<dynamic>;
        final model = VehicleModel.fromJson(
          decoded.cast<Map<String, dynamic>>().singleWhere(
                (json) => json['vin'] == 'VIN0007',
              ),
        );

        expect(model.vin, 'VIN0007');
        expect(model.socPercent, 8);
        expect(model.lastPingSecondsAgo, 720);

        final vehicle = model.toDomain(clock);
        final socVerdict = evaluateStaleness(vehicle.soc, kSocBounds, clock);

        expect(socVerdict, Verdict.stale);
        expect(socVerdict, isNot(Verdict.alert));

        // Same 8% SOC when fresh would breach and show ALERT — proves the
        // VIN0007 case is STALE because of age, not because 8% is in-bounds.
        final freshEightPercent = buildVehicle(
          vehicleVin: 'VIN0007',
          soc: 8,
          readingAge: const Duration(minutes: 1),
        );
        expect(
          evaluateStaleness(freshEightPercent.soc, kSocBounds, clock),
          Verdict.alert,
        );
      },
    );

    blocTest<VehicleDetailBloc, VehicleDetailState>(
      'VIN0007 SOC 8% with seed-age ping yields STALE soc verdict, not ALERT',
      build: () => VehicleDetailBloc(
        vin: 'VIN0007',
        repository: mockRepository,
        alertsCubit: alertsCubit,
        clock: clock,
      ),
      act: (bloc) async {
        bloc.add(const VehicleDetailStarted());
        final vin0007 = buildVehicle(
          vehicleVin: 'VIN0007',
          soc: 8,
          range: 15,
          speed: 0,
          batteryTemp: 36,
          odometer: 91004,
          readingAge: const Duration(seconds: 720),
          ignitionOn: true,
        );
        alertsVehicleController.add([vin0007]);
        await pumpEventQueue();
        fleetController.add([vin0007]);
        await pumpEventQueue();
      },
      expect: () => [
        isA<VehicleDetailLoaded>()
            .having((s) => s.vehicle.vin, 'vin', 'VIN0007')
            .having((s) => s.vehicle.soc.value, 'soc 8%', 8)
            .having((s) => s.status, 'offline', VehicleStatus.offline)
            .having((s) => s.verdicts.soc, 'STALE not ALERT', Verdict.stale),
      ],
    );
  });
}
