import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart' as provider;
import '../../providers/location_provider.dart';
import '../../features/customer/customer_models.dart';
import '../../services/osm_service.dart';
import '../../config/map_config.dart';

class LocationEditScreen extends StatefulWidget {
  const LocationEditScreen({super.key, required this.draft});
  final CustomerOrderDraft draft;

  @override
  State<LocationEditScreen> createState() => _LocationEditScreenState();
}

class _LocationEditScreenState extends State<LocationEditScreen> {
  final OsmService _osmService = OsmService();
  LatLng? _selectedLocation;
  String _address = 'Fetching current position...';
  bool _isLoading = false;
  List<Map<String, dynamic>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final lp = provider.Provider.of<LocationProvider>(context, listen: false);
    if (lp.currentPosition != null) {
      _fetchAddress(lp.currentPosition!);
    }
  }

  Future<void> _fetchAddress(LatLng loc) async {
    setState(() { _selectedLocation = loc; _isLoading = true; _address = 'Updating address...'; _suggestions = []; });
    try {
      final addr = await _osmService.reverseGeocode(loc);
      if (mounted) {
        setState(() {
          _address = addr ?? 'Unknown Location';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _address = 'Unknown Location'; _isLoading = false; });
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.length < 3) return;
    final results = await _osmService.search(query);
    if (mounted) setState(() { _suggestions = results; });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tileUrl = isDarkMode ? MapConfig.cartoDarkUrl : MapConfig.cartoVoyagerUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Location')),
      body: Stack(children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _selectedLocation ?? const LatLng(-6.7924, 39.2083),
            initialZoom: 15.0,
            onTap: (pos, point) => _fetchAddress(point),
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              subdomains: MapConfig.subdomains,
              userAgentPackageName: 'com.patapoa.app',
              tileProvider: CancellableNetworkTileProvider(),
            ),
            if (_selectedLocation != null) MarkerLayer(markers: [
              Marker(point: _selectedLocation!, child: Icon(Icons.location_on, color: colorScheme.primary, size: 40)),
            ]),
          ],
        ),
        _buildSearchAndAddress(colorScheme, textTheme),
      ]),
      bottomNavigationBar: _buildConfirmButton(colorScheme),
    );
  }

  Widget _buildSearchAndAddress(ColorScheme colorScheme, TextTheme textTheme) {
    return Positioned(
      top: 16, left: 16, right: 16,
      child: Column(
        children: [
          _buildSearchBar(colorScheme),
          if (_suggestions.isNotEmpty) _buildSuggestionsList(colorScheme),
          const SizedBox(height: 12),
          _buildAddressCard(colorScheme, textTheme),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Card(
      child: TextField(
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'Search address...',
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(ColorScheme colorScheme) {
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, i) {
          final s = _suggestions[i];
          return ListTile(
            title: Text(s['display_name']),
            onTap: () {
              final loc = LatLng(s['lat'], s['lon']);
              _fetchAddress(loc);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      color: colorScheme.surface.withValues(alpha: 0.9),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        const Icon(Icons.my_location),
        const SizedBox(width: 12),
        Expanded(child: Text(_address, style: textTheme.bodyMedium)),
        if (_isLoading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      ])),
    );
  }

  Widget _buildConfirmButton(ColorScheme colorScheme) {
    return SafeArea(child: Padding(
      padding: const EdgeInsets.all(16),
      child: FilledButton(onPressed: () => context.push('/customer/payment-gateway', extra: widget.draft), child: const Text('Confirm Location')),
    ));
  }
}
