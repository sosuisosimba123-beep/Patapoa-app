import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../services/osm_service.dart';

class OsmTester {
  static final _service = OsmService();

  /// Runs a full check of the OSM integration
  static Future<void> runFullDiagnostic() async {
    debugPrint('🚀 Starting OSM Diagnostic...');

    // 1. Test Search
    debugPrint('🔍 Testing Search (Query: "Dar es Salaam")...');
    final searchResults = await _service.search('Dar es Salaam');
    if (searchResults.isNotEmpty) {
      debugPrint('✅ Search Working: Found ${searchResults.length} results.');
      debugPrint('   First Result: ${searchResults.first['display_name']}');
    } else {
      debugPrint('❌ Search Failed or no results.');
    }

    // 2. Test Geocoding
    const testPoint = LatLng(-6.7924, 39.2083);
    debugPrint('📍 Testing Reverse Geocode ($testPoint)...');
    final address = await _service.reverseGeocode(testPoint);
    if (address != null) {
      debugPrint('✅ Geocoding Working: $address');
    } else {
      debugPrint('❌ Geocoding Failed.');
    }

    // 3. Test Routing
    debugPrint('🚗 Testing Routing...');
    const start = LatLng(-6.7924, 39.2083);
    const end = LatLng(-6.8124, 39.2283);
    final route = await _service.getRoute(start, end);
    if (route != null) {
      debugPrint('✅ Routing Working: Path found with ${route.points.length} points.');
      debugPrint('   Estimated Travel Time: ${route.travelTimeInSeconds} seconds');
    } else {
      debugPrint('❌ Routing Failed.');
    }

    debugPrint('🏁 Diagnostic Complete.');
  }
}
