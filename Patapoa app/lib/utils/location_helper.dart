import 'package:geolocator/geolocator.dart';

class LocationHelper {
  /// Captures the current device coordinates after verifying permissions.
  /// Returns a Map containing 'latitude' and 'longitude' keys.
  static Future<Map<String, double>> getCurrentCoordinates() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // 2. Check and request permissions.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    } 

    // 3. When we have permission, access the position of the device.
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  }
}
