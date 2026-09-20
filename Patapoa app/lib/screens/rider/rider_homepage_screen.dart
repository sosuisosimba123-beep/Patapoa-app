import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../../services/delivery_partner_service.dart';
import '../../services/map_marker_service.dart';
import '../../services/pocketbase_services.dart';
import '../../services/pocketbase_services.dart';
import '../../providers/location_provider.dart';
import '../../providers/partner_location_provider.dart';
import '../../utils/app_permissions.dart';
import '../../config/map_config.dart';
import '../../widgets/liquid_glass_container.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  final DeliveryPartnerService _riderService = DeliveryPartnerService();
  final _scrollController = ScrollController();

  bool _isOnline = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _orders = [];
  Timer? _locationTimer;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadOrders();
    _broadcastStatus();

    // Initialize custom markers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MapMarkerService().initialize(context);
    });
  }

  Future<void> _broadcastStatus() async {
    try {
      final userId = pb.authStore.model?.id;
      if (userId == null) return;

      final records = await pb.collection('rider_status').getList(
        filter: 'user = "$userId"',
        page: 1, perPage: 1
      );

      final data = {
        'user': userId,
        'is_online': _isOnline,
        'last_active': DateTime.now().toIso8601String(),
      };

      if (records.items.isNotEmpty) {
        await pb.collection('rider_status').update(records.items.first.id, body: data);
      } else {
        await pb.collection('rider_status').create(body: data);
      }
    } catch (e) {
      debugPrint('Rider status broadcast error: $e');
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _riderService.getProfile();
      
      // Also fetch online status from rider_status collection
      final userId = pb.authStore.model?.id;
      if (userId != null) {
        try {
          final statusRecord = await pb.collection('rider_status').getFirstListItem('users = "$userId"');
          if (mounted) {
            setState(() {
              _isOnline = statusRecord.data['is_online'] ?? false;
            });
          }
        } catch (_) {
          // Status record might not exist yet, that's fine
        }
      }

      if (mounted) setState(() { _profile = profile; });
      if (_isOnline) _startLocationUpdates();
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _loadOrders() async {
    if (!_isOnline) return;
    try {
      final orders = await _riderService.getAvailableOrders(page: 1, limit: 20);
      if (mounted) setState(() { _orders = orders; });
    } catch (e) {
      debugPrint('Error loading orders: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _stopLocationUpdates();
    super.dispose();
  }

  Future<void> _toggleOnlineStatus() async {
    if (!_isOnline) {
      final hasLocation = await AppPermissions.requestLocationPermission(context);
      if (!hasLocation) return;
    }

    setState(() => _isLoading = true); // Assuming you add an _isLoading bool for the button

    try {
      if (!_isOnline) {
        await _riderService.goOnline();
        _startLocationUpdates();
        setState(() => _isOnline = true);
        _loadOrders();
      } else {
        await _riderService.goOffline();
        _stopLocationUpdates();
        setState(() {
          _isOnline = false;
          _orders.clear();
        });
      }
      // Broadcast to real-time status collection
      await _broadcastStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    if (mounted) provider.Provider.of<LocationProvider>(context, listen: false).startTracking(distanceFilter: 30);
    final container = riverpod.ProviderScope.containerOf(context, listen: false);

    _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final latLng = LatLng(position.latitude, position.longitude);
        container.read(partnerLocationProvider.notifier).state = latLng;
        await _riderService.updateLocation(position.latitude, position.longitude);
        _loadOrders(); // Auto refresh orders while online
      } catch (e) { debugPrint('Location update error: $e'); }
    });
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
    if (mounted) provider.Provider.of<LocationProvider>(context, listen: false).stopTracking();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(initialCenter: LatLng(-6.7924, 39.2083), initialZoom: 13.0),
            children: [
              TileLayer(
                urlTemplate: MapConfig.tileUrl,
                subdomains: MapConfig.subdomains,
                tileProvider: CancellableNetworkTileProvider(),
              ),
              riverpod.Consumer(builder: (context, ref, _) {
                final riderLocation = ref.watch(partnerLocationProvider);
                if (riderLocation == null) return const SizedBox.shrink();
                return MarkerLayer(markers: [
                  Marker(
                    point: riderLocation, 
                    width: 50, height: 50, 
                    child: MapMarkerService().buildRiderMarker(accentColor: colorScheme.primary)
                  ),
                ]);
              }),
            ],
          ),
          _buildTopBar(colorScheme, textTheme),
          _buildStatusSection(colorScheme, textTheme),
          if (_isOnline && _orders.isNotEmpty) _buildOrdersSheet(colorScheme, textTheme),
        ],
      ),
    );
  }

  Widget _buildTopBar(ColorScheme colorScheme, TextTheme textTheme) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: LiquidGlassContainer(
        borderRadius: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        blur: 10,
        opacity: 0.8,
        child: SizedBox(
          height: 100,
          child: SafeArea(child: Row(children: [
            Image.asset(
              'assets/images/patapoa logo.jpg',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Partner', style: textTheme.labelSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Text(
                  _profile?['name'] ?? _profile?['user']?['name'] ?? 'Loading...', 
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)
                ),
              ],
            ),
            const Spacer(),
            CircleAvatar(radius: 20, backgroundColor: colorScheme.primaryContainer.withOpacity(0.3), child: Icon(Icons.person, color: colorScheme.primary)),
          ])),
        ),
      ),
    );
  }

  Widget _buildStatusSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Positioned(
      bottom: _orders.isNotEmpty ? 320 : 100,
      left: 16, right: 16,
      child: Column(children: [
        LiquidGlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: 20,
          opacity: 0.15,
          blur: 15,
          child: Row(children: [
            Icon(_isOnline ? Icons.sensors : Icons.cloud_off, color: _isOnline ? Colors.green : colorScheme.error),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_isOnline ? 'You\'re online' : 'You are offline', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(_isOnline ? 'Waiting for order requests...' : 'Go online to receive delivery requests', style: textTheme.bodySmall),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 60, child: FilledButton(
          onPressed: _toggleOnlineStatus,
          style: FilledButton.styleFrom(
            backgroundColor: _isOnline ? colorScheme.error : colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(_isOnline ? 'Go Offline' : 'Go Online'),
        )),
      ]),
    );
  }

  Widget _buildOrdersSheet(ColorScheme colorScheme, TextTheme textTheme) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35, minChildSize: 0.2, maxChildSize: 0.9,
      builder: (context, scrollController) => LiquidGlassContainer(
        borderRadius: 32,
        padding: EdgeInsets.zero,
        opacity: 0.9,
        blur: 20,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Available Tasks', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                    child: Text('${_orders.length}', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _orders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final o = _orders[i];
                  return LiquidGlassContainer(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 24,
                    opacity: 0.05,
                    blur: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(o['display_id'] ?? '#${o['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Earn TZS ${o['delivery_fee']}', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.shopping_bag_outlined, size: 14),
                            const SizedBox(width: 4),
                            Text('${(o['order_items'] as List).length} items from ${o['order_items'][0]['product_name']}...'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: () => context.go('/delivery-partner/route-assign', extra: o),
                            child: const Text('View Delivery Details')
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
