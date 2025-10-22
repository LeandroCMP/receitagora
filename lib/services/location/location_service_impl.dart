import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

class LocationServiceImpl implements LocationService {
  LocationServiceImpl({GeolocatorPlatform? geolocator})
      : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _geolocator;

  @override
  Future<LocationPermissionStatus> ensurePermission() async {
    final serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.servicesDisabled;
    }

    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.permanentlyDenied;
    }

    if (permission == LocationPermission.denied) {
      return LocationPermissionStatus.denied;
    }

    return LocationPermissionStatus.granted;
  }

  @override
  Future<LocationCoordinates?> getCurrentPosition({bool forceFresh = false}) async {
    try {
      Position? position;
      if (!forceFresh) {
        position = await _geolocator.getLastKnownPosition();
      }
      position ??=
          await _geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      if (position == null) {
        return null;
      }
      return LocationCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> openAppSettings() {
    return _geolocator.openAppSettings();
  }

  @override
  Future<bool> openLocationSettings() {
    return _geolocator.openLocationSettings();
  }
}
