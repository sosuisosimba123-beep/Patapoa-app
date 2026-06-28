import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/rider_service.dart';

/// Location Provider — shared GPS state across the app
/// Manages real-time user position, permission status, and address
/// 
/// For riders: uses distance-based throttling to avoid hammering the backend.
/// Updates are only sent to the server when the rider has moved more than
/// [minimumDistance] meters AND at least [minimumInterval] seconds have passed
/// since the last update.
class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final RiderService _riderService = RiderService();

  LatLng? _currentPosition;
  LatLng? get currentPosition => _currentPosition;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _permissionGranted = false;
  bool get permissionGranted => _permissionGranted;

  bool _serviceEnabled = false;
  bool get serviceEnabled => _serviceEnabled;

  StreamSubscription<Position>? _streamSubscription;

  // Throttling state for rider location updates
  LatLng? _lastSentPosition;
  DateTime? _lastSentTime;
  static const double _minimumDistanceMeters = 30.0;
  static const int _minimumIntervalSeconds = 15;
  bool _isSending = false;

  /// Initialize and fetch current position once
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _serviceEnabled = await _locationService.isLocationServiceEnabled();
    if (!_serviceEnabled) {
      _error = 'Location services are disabled. Please enable them in settings.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    final permission = await _locationService.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _permissionGranted = false;
      _error = 'Location permission denied. Please allow access in settings.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _permissionGranted = true;

    // Try to get current position, fallback to last known
    Position? position = await _locationService.getCurrentPosition();
    position ??= await _locationService.getLastKnownPosition();

    if (position != null) {
      _currentPosition = LatLng(position.latitude, position.longitude);
    } else {
      // Default to Dar es Salaam as fallback
      _currentPosition = const LatLng(-6.7924, 39.2083);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh current position manually
  Future<void> refreshPosition() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      _currentPosition = LatLng(position.latitude, position.longitude);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Start continuous location tracking for the rider with backend throttling.
  /// 
  /// This uses a 30m distance filter from the GPS, then an additional check
  /// to only send to the backend when the rider has moved >30m AND at least
  /// 15 seconds have passed since the last server update. This prevents
  /// hammering the API when the rider is idle or stuck in traffic.
  void startRiderTracking({
    double minimumDistance = _minimumDistanceMeters,
    int minimumInterval = _minimumIntervalSeconds,
  }) {
    _locationService.startTracking(
      distanceFilter: minimumDistance.toInt(),
      onUpdate: (position) {
        _currentPosition = LatLng(position.latitude, position.longitude);
        notifyListeners();
        _throttledSendToBackend(
          LatLng(position.latitude, position.longitude),
          minimumDistance: minimumDistance,
          minimumInterval: minimumInterval,
        );
      },
    );
  }

  /// Start continuous location tracking for customers (map display only).
  /// No backend calls — just updates the UI position.
  void startTracking({int distanceFilter = 50}) {
    _locationService.startTracking(
      distanceFilter: distanceFilter,
      onUpdate: (position) {
        _currentPosition = LatLng(position.latitude, position.longitude);
        notifyListeners();
      },
    );
  }

  /// Stop continuous location tracking
  void stopTracking() {
    _locationService.stopTracking();
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  /// Send a throttled location update to the backend.
  /// Only sends if moved > minimumDistance AND minimumInterval has passed.
  Future<void> _throttledSendToBackend(
    LatLng position, {
    double minimumDistance = _minimumDistanceMeters,
    int minimumInterval = _minimumIntervalSeconds,
  }) async {
    // Check minimum interval
    if (_lastSentTime != null) {
      final secondsSince = DateTime.now().difference(_lastSentTime!).inSeconds;
      if (secondsSince < minimumInterval) {
        return;
      }
    }

    // Check minimum distance
    if (_lastSentPosition != null) {
      final distance = _locationService.distanceBetween(
        _lastSentPosition!.latitude,
        _lastSentPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      if (distance < minimumDistance) {
        return;
      }
    }

    // Prevent concurrent sends
    if (_isSending) return;
    _isSending = true;

    try {
      await _riderService.updateLocation(position.latitude, position.longitude);
      _lastSentPosition = position;
      _lastSentTime = DateTime.now();
    } catch (e) {
      debugPrint('Throttled location update error: $e');
    } finally {
      _isSending = false;
    }
  }

  /// Set a position manually (e.g., from address selection)
  void setPosition(LatLng position) {
    _currentPosition = position;
    notifyListeners();
  }

  /// Calculate distance from current position to a target in meters
  double? distanceTo(double lat, double lng) {
    if (_currentPosition == null) return null;
    return _locationService.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
