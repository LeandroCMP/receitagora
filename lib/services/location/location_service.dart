import 'dart:async';

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  servicesDisabled,
}

class LocationCoordinates {
  const LocationCoordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

abstract class LocationService {
  Future<LocationPermissionStatus> ensurePermission();

  Future<LocationCoordinates?> getCurrentPosition({bool forceFresh = false});

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}
