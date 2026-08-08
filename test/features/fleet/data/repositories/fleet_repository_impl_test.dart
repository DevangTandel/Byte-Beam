import 'dart:async';

import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/fleet/data/datasources/telemetry_data_source.dart';
import 'package:byte_beam/features/fleet/data/models/vehicle_model.dart';
import 'package:byte_beam/features/fleet/data/repositories/fleet_repository_impl.dart';
import 'package:byte_beam/features/fleet/domain/entities/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([TelemetryDataSource])
import 'fleet_repository_impl_test.mocks.dart';

/// Test-only clock with a fixed [now] value ("app launch" instant).
class FakeClock implements Clock {
  FakeClock(this._fixed);

  DateTime _fixed;

  @override
  DateTime now() => _fixed;

  void advance(Duration d) => _fixed = _fixed.add(d);
}

void main() {
  final launchAt = DateTime(2026, 8, 7, 12, 0, 0);

  late MockTelemetryDataSource mockDataSource;
  late FakeClock launchClock;
  late FleetRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockTelemetryDataSource();
    launchClock = FakeClock(launchAt);
    repository = FleetRepositoryImpl(
      dataSource: mockDataSource,
      launchClock: launchClock,
    );
  });

  group('FleetRepositoryImpl.watchFleet', () {
    test('maps VehicleModel stream emissions to domain Vehicle streams',
        () async {
      final modelsController = StreamController<List<VehicleModel>>();
      addTearDown(() async {
        await modelsController.close();
      });

      when(mockDataSource.watchFleet())
          .thenAnswer((_) => modelsController.stream);

      const model = VehicleModel(
        vin: 'VIN0003',
        reg: 'MH 12 EF 9012',
        model: 'eVan 30',
        socPercent: 17,
        rangeKm: 34,
        speedKmh: 38,
        ignitionOn: true,
        batteryTempC: 33,
        odometerKm: 12780,
        lastPingSecondsAgo: 5,
      );

      const nullables = VehicleModel(
        vin: 'VIN0008',
        reg: 'KA 41 PQ 8642',
        model: 'eVan 30',
        socPercent: null,
        rangeKm: null,
        speedKmh: 0,
        ignitionOn: false,
        batteryTempC: 25,
        odometerKm: 23100,
        lastPingSecondsAgo: 55,
      );

      final expectation = expectLater(
        repository.watchFleet(),
        emitsInOrder([
          predicate<List<Vehicle>>((vehicles) {
            expect(vehicles, hasLength(1));
            final vehicle = vehicles.single;
            final expected = model.toDomain(launchClock);
            expect(vehicle.vin, expected.vin);
            expect(vehicle.reg, expected.reg);
            expect(vehicle.model, expected.model);
            expect(vehicle.soc.value, expected.soc.value);
            expect(vehicle.range.value, expected.range.value);
            expect(vehicle.speed.value, expected.speed.value);
            expect(vehicle.batteryTemp.value, expected.batteryTemp.value);
            expect(vehicle.odometer.value, expected.odometer.value);
            expect(vehicle.ignitionOn, expected.ignitionOn);
            expect(
              vehicle.lastPingAt,
              launchAt.subtract(const Duration(seconds: 5)),
            );
            return true;
          }),
          predicate<List<Vehicle>>((vehicles) {
            expect(vehicles, hasLength(1));
            final mapped = vehicles.single;
            expect(mapped.vin, 'VIN0008');
            expect(mapped.soc.value, isNull);
            expect(mapped.range.value, isNull);
            expect(mapped.batteryTemp.value, 25);
            expect(
              mapped.lastPingAt,
              launchAt.subtract(const Duration(seconds: 55)),
            );
            return true;
          }),
        ]),
      );

      modelsController
        ..add([model])
        ..add([nullables]);

      await expectation;
      verify(mockDataSource.watchFleet()).called(1);
    });

    test('dispose forwards to TelemetryDataSource.dispose', () {
      repository.dispose();
      verify(mockDataSource.dispose()).called(1);
    });
  });
}
