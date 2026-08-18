import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../services/delivery_partner_service.dart';

/// Riverpod provider for granular partner location state.
/// This avoids rebuilding entire screens when only the map marker needs to move.
final partnerLocationProvider = StateProvider<LatLng?>((ref) => null);

/// Provider for online status
final partnerOnlineStatusProvider = StateProvider<bool>((ref) => false);

/// Service for updating location in the background
class PartnerLocationNotifier extends StateNotifier<LatLng?> {
  final DeliveryPartnerService _partnerService = DeliveryPartnerService();

  PartnerLocationNotifier() : super(null);

  void updateLocation(LatLng newLocation) {
    if (state != newLocation) {
      state = newLocation;
      _partnerService.updateLocation(newLocation.latitude, newLocation.longitude);
    }
  }
}
