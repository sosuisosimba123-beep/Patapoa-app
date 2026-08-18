import 'package:flutter/material.dart';

class MapMarkerService {
  static final MapMarkerService _instance = MapMarkerService._internal();
  factory MapMarkerService() => _instance;
  MapMarkerService._internal();

  bool _isInitialized = false;

  final String merchantPinAsset = 'assets/images/map_merchant_pin.jpg.jpg';
  final String riderPinAsset = 'assets/images/map_rider_pin.jpg.jpg';

  /// Precache assets for smoother rendering on the map
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    
    await Future.wait([
      precacheImage(AssetImage(merchantPinAsset), context),
      precacheImage(AssetImage(riderPinAsset), context),
    ]);
    
    _isInitialized = true;
  }

  /// Branded Merchant Marker
  Widget buildMerchantMarker({double size = 45.0, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.location_on, size: size, color: Colors.red),
          Positioned(
            top: size * 0.15,
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(merchantPinAsset),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Branded Rider Marker
  Widget buildRiderMarker({double size = 50.0, Color? accentColor}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse Effect
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (accentColor ?? Colors.blue).withValues(alpha: 0.2),
          ),
        ),
        // Branded Icon
        Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: ClipOval(
              child: Image.asset(
                riderPinAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.delivery_dining, 
                  color: accentColor ?? Colors.blue,
                  size: size * 0.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
