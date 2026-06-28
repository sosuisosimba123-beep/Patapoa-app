import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class AddressSuggestion {
  const AddressSuggestion({required this.label, required this.position});

  final String label;
  final LatLng position;
}

/// Location Service — wraps Geolocator and provides real-time GPS capabilities
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;

  /// Get the current position once (high accuracy)
  Future<Position?> getCurrentPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get the last known position (fast, low power)
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  /// Stream of position updates (for live tracking)
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 50, // meters
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Start listening to position updates
  void startTracking({
    required Function(Position) onUpdate,
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 50,
  }) {
    _positionStream?.cancel();
    _positionStream = getPositionStream(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    ).listen(onUpdate);
  }

  /// Stop listening to position updates
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  /// Calculate distance between two coordinates in meters
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }
}
