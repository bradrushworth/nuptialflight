import 'package:geolocator/geolocator.dart';

/// Builds a [Position] from bare coordinates (cache restores, report
/// queries). Geolocator's constructor demands every accuracy/motion field,
/// so this is the one place the zero-filled boilerplate lives.
Position syntheticPosition(double latitude, double longitude) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
}
