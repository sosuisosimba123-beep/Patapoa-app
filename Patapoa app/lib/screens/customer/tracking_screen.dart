import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart' as provider;
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/websocket_service.dart';
import '../../providers/location_provider.dart';
import '../../services/osm_service.dart';
import '../../services/map_marker_service.dart';
import '../../config/map_config.dart';
import '../../widgets/liquid_glass_container.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, required this.order});
  final Order order;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final OsmService _osmService = OsmService();
  final WebSocketService _wsService = WebSocketService();
  late final AnimationController _animController;
  LatLng? _riderLocation;
  List<LatLng> _routePoints = [];
  StreamSubscription? _wsSubscription;
  int _eta = 15;
  Timer? _timer;
  String _currentStatus = 'placed';
  String _currentStatusNote = 'Order placed';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
    _currentStatusNote = _getStatusNote(_currentStatus);
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _fetchLiveLocation();
    _initWebSocket();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchLiveLocation()); // Fallback polling
    
    // Initialize custom markers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MapMarkerService().initialize(context);
    });
  }

  void _initWebSocket() {
    if (widget.order.rider?['id'] != null) {
      final partnerId = (widget.order.rider!['id'] as num).toInt();
      _wsSubscription = _wsService.listenToPartnerLocation(partnerId).listen((data) {
        if (mounted) {
           final lat = (data['latitude'] as num).toDouble();
           final lng = (data['longitude'] as num).toDouble();
           _updateMap(LatLng(lat, lng));
        }
      });
    }
  }

  void _updateMap(LatLng newPos) async {
      // Calculate destination
      final destination = widget.order.address != null 
          ? LatLng(
              (widget.order.address!['latitude'] as num).toDouble(),
              (widget.order.address!['longitude'] as num).toDouble(),
            )
          : const LatLng(-6.7924, 39.2083);

      final route = await _osmService.getRoute(newPos, destination);
      if (mounted) {
        setState(() {
          _riderLocation = newPos;
          if (route != null) {
             _routePoints = route.points;
             _eta = (route.travelTimeInSeconds / 60).ceil();
          }
        });
      }
  }

  String _getStatusNote(String status) {
    return switch (status) {
      'placed' => 'Order placed, waiting for confirmation',
      'confirmed' => 'Order confirmed, preparing your items',
      'paid' => 'Payment received, preparing your items',
      'processing' => 'Merchant is preparing your order',
      'out_for_delivery' => 'Rider is on the way to your location',
      'delivered' => 'Order delivered! Enjoy your meal',
      'cancelled' => 'Order has been cancelled',
      _ => 'Processing your order',
    };
  }

  double _getStatusProgress(String status) {
    return switch (status) {
      'placed' => 0.15,
      'confirmed' => 0.3,
      'paid' => 0.4,
      'processing' => 0.55,
      'out_for_delivery' => 0.8,
      'delivered' => 1.0,
      'cancelled' => 0.0,
      _ => 0.15,
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wsSubscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveLocation() async {
    try {
      final data = await _orderService.getOrderTracking(widget.order.id);
      if (mounted) {
        final riderLat = (data['rider']?['current_latitude'] as num?)?.toDouble();
        final riderLng = (data['rider']?['current_longitude'] as num?)?.toDouble();
        
        final dropoffLat = (data['dropoff_location']?['latitude'] as num?)?.toDouble();
        final dropoffLng = (data['dropoff_location']?['longitude'] as num?)?.toDouble();

        setState(() {
          _currentStatus = data['status'] ?? _currentStatus;
          _currentStatusNote = _getStatusNote(_currentStatus);
          if (data['estimated_duration'] != null) {
            _eta = (data['estimated_duration'] as num).toInt();
          }
        });

        if (riderLat != null && riderLng != null && dropoffLat != null && dropoffLng != null) {
          final newRiderLocation = LatLng(riderLat, riderLng);
          final destination = LatLng(dropoffLat, dropoffLng);

          try {
            final route = await _osmService.getRoute(newRiderLocation, destination);
            if (route != null && mounted) {
              setState(() {
                _routePoints = route.points;
                _eta = (route.travelTimeInSeconds / 60).ceil();
              });
            }
          } catch (e) {
            debugPrint('Routing error: $e');
          }

          setState(() {
            _riderLocation = newRiderLocation;
          });
          
          // Auto-fit bounds on the first fetch
          if (_routePoints.isNotEmpty && widget.order.status == 'out_for_delivery') {
             // _mapController.fitCamera(...) would be ideal here if using a controller
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching tracking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userPos = provider.Provider.of<LocationProvider>(context).currentPosition;
    
    // The fixed destination for the order
    final destination = widget.order.address != null 
        ? LatLng(
            (widget.order.address!['latitude'] as num).toDouble(),
            (widget.order.address!['longitude'] as num).toDouble(),
          )
        : const LatLng(-6.7924, 39.2083);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tileUrl = isDarkMode ? MapConfig.cartoDarkUrl : MapConfig.cartoVoyagerUrl;

    return Scaffold(
      body: Stack(children: [
        // 1. Immersive Map
        Positioned.fill(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _riderLocation ?? destination,
              initialZoom: 14.0
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                subdomains: MapConfig.subdomains,
                userAgentPackageName: 'com.patapoa.app',
                tileProvider: CancellableNetworkTileProvider(),
              ),
              if (_routePoints.isNotEmpty) PolylineLayer(polylines: [
                Polyline(points: _routePoints, color: colorScheme.primary, strokeWidth: 5),
              ]),
              if (_riderLocation != null) MarkerLayer(markers: [
                Marker(
                  point: _riderLocation!, 
                  width: 60, height: 60, 
                  child: MapMarkerService().buildRiderMarker(accentColor: colorScheme.primary)
                ),
              ]),
              MarkerLayer(markers: [
                Marker(
                  point: destination, 
                  width: 50, height: 50,
                  child: MapMarkerService().buildMerchantMarker(size: 50)
                ),
              ]),
              // Show user's current device location as a faint blue dot
              if (userPos != null) MarkerLayer(markers: [
                Marker(point: userPos, width: 16, height: 16, child: Container(decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
              ]),
            ],
          ),
        ),

        // 2. Status Bar Overlay (Frosted style)
        Positioned(
          top: MediaQuery.paddingOf(context).top + 10,
          left: 16, right: 16,
          child: _StatusBar(displayId: widget.order.displayId, eta: _eta, status: _currentStatus),
        ),

        // 3. Bottom Order Info
        _buildBottomCard(colorScheme, textTheme),
      ]),
    );
  }

  Widget _buildBottomCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Positioned(
      bottom: 24, left: 16, right: 16,
      child: LiquidGlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: 32,
        opacity: 0.15,
        blur: 20,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: widget.order.rider?['user']?['profile_image'] != null
                ? NetworkImage(widget.order.rider?['user']?['profile_image'])
                : null,
              child: widget.order.rider?['user']?['profile_image'] == null ? const Icon(Icons.person, size: 28) : null,
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.order.rider?['user']?['name'] ?? 'Searching for Rider...', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('${widget.order.rider?['rating'] ?? 4.8} ★ • ${widget.order.rider != null ? 'Top Tier Rider' : 'Assigning soon'}', style: textTheme.bodySmall),
            ])),
            if (widget.order.rider?['user']?['phone'] != null)
              IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.call)),
          ]),
          const Divider(height: 32, color: Colors.white24),
          LinearProgressIndicator(
            value: _getStatusProgress(_currentStatus),
            minHeight: 6,
            backgroundColor: Colors.white10,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 12),
          Text(_currentStatusNote, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 50, child: OutlinedButton(
            onPressed: () => context.pop(), 
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Order Details')
          )),
        ]),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String displayId;
  final int eta;
  final String status;
  const _StatusBar({required this.displayId, required this.eta, required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LiquidGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 20,
      opacity: 0.8,
      blur: 15,
      child: Row(children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Order $displayId', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          Text(status == 'delivered' ? 'Arrived!' : 'Arriving in $eta mins', style: const TextStyle(fontSize: 12)),
        ]),
        const Spacer(),
        if (status == 'out_for_delivery')
          const Badge(label: Text('LIVE'), child: Icon(Icons.sensors, size: 20))
        else
          Icon(Icons.access_time, size: 20, color: colorScheme.outline),
      ]),
    );
  }
}
