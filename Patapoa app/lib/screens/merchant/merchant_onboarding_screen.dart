import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import '../../services/merchant_service.dart';
import '../../services/map_marker_service.dart';
import '../../providers/location_provider.dart';
import '../../config/map_config.dart';

class MerchantOnboardingScreen extends StatefulWidget {
  const MerchantOnboardingScreen({super.key});

  @override
  State<MerchantOnboardingScreen> createState() => _MerchantOnboardingScreenState();
}

class _MerchantOnboardingScreenState extends State<MerchantOnboardingScreen> {
  final MapController _mapController = MapController();
  final _formKey = GlobalKey<FormState>();

  final _shopNameController = TextEditingController();
  
  LatLng _selectedLocation = const LatLng(-6.7924, 39.2083); // Dar es Salaam default
  bool _isLoading = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Precache marker for consistent rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MapMarkerService().initialize(context);
    });
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    super.dispose();
  }

  Future<void> _locateMe() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.refreshPosition();
    
    if (locationProvider.currentPosition != null) {
      setState(() {
        _selectedLocation = locationProvider.currentPosition!;
      });
      _mapController.move(_selectedLocation, 16.0);
    }
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

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

    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    try {
      final merchantService = MerchantService();
      await merchantService.updateStoreLocation({
        'store_name': _shopNameController.text,
        'latitude': _selectedLocation.latitude,
        'longitude': _selectedLocation.longitude,
      });

      if (mounted) {
        context.go('/merchant/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLocationNotice(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
        title: const Text('Store Setup'),
        automaticallyImplyLeading: true,
        leading: IconButton(onPressed: () => context.go('/merchant/home'), icon: const Icon(Icons.arrow_back)),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLocation,
                      initialZoom: 15.0,
                      // Logic: Restricted to current location. 
                      // User cannot manually drag to set coordinates.
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.drag & ~InteractiveFlag.flingAnimation,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: tileUrl,
                        subdomains: MapConfig.subdomains,
                        userAgentPackageName: 'com.patapoa.app',
                        tileProvider: CancellableNetworkTileProvider(),
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation,
                            width: 50, height: 50,
                            child: MapMarkerService().buildMerchantMarker(size: 45),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      heroTag: 'onboarding_locate',
                      onPressed: _locateMe,
                      backgroundColor: colorScheme.surface,
                      child: locationProvider.isLoading 
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : Icon(Icons.my_location, color: colorScheme.primary),
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
                  Text('Store Details', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _shopNameController,
                    decoration: const InputDecoration(labelText: 'Shop Name', border: OutlineInputBorder()),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _completeSetup,
                      child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirm Store Location'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLocationNotice(colorScheme, textTheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
