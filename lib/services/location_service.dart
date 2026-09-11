// Location Service

import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../utils/error_handler.dart';

/// A simple latitude/longitude pair.
class Coordinates {
  const Coordinates(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  String toString() => 'Coordinates($latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      other is Coordinates &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

class LocationService {
  LocationService({GeolocatorPlatform? geolocator})
      : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _geolocator;

  /// Mean radius of the Earth in kilometers.
  static const double earthRadiusKm = 6371.0;

  /// Runs [action], translating any thrown error into a standardized
  /// [AppException] with a user-friendly message.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw SupabaseErrorHandler.handle(error);
    }
  }

  /// Whether location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() {
    return _guard(() => _geolocator.isLocationServiceEnabled());
  }

  /// Returns the current permission status without prompting the user.
  Future<LocationPermission> checkPermission() {
    return _guard(() => _geolocator.checkPermission());
  }

  /// Requests location permission, prompting the user if necessary.
  ///
  /// Throws an [AppException] if permission is denied or permanently denied.
  Future<LocationPermission> requestPermission() {
    return _guard(() async {
      var permission = await _geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await _geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw const AppException('تم رفض إذن الوصول إلى الموقع');
      }

      if (permission == LocationPermission.deniedForever) {
        throw const AppException(
          'تم رفض إذن الوصول إلى الموقع بشكل دائم، يرجى تفعيله من الإعدادات',
        );
      }

      return permission;
    });
  }

  /// Captures the device's current position.
  ///
  /// Ensures location services are enabled and permission is granted before
  /// requesting a fix.
  Future<Coordinates> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeLimit,
  }) {
    return _guard(() async {
      if (!await _geolocator.isLocationServiceEnabled()) {
        throw const AppException('خدمة الموقع غير مفعّلة');
      }

      await requestPermission();

      final position = await _geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );

      return Coordinates(position.latitude, position.longitude);
    });
  }

  /// Streams position updates as the device moves.
  Stream<Coordinates> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return _geolocator
        .getPositionStream(
          locationSettings: LocationSettings(
            accuracy: accuracy,
            distanceFilter: distanceFilter,
          ),
        )
        .map((position) => Coordinates(position.latitude, position.longitude));
  }

  /// Calculates the distance in kilometers between two coordinates using the
  /// haversine formula.
  double distanceBetween(Coordinates from, Coordinates to) {
    return distanceBetweenPoints(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Calculates the distance in kilometers between two lat/lng pairs using the
  /// haversine formula.
  static double distanceBetweenPoints(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    final dLat = _toRadians(endLatitude - startLatitude);
    final dLng = _toRadians(endLongitude - startLongitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(startLatitude)) *
            math.cos(_toRadians(endLatitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Whether [point] lies within [radiusKm] of [center].
  bool isWithinRadius({
    required Coordinates center,
    required Coordinates point,
    required double radiusKm,
  }) {
    return distanceBetween(center, point) <= radiusKm;
  }

  /// Opens the platform's location settings so the user can enable services.
  Future<bool> openLocationSettings() {
    return _guard(() => _geolocator.openLocationSettings());
  }

  /// Opens the platform's app settings so the user can grant permission.
  Future<bool> openAppSettings() {
    return _guard(() => _geolocator.openAppSettings());
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
}
