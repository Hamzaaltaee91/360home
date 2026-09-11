import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dabberli/services/location_service.dart';
import 'package:dabberli/utils/error_handler.dart';

class MockGeolocatorPlatform extends Mock implements GeolocatorPlatform {}

class MockPosition extends Mock implements Position {}

void main() {
  late MockGeolocatorPlatform geolocator;
  late LocationService service;

  setUp(() {
    geolocator = MockGeolocatorPlatform();
    service = LocationService(geolocator: geolocator);
  });

  group('distanceBetweenPoints', () {
    test('returns 0 for identical points', () {
      expect(
        LocationService.distanceBetweenPoints(25.0, 55.0, 25.0, 55.0),
        0,
      );
    });

    test('computes the haversine distance between two cities', () {
      // Dubai to Abu Dhabi is roughly 130 km.
      final distance = LocationService.distanceBetweenPoints(
        25.2048,
        55.2708,
        24.4539,
        54.3773,
      );

      expect(distance, greaterThan(120));
      expect(distance, lessThan(140));
    });
  });

  group('isWithinRadius', () {
    test('returns true when the point is inside the radius', () {
      const center = Coordinates(25.2048, 55.2708);
      const point = Coordinates(25.2100, 55.2750);

      expect(
        service.isWithinRadius(center: center, point: point, radiusKm: 5),
        isTrue,
      );
    });

    test('returns false when the point is outside the radius', () {
      const center = Coordinates(25.2048, 55.2708);
      const point = Coordinates(24.4539, 54.3773);

      expect(
        service.isWithinRadius(center: center, point: point, radiusKm: 5),
        isFalse,
      );
    });
  });

  group('requestPermission', () {
    test('returns granted permission without prompting', () async {
      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);

      expect(
        await service.requestPermission(),
        LocationPermission.whileInUse,
      );
      verifyNever(() => geolocator.requestPermission());
    });

    test('throws AppException when permission is denied', () async {
      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(() => geolocator.requestPermission())
          .thenAnswer((_) async => LocationPermission.denied);

      expect(
        () => service.requestPermission(),
        throwsA(isA<AppException>()),
      );
    });

    test('throws AppException when permission is denied forever', () async {
      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.deniedForever);

      expect(
        () => service.requestPermission(),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('getCurrentLocation', () {
    test('throws AppException when location services are disabled', () async {
      when(() => geolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => false);

      expect(
        () => service.getCurrentLocation(),
        throwsA(isA<AppException>()),
      );
    });

    test('returns coordinates when services and permission are granted',
        () async {
      when(() => geolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);

      final position = MockPosition();
      when(() => position.latitude).thenReturn(25.2048);
      when(() => position.longitude).thenReturn(55.2708);
      when(
        () => geolocator.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenAnswer((_) async => position);

      final coordinates = await service.getCurrentLocation();

      expect(coordinates, const Coordinates(25.2048, 55.2708));
    });
  });
}
