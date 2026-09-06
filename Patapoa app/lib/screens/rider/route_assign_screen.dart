import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../../providers/partner_location_provider.dart';
import '../../features/delivery_partner/delivery_partner_models.dart';
import '../../config/map_config.dart';
import '../../services/osm_service.dart';
import '../../services/map_marker_service.dart';
import '../../services/delivery_partner_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RouteAssignScreen extends StatefulWidget {
  const RouteAssignScreen({super.key, this.orderData});

  final Map<String, dynamic>? orderData;

  @override
  State<RouteAssignScreen> createState() => _RouteAssignScreenState();
}

class _RouteAssignScreenState extends State<RouteAssignScreen> {
  final OsmService _osmService = OsmService();
  final DeliveryPartnerService _riderService = DeliveryPartnerService();
  List<LatLng> _routePoints = [];
  late DeliveryOrder _order;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _order = _parseOrder(widget.orderData);
    _initRoute();

    // Initialize custom markers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MapMarkerService().initialize(context);
    });
  }

  Future<void> _launchNavigation() async {
    final lat = (widget.orderData?['delivery_latitude'] as num?)?.toDouble() ?? -6.7924;
    final lng = (widget.orderData?['delivery_longitude'] as num?)?.toDouble() ?? 39.2083;

    final googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final appleMapsUrl = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch maps')));
    }
  }

  Future<void> _initRoute() async {
    // For demo, using dummy coordinates for pickup if not provided
    // In production, orderData would contain pickup_lat/lng
    final pickupLat = (widget.orderData?['pickup_latitude'] as num?)?.toDouble() ?? -6.7924;
    final pickupLng = (widget.orderData?['pickup_longitude'] as num?)?.toDouble() ?? 39.2083;
    final pickup = LatLng(pickupLat, pickupLng);

    // Initial route from a generic point, will be updated by listener
    final result = await _osmService.getRoute(const LatLng(-6.8, 39.22), pickup);
    if (mounted && result != null) setState(() { _routePoints = result.points; });
  }

  DeliveryOrder _parseOrder(Map<String, dynamic>? data) {
    if (data == null) return DeliveryOrder(id: '-', customerName: 'Loading…', customerRating: 0.0, customerPhone: '', pickupLocation: 'Pickup location', dropoffLocation: 'Drop-off location', pickupDistance: 0.0, items: [], totalAmount: 0.0, deliveryFee: 0.0, earnings: 0.0, status: 'assigned', orderDate: DateTime.now(), isCashOnDelivery: false);
    return DeliveryOrder(
      id: data['id']?.toString() ?? '-',
      customerName: data['customer_name'] as String? ?? 'Customer',
      customerRating: (data['customer_rating'] as num?)?.toDouble() ?? 0.0,
      customerPhone: data['customer_phone'] as String? ?? '',
      pickupLocation: data['pickup_location'] as String? ?? 'Pickup',
      dropoffLocation: data['delivery_location'] as String? ?? 'Drop-off',
      pickupDistance: (data['pickup_distance'] as num?)?.toDouble() ?? 0.0,
      items: const [],
      totalAmount: (data['total_amount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (data['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      earnings: (data['earnings'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'assigned',
      orderDate: DateTime.now(),
      isCashOnDelivery: data['is_cash_on_delivery'] as bool? ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topInset = math.max(12.0, MediaQuery.paddingOf(context).top);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(initialCenter: LatLng(-6.7924, 39.2083), initialZoom: 14.0),
            children: [
              TileLayer(
                urlTemplate: MapConfig.tileUrl,
                subdomains: MapConfig.subdomains,
                tileProvider: CancellableNetworkTileProvider(),
              ),
              riverpod.Consumer(builder: (context, ref, _) {
                final riderLocation = ref.watch(partnerLocationProvider);

                // Optional: Dynamic route update logic here or in a provider

                return Stack(children: [
                  if (_routePoints.isNotEmpty) PolylineLayer(polylines: [
                    Polyline(points: _routePoints, color: colorScheme.primary, strokeWidth: 5.0),
                  ]),
                  if (riderLocation != null) MarkerLayer(markers: [
                    Marker(
                      point: riderLocation, 
                      width: 50, height: 50, 
                      child: MapMarkerService().buildRiderMarker(accentColor: colorScheme.primary)
                    ),
                  ]),
                  // Pickup Marker
                  MarkerLayer(markers: [
                    Marker(
                      point: const LatLng(-6.7924, 39.2083), 
                      width: 45, height: 45,
                      child: MapMarkerService().buildMerchantMarker(size: 45)
                    ),
                  ]),
                ]);
              }),
            ],
          ),
          _buildPickupOverlay(colorScheme, textTheme, topInset, _order),
          _buildBottomSheet(colorScheme, textTheme, _order),
        ],
      ),
    );
  }

  Widget _buildPickupOverlay(ColorScheme colorScheme, TextTheme textTheme, double topInset, DeliveryOrder order) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(child: Padding(
        padding: EdgeInsets.fromLTRB(16, topInset, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colorScheme.surface.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.storefront, color: colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PICKUP FROM', style: textTheme.labelSmall),
              Text(order.pickupLocation, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text('${order.pickupDistance.toStringAsFixed(1)} km away', style: textTheme.bodySmall),
            ])),
            FilledButton.icon(
              onPressed: _launchNavigation,
              icon: const Icon(Icons.directions, size: 18),
              label: const Text('Go')
            ),
          ]),
        ),
      )),
    );
  }

  Widget _buildBottomSheet(ColorScheme colorScheme, TextTheme textTheme, DeliveryOrder order) {
    String buttonText = 'Arrived at Pickup';
    String nextStatus = 'picked_up';

    if (order.status == 'picked_up') {
      buttonText = 'Arrived at Customer';
      nextStatus = 'delivered';
    } else if (order.status == 'delivered') {
      buttonText = 'Complete Order';
      nextStatus = 'completed';
    }

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const CircleAvatar(radius: 30, child: Icon(Icons.person)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.customerName, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('${order.customerRating}★ Top Tier', style: textTheme.bodyMedium),
            ])),
            IconButton(
              onPressed: () => _launchCaller(order.customerPhone), 
              icon: const Icon(Icons.call), 
              style: IconButton.styleFrom(backgroundColor: colorScheme.primaryContainer)
            ),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, 
            height: 60, 
            child: FilledButton(
              onPressed: _isUpdating ? null : () => _updateStatus(int.parse(order.id), nextStatus), 
              child: _isUpdating 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(buttonText)
            )
          ),
        ]),
      ),
    );
  }

  Future<void> _launchCaller(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _updateStatus(int orderId, String status) async {
    setState(() => _isUpdating = true);
    try {
      await _riderService.updateOrderStatus(orderId, status).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Connection timed out. Please try again.'),
      );
      if (status == 'completed') {
        if (mounted) {
          context.go('/delivery-partner/home');
        }
        return;
      }
      // Refresh local order state
      if (mounted) {
        setState(() {
          _order = DeliveryOrder(
            id: _order.id,
            customerName: _order.customerName,
            customerRating: _order.customerRating,
            customerPhone: _order.customerPhone,
            pickupLocation: _order.pickupLocation,
            dropoffLocation: _order.dropoffLocation,
            pickupDistance: _order.pickupDistance,
            items: _order.items,
            totalAmount: _order.totalAmount,
            deliveryFee: _order.deliveryFee,
            earnings: _order.earnings,
            status: status,
            orderDate: _order.orderDate,
            isCashOnDelivery: _order.isCashOnDelivery,
          );
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }
}
