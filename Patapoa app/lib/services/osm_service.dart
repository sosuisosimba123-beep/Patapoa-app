import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class RouteResult {
  final List<LatLng> points;
  final int travelTimeInSeconds;
  final double lengthInMeters;

  RouteResult({
    required this.points,
    required this.travelTimeInSeconds,
    required this.lengthInMeters,
  });
}

class OsmService {
  // Nominatim for Geocoding
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';
  // OSRM for Routing (Using public demo server, recommend self-hosting for production)
  static const String _osrmUrl = 'https://router.project-osrm.org';

  /// Search for addresses or places (Forward Geocoding)
  Future<List<Map<String, dynamic>>> search(String query) async {
    final url = '$_nominatimUrl/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'PatapoaApp/1.0', // Required by Nominatim policy
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => {
          'display_name': item['display_name'],
          'lat': double.parse(item['lat']),
          'lon': double.parse(item['lon']),
          'address': item['address'],
        }).toList();
      }
    } catch (e) {
      debugPrint('Nominatim Forward Geocode Error: $e');
    }
    return [];
  }

  /// Calculate route (OSRM)
  Future<RouteResult?> getRoute(LatLng start, LatLng end) async {
    final url = '$_osrmUrl/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;
          
          final List<LatLng> points = geometry.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();

          return RouteResult(
            points: points,
            travelTimeInSeconds: (route['duration'] as num).toInt(),
            lengthInMeters: (route['distance'] as num).toDouble(),
          );
        }
      }
    } catch (e) {
      debugPrint('OSRM Routing Error: $e');
    }
    return null;
  }

  /// Reverse geocoding: coordinates to address details (Nominatim)
  Future<Map<String, dynamic>?> reverseGeocodeDetails(LatLng position) async {
    final url = '$_nominatimUrl/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json&addressdetails=1';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'PatapoaApp/1.0',
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addr = data['address'];
        return {
          'freeformAddress': data['display_name'],
          'municipality': addr['city'] ?? addr['town'] ?? addr['village'],
          'countrySecondarySubdivision': addr['state_district'] ?? addr['county'] ?? addr['region'],
          'postalCode': addr['postcode'],
        };
      }
    } catch (e) {
      debugPrint('Nominatim Reverse Geocode Error: $e');
    }
    return null;
  }

  /// Reverse geocoding: coordinates to address (String)
  Future<String?> reverseGeocode(LatLng position) async {
    final details = await reverseGeocodeDetails(position);
    return details?['freeformAddress'];
  }
}
