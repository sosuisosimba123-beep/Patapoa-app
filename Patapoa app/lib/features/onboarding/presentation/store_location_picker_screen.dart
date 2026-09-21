import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import '../../../services/osm_service.dart';
import '../../../services/api_service.dart';
import '../../../services/pocketbase_services.dart';
import '../../../providers/location_provider.dart';
import '../../../config/map_config.dart';
import '../../../utils/app_permissions.dart';

class StoreLocationPickerScreen extends StatefulWidget {
  const StoreLocationPickerScreen({super.key});

  @override
  State<StoreLocationPickerScreen> createState() => _StoreLocationPickerScreenState();
}

class _StoreLocationPickerScreenState extends State<StoreLocationPickerScreen> {
  final MapController _mapController = MapController();
  final ApiService _apiService = ApiService();
  final OsmService _osmService = OsmService();
  final _landmarkController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();

  LatLng _selectedLocation = const LatLng(-6.7924, 39.2083); // Dar es Salaam default
  bool _isLoading = false;
  bool _hasInitialized = false;
  String _detectedAddress = 'Locating...';

  @override
  void initState() {
    super.initState();
    _cityController.text = 'Dar es Salaam'; // Default
    // Auto-detect location on entry
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  Future<void> _initLocation() async {
    final hasPermission = await AppPermissions.requestLocationPermission(context);
    if (hasPermission) {
      await _locateMe();
    }
  }

  Future<void> _detectAddress(LatLng pos) async {
    final details = await _osmService.reverseGeocodeDetails(pos);
    if (details != null && mounted) {
      setState(() {
        _detectedAddress = details['freeformAddress'] ?? 'Unknown Area';
        if (details['municipality'] != null) {
          _cityController.text = details['municipality'];
        }
        if (details['countrySecondarySubdivision'] != null) {
           _districtController.text = details['countrySecondarySubdivision'];
        }
      });
    }
  }

  Future<void> _locateMe() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.refreshPosition();
    
    if (locationProvider.currentPosition != null && mounted) {
      setState(() {
        _selectedLocation = locationProvider.currentPosition!;
        _hasInitialized = true;
      });
      _mapController.move(_selectedLocation, 16.0);
      _detectAddress(_selectedLocation);
    } else if (locationProvider.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(locationProvider.error!)),
        );
      }
    }
  }

  Future<void> _saveLocation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you currently standing inside your store?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('LAT: ${_selectedLocation.latitude.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('LON: ${_selectedLocation.longitude.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              _locateMe();
            },
            child: const Text('CANCEL / RE-DETECT'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YES, SAVE LOCATION'),
          ),
        ],
      ),
    );

    setState(() => _isLoading = true);
    try {
      // 1. Save to PocketBase (merchant_profiles)
      final merchantService = MerchantService();
      await merchantService.updateStoreLocation({
        'latitude': _selectedLocation.latitude,
        'longitude': _selectedLocation.longitude,
        'city': _cityController.text,
        'address': _detectedAddress,
      });

      // 2. Update status in merchant_activity
      try {
        final userId = pb.authStore.model?.id;
        if (userId != null) {
          final records = await pb.collection('merchant_activity').getList(
            filter: 'users = "$userId"',
            page: 1, perPage: 1
          );

          final data = {
            'users': userId,
            'is_accepting_orders': true,
            'last_seen': DateTime.now().toIso8601String(),
          };

          if (records.items.isNotEmpty) {
            await pb.collection('merchant_activity').update(records.items.first.id, body: data);
          } else {
            await pb.collection('merchant_activity').create(body: data);
          }
        }
      } catch (e) {
        debugPrint('PocketBase location activity sync warning: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store location saved successfully!')),
        );
        context.go('/merchant/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLocationNotice(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Set Location While At Store',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ensure you are standing inside your physical shop right now. Delivery riders navigate directly to these exact coordinates to pick up orders.',
            style: textTheme.bodySmall?.copyWith(color: Colors.amber.shade900),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _locateMe,
              icon: const Icon(Icons.my_location, size: 16),
              label: const Text('RE-DETECT GPS'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber.shade900,
                side: BorderSide(color: Colors.amber.shade900),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locationProvider = context.watch<LocationProvider>();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tileUrl = isDarkMode ? MapConfig.cartoDarkUrl : MapConfig.cartoVoyagerUrl;

    // Reactive Auto-center: If provider resolves a true location while we are on this screen, move the map.
    if (locationProvider.currentPosition != null && !_hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasInitialized) {
          setState(() {
            _selectedLocation = locationProvider.currentPosition!;
            _hasInitialized = true;
          });
          _mapController.move(_selectedLocation, 15.0);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Store Location'),
        actions: [
          if (locationProvider.isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ))
        ],
      ),
      body: Column(
        children: [
          _buildLocationNotice(colorScheme, textTheme),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 15.0,
                    onPositionChanged: (position, hasGesture) {
                      if (position.center != null) {
                        setState(() {
                          _selectedLocation = position.center!;
                        });
                      }
                    },
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        _detectAddress(_selectedLocation);
                      }
                    }
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: tileUrl,
                      subdomains: MapConfig.subdomains,
                      userAgentPackageName: 'com.patapoa.app',
                      tileProvider: CancellableNetworkTileProvider(),
                    ),
                    // Visual Pin that stays at the selected location
                    MarkerLayer(markers: [
                      Marker(
                        point: _selectedLocation,
                        width: 50, height: 50,
                        alignment: Alignment.topCenter,
                        child: const Icon(Icons.location_on, size: 48, color: Colors.red),
                      ),
                    ]),
                    // User's current physical location (Blue dot)
                    if (locationProvider.currentPosition != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: locationProvider.currentPosition!,
                          width: 20, height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 12, height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
                  ],
                ),
                // Coordinates Overlay
                Positioned(
                  top: 20,
                  left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        _detectedAddress,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                // GPS Recenter Button
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    heroTag: 'recenter_onboarding',
                    onPressed: _locateMe,
                    backgroundColor: colorScheme.surface,
                    child: Icon(Icons.my_location, color: colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Location Details', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City / Region',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _districtController,
                        decoration: const InputDecoration(
                          labelText: 'District',
                          prefixIcon: Icon(Icons.map_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Coordinates', style: textTheme.labelSmall),
                            Text(
                              '${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                              style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _landmarkController,
                  decoration: const InputDecoration(
                    labelText: 'Nearby Landmark (Optional)',
                    hintText: 'e.g. Next to Total Station, Moshi Market',
                    prefixIcon: Icon(Icons.business_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _saveLocation,
                    child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirm Store Location'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
