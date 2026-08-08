import 'dart:convert';

import 'package:byte_beam/core/clock/clock.dart';
import 'package:byte_beam/features/fleet/data/models/vehicle_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test-only clock with a fixed [now] value ("app launch" instant).
class FakeClock implements Clock {
  FakeClock(this._fixed);

  DateTime _fixed;

  @override
  DateTime now() => _fixed;

  void advance(Duration d) => _fixed = _fixed.add(d);
}

/// Loads [assets/seed_fleet.json] from the Flutter asset bundle.
Future<List<Map<String, dynamic>>> loadSeedFleetJson() async {
  final raw = await rootBundle.loadString('assets/seed_fleet.json');
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded.cast<Map<String, dynamic>>();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final launchAt = DateTime(2026, 8, 7, 12);
  final clock = FakeClock(launchAt);

  group('VehicleModel.fromJson (seed_fleet.json)', () {
    late List<VehicleModel> vehicles;

    setUp(() async {
      final raw = await loadSeedFleetJson();
      vehicles = [
        for (final json in raw) VehicleModel.fromJson(json),
      ];
    });

    test('parses all 8 vehicles without throwing', () {
      expect(vehicles, hasLength(8));
      expect(
        vehicles.map((v) => v.vin),
        containsAll(<String>[
          'VIN0001',
          'VIN0002',
          'VIN0003',
          'VIN0004',
          'VIN0005',
          'VIN0006',
          'VIN0007',
          'VIN0008',
        ]),
      );
    });

    test('VIN0006 range/batteryTemp and VIN0008 soc/range null JSON fields '
        'deserialize as null (not 0, not throw)', () {
      final vin0006 = vehicles.singleWhere((v) => v.vin == 'VIN0006');
      expect(vin0006.batteryTempC, isNull);
      expect(vin0006.rangeKm, isNull);

      final vin0008 = vehicles.singleWhere((v) => v.vin == 'VIN0008');
      expect(vin0008.socPercent, isNull);
      expect(vin0008.rangeKm, isNull);
    });

    test('VIN0007 lastPingSecondsAgo 720 converts to absolute DateTime '
        'via injected app-launch Clock', () {
      final vin0007 = vehicles.singleWhere((v) => v.vin == 'VIN0007');
      final domain = vin0007.toDomain(clock);

      expect(
        domain.lastPingAt,
        launchAt.subtract(const Duration(seconds: 720)),
      );
    });
  });
}
