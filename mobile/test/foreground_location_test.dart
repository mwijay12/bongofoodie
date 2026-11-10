import 'package:bongo_foodie/data/repositories/foreground_location_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

class Device implements ForegroundLocationDevice {
  bool enabled = true;
  bool fail = false;
  int requests = 0;
  int reads = 0;
  double accuracy = 20;
  double latitude = -6.8;
  DateTime? timestamp;
  LocationPermission initial = LocationPermission.denied;
  LocationPermission result = LocationPermission.whileInUse;
  @override
  Future<bool> servicesEnabled() async => enabled;
  @override
  Future<LocationPermission> permission() async => initial;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return result;
  }

  @override
  Future<bool> openSettings() async => false;
  @override
  Future<Position> position() async {
    reads++;
    if (fail) throw StateError('unavailable');
    return Position(
        latitude: latitude,
        longitude: 39.2,
        timestamp: timestamp ?? DateTime.now(),
        accuracy: accuracy,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0);
  }
}

void main() {
  test(
      'creation is permission-free, action requests once and shares concurrent work',
      () async {
    final d = Device();
    final repo = ForegroundLocationRepository(d);
    expect(d.requests, 0);
    expect(d.reads, 0);
    final results = await Future.wait([repo.locate(), repo.locate()]);
    expect(
        results.every((r) => r.outcome == LocationOutcome.available), isTrue);
    expect(d.requests, 1);
    expect(d.reads, 1);
  });
  test('denied and permanently denied never read coordinates', () async {
    for (final permission in [
      LocationPermission.denied,
      LocationPermission.deniedForever
    ]) {
      final d = Device()..result = permission;
      final fix = await ForegroundLocationRepository(d).locate();
      expect(
          fix.outcome,
          permission == LocationPermission.denied
              ? LocationOutcome.denied
              : LocationOutcome.deniedForever);
      expect(d.reads, 0);
    }
    final d = Device()..initial = LocationPermission.deniedForever;
    await ForegroundLocationRepository(d).locate();
    expect(d.requests, 0);
  });
  test('services off, unavailable, inaccurate, stale and invalid fixes recover',
      () async {
    final off = Device()..enabled = false;
    expect((await ForegroundLocationRepository(off).locate()).outcome,
        LocationOutcome.servicesOff);
    expect(off.requests, 0);
    final fail = Device()..fail = true;
    expect((await ForegroundLocationRepository(fail).locate()).outcome,
        LocationOutcome.unavailable);
    final inaccurate = Device()..accuracy = 500;
    expect((await ForegroundLocationRepository(inaccurate).locate()).outcome,
        LocationOutcome.inaccurate);
    for (final d in [
      Device()..accuracy = double.nan,
      Device()..latitude = 100,
      Device()..timestamp = DateTime.now().subtract(const Duration(minutes: 10))
    ]) {
      expect((await ForegroundLocationRepository(d).locate()).outcome,
          LocationOutcome.unavailable);
    }
  });
  test('coordinates outside Dar do not become a serviceable address', () async {
    final d = Device()..latitude = 51.5;
    final fix = await ForegroundLocationRepository(d).locate();
    expect(fix.outcome, LocationOutcome.available);
    expect(fix.latitude,
        51.5); // Device fix only; no ward/address/serviceability conversion.
  });
}
