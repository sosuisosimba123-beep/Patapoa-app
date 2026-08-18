import 'package:latlong2/latlong.dart';

class OperationalZone {
  final String cityName;
  final LatLng center;
  final double radiusKm;

  OperationalZone({
    required this.cityName,
    required this.center,
    required this.radiusKm,
  });
}

class OperationalConfig {
  static final List<OperationalZone> activeZones = [
    OperationalZone(
      cityName: 'Dar es Salaam',
      center: const LatLng(-6.7924, 39.2083),
      radiusKm: 25.0,
    ),
    OperationalZone(
      cityName: 'Moshi',
      center: const LatLng(-3.3488, 37.3400),
      radiusKm: 15.0,
    ),
  ];

  static bool isWithinAnyZone(LatLng position, {double? distancePaddingKm}) {
    final Distance distance = const Distance();
    for (var zone in activeZones) {
      final double distanceMeters = distance.as(
        LengthUnit.Meter,
        position,
        zone.center,
      );
      if (distanceMeters <= (zone.radiusKm + (distancePaddingKm ?? 0)) * 1000) {
        return true;
      }
    }
    return false;
  }

  static OperationalZone? getNearestZone(LatLng position) {
    final Distance distance = const Distance();
    OperationalZone? nearest;
    double minDistance = double.infinity;

    for (var zone in activeZones) {
      final double d = distance.as(LengthUnit.Meter, position, zone.center);
      if (d < minDistance) {
        minDistance = d;
        nearest = zone;
      }
    }
    return nearest;
  }
}
