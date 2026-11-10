import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Device only: no reverse geocoding, persistence, server upload or coverage claim.
enum LocationOutcome {
  available,
  denied,
  deniedForever,
  servicesOff,
  inaccurate,
  unavailable
}

class LocationFix {
  const LocationFix(this.outcome,
      {this.latitude, this.longitude, this.accuracy});
  final LocationOutcome outcome;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
}

abstract class ForegroundLocationDevice {
  Future<bool> servicesEnabled();
  Future<LocationPermission> permission();
  Future<LocationPermission> requestPermission();
  Future<Position> position();
  Future<bool> openSettings();
}

class GeolocatorDevice implements ForegroundLocationDevice {
  @override
  Future<bool> servicesEnabled() => Geolocator.isLocationServiceEnabled();
  @override
  Future<LocationPermission> permission() => Geolocator.checkPermission();
  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();
  @override
  Future<Position> position() => Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)));
  @override
  Future<bool> openSettings() => Geolocator.openAppSettings();
}

final foregroundLocationProvider =
    Provider((ref) => ForegroundLocationRepository(GeolocatorDevice()));

class ForegroundLocationRepository {
  ForegroundLocationRepository(this.device);
  final ForegroundLocationDevice device;
  // Input-quality threshold, NOT a guarantee of correct address or delivery area.
  static const maxAccuracyMeters = 100.0;
  Future<LocationFix>? _pending;

  /// Called only by the explicit action. Concurrent taps share one acquisition.
  Future<LocationFix> locate() {
    if (_pending != null) return _pending!;
    final operation = _locate();
    _pending = operation;
    return operation.whenComplete(() => _pending = null);
  }

  Future<LocationFix> _locate() async {
    try {
      if (!await device.servicesEnabled().timeout(const Duration(seconds: 5))) {
        return const LocationFix(LocationOutcome.servicesOff);
      }
      var permission = await device.permission();
      if (permission == LocationPermission.denied)
        permission = await device.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return const LocationFix(LocationOutcome.deniedForever);
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return const LocationFix(LocationOutcome.denied);
      }
      final position =
          await device.position().timeout(const Duration(seconds: 20));
      final age = DateTime.now().difference(position.timestamp);
      if (!position.latitude.isFinite ||
          !position.longitude.isFinite ||
          position.latitude.abs() > 90 ||
          position.longitude.abs() > 180 ||
          !position.accuracy.isFinite ||
          position.accuracy < 0 ||
          age > const Duration(minutes: 2) ||
          age < const Duration(seconds: -30)) {
        return const LocationFix(LocationOutcome.unavailable);
      }
      return LocationFix(
          position.accuracy > maxAccuracyMeters
              ? LocationOutcome.inaccurate
              : LocationOutcome.available,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy);
    } catch (_) {
      return const LocationFix(LocationOutcome.unavailable);
    }
  }

  Future<bool> openSettings() async {
    try {
      return await device.openSettings();
    } catch (_) {
      return false;
    }
  }
}
