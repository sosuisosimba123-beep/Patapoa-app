import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart' as provider;
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/merchant_service.dart';
import '../../providers/location_provider.dart';
import '../../utils/app_permissions.dart';
import '../../widgets/patapoa_product_image.dart';
import '../../widgets/liquid_glass_container.dart';
import '../../services/map_marker_service.dart';
import '../../config/map_config.dart';
import '../../config/api_config.dart';
import '../../utils/analytics_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _mapController = MapController();
  final ProductService _productService = ProductService();
  final MerchantService _merchantService = MerchantService();
  
  late final AnimationController _pulseController;
  
  List<Product> _products = [];
  List<Map<String, dynamic>> _merchants = [];
  List<PrimaryCategory> _categories = [];
  
  MasterProduct? _heroProduct;
  bool _isLoading = true;
  bool _hasCenteredOnUser = false;
  bool _merchantsNearby = true;

  bool _isSearching = false;
  bool _isSearchLoading = false;
  List<Product> _searchResults = [];
  MasterProduct? _searchHeroProduct;

  int? _selectedPrimaryCategoryId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadInitialData();
    _requestPermissions();
    _scrollController.addListener(_onScroll);

    // Initialize custom markers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MapMarkerService().initialize(context);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final granted = await AppPermissions.requestLocationPermission(context);
    if (granted && mounted) {
      await provider.Provider.of<LocationProvider>(context, listen: false).initialize();
      _loadProducts();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final cats = await _productService.getCategories();
      if (mounted) setState(() => _categories = cats);
      _loadProducts();
    } catch (e) {
      debugPrint('Load Initial Data Error: $e');
    }
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      final locationProvider = provider.Provider.of<LocationProvider>(context, listen: false);
      final pos = locationProvider.currentPosition;

      // 1. Fetch Products
      final response = await _productService.getProducts(
        page: 1,
        limit: 20,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
        primaryCategoryId: _selectedPrimaryCategoryId,
      );

      // 2. Fetch Nearby Merchants for the map
      final merchants = await _merchantService.getNearbyMerchants(
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );

      if (mounted) {
        debugPrint('Explore Screen: Found ${response.products.length} products and ${merchants.length} merchants');
        setState(() {
          _products = response.products;
          _merchants = merchants;
          _heroProduct = response.heroProduct;
          _merchantsNearby = response.merchantsNearby || merchants.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load Products Error: $e');
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more logic...
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() { _isSearching = false; });
      return;
    }
    setState(() { _isSearching = true; _isSearchLoading = true; });
    try {
      final locationProvider = provider.Provider.of<LocationProvider>(context, listen: false);
      final pos = locationProvider.currentPosition;

      final response = await _productService.searchProducts(
        query,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );

      if (mounted) {
        setState(() {
          _searchResults = response.products;
          _searchHeroProduct = response.heroProduct;
          _merchantsNearby = response.merchantsNearby;
          _isSearchLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Search Error: $e');
      if (mounted) setState(() { _isSearchLoading = false; });
    }
  }

  List<Marker> _getUniqueMerchantMarkers(ColorScheme colorScheme) {
    final markers = <Marker>[];

    for (final m in _merchants) {
      if (m['latitude'] == null || m['longitude'] == null) continue;

      final double lat = double.parse(m['latitude'].toString());
      final double lng = double.parse(m['longitude'].toString());

      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 50,
          height: 50,
          alignment: Alignment.topCenter,
          child: MapMarkerService().buildMerchantMarker(
            size: 45,
            onTap: () => _showMerchantStorePreview(m),
          ),
        ),
      );
    }
    return markers;
  }

  void _showMerchantStorePreview(Map<String, dynamic> merchant) {
    AnalyticsService.logStoreSelected(
      storeId: merchant['id']?.toString() ?? 'unknown',
      storeName: merchant['store_name'] ?? 'Local Store',
      city: merchant['city'],
    );
    _mapController.move(
      LatLng(
        double.parse(merchant['latitude'].toString()) - 0.002, 
        double.parse(merchant['longitude'].toString())
      ),
      15.0
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MerchantStorePreviewSheet(merchant: merchant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locationProvider = provider.Provider.of<LocationProvider>(context);
    final userLocation = locationProvider.currentPosition;
    final isInitializing = locationProvider.isLoading;

    // Auto-center map on user location once a position is acquired
    if (userLocation != null && !_hasCenteredOnUser && !isInitializing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasCenteredOnUser) {
          debugPrint('Centering map on user: ${userLocation.latitude}, ${userLocation.longitude}');
          _mapController.move(userLocation, 14.0);
          setState(() => _hasCenteredOnUser = true);
          _loadProducts(); // Reload products for real location
        }
      });
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tileUrl = isDarkMode ? MapConfig.cartoDarkUrl : MapConfig.cartoVoyagerUrl;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Immersive Map Background
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: userLocation ?? const LatLng(-6.7924, 39.2083),
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: tileUrl,
                  subdomains: MapConfig.subdomains,
                  userAgentPackageName: 'com.patapoa.app',
                  tileProvider: CancellableNetworkTileProvider(),
                ),
                if (userLocation != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: userLocation,
                      width: 80, height: 80,
                      child: _UserLocationPulse(
                        color: colorScheme.primary,
                        animation: _pulseController,
                      ),
                    ),
                  ]),
                
                // 1.2 Merchant Markers (Pill Badges)
                MarkerLayer(
                  markers: _getUniqueMerchantMarkers(colorScheme),
                ),
              ],
            ),
          ),

          // 1.3 Liquid Background Blobs removed (Now handled by CustomerShell)

          // 1.5 Recenter Button
          Positioned(
            right: 16,
            top: MediaQuery.paddingOf(context).top + 80,
            child: FloatingActionButton.small(
              heroTag: 'recenter_explore',
              onPressed: () async {
                await locationProvider.refreshPosition();
                if (locationProvider.currentPosition != null) {
                  _mapController.move(locationProvider.currentPosition!, 14.0);
                  _loadProducts(); // Reload products for new location
                }
              },
              backgroundColor: colorScheme.surface,
              child: locationProvider.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.my_location, color: colorScheme.primary),
            ),
          ),

          // 2. Gradient Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.8),
                      colorScheme.surface.withValues(alpha: 0),
                      colorScheme.surface.withValues(alpha: 0.9),
                    ],
                    stops: const [0, 0.2, 1],
                  ),
                ),
              ),
            ),
          ),

          // 3. Search Bar
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 16, right: 16,
            child: _SearchBar(
              controller: _searchController,
              onSubmitted: _performSearch,
            ),
          ),

          // 4. Draggable Bottom Sheet for Products
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.15,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              final currentHero = _isSearching ? _searchHeroProduct : _heroProduct;
              final list = _isSearching ? _searchResults : _products;
              final isLoading = _isSearching ? _isSearchLoading : _isLoading;

              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 12),
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),

                    // Categories Horizontal List
                    if (_categories.isNotEmpty) ...[
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length + 1,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return ChoiceChip(
                                label: const Text('All'),
                                selected: _selectedPrimaryCategoryId == null,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedPrimaryCategoryId = null);
                                    _loadProducts();
                                  }
                                },
                              );
                            }
                            final cat = _categories[index - 1];
                            return ChoiceChip(
                              avatar: cat.imageUrl != null 
                                ? CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: Image.network(
                                      '${ApiConfig.imageBaseUrl}/${cat.imageUrl}',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.category, size: 16),
                                    ),
                                  )
                                : null,
                              label: Text(cat.name),
                              selected: _selectedPrimaryCategoryId == cat.id,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedPrimaryCategoryId = cat.id);
                                  _loadProducts();
                                }
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ALWAYS show the hero/searched product image if available
                    if (currentHero != null) ...[
                      _HeroProductCard(hero: currentHero),
                      const SizedBox(height: 24),
                    ],

                    if (isLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ))
                    else ...[
                       if (list.isNotEmpty || _isSearching)
                        Text(
                          _isSearching ? 'Search Results' : 'Nearby Products',
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 16),

                        if (list.isEmpty)
                          Center(child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                // Show search_off icon ONLY if there's NO hero product either
                                if (currentHero == null) ...[
                                  Icon(
                                    !_merchantsNearby ? Icons.location_off_outlined : Icons.search_off,
                                    size: 48,
                                    color: colorScheme.outline
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Text(
                                  !_merchantsNearby
                                    ? 'Out of Range - Coming Soon!'
                                    : 'No products match your search',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  !_merchantsNearby
                                    ? 'We don\'t operate in your area yet. We\'ve added you to our Moshi waitlist!'
                                    : 'Try a different keyword or check back later',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)
                                ),
                                if (!_merchantsNearby) ...[
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      _performSearch('');
                                    },
                                    child: const Text('View All Areas')
                                  ),
                                ],
                              ],
                            ),
                          ))
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, i) => _ProductTile(
                              product: list[i],
                              onTap: () => context.push('/customer/product', extra: list[i]),
                            ),
                          ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroProductCard extends StatelessWidget {
  final MasterProduct hero;
  const _HeroProductCard({required this.hero});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: PatapoaProductImage(
              imageUrl: hero.primaryImageUrl,
              categorySlug: hero.categorySlug,
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.9),
                  Colors.black.withValues(alpha: 0.2),
                  Colors.transparent
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'DAILY SPECIAL',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hero.name,
                  style: textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -0.5)
                ),
                if (hero.description != null)
                  Text(
                    hero.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;
  const _SearchBar({required this.controller, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LiquidGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      borderRadius: 24,
      opacity: 0.1,
      blur: 15,
      color: Colors.black,
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: 'Search for groceries...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon: Icon(Icons.search, color: colorScheme.primary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () {
              controller.clear();
              onSubmitted('');
            }
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            PatapoaProductImage(
              imageUrl: product.displayImage,
              categorySlug: product.categorySlug,
              width: 85, height: 85,
              borderRadius: BorderRadius.circular(16),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                product.fullDisplayName, 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.storefront, size: 12, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      product.merchant?['store_name'] ?? 'Local Store',
                      maxLines: 1,
                      style: TextStyle(color: colorScheme.secondary, fontSize: 11, fontWeight: FontWeight.w500)
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TZS ${product.price.toStringAsFixed(0)}', 
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 15)
                  ),
                  if (product.distance > 0 || product.isSimulation)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.isSimulation
                            ? 'Instant'
                            : '${product.distance.toStringAsFixed(1)} km',
                        style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                    ),
                ],
              ),
            ])),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: colorScheme.outline),
          ]),
        ),
      ),
    );
  }
}

class _UserLocationPulse extends StatelessWidget {
  final Color color;
  final Animation<double> animation;

  const _UserLocationPulse({required this.color, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Inner Pulsing Ring
            Container(
              width: 40 * animation.value,
              height: 40 * animation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.3 * (1 - animation.value)),
              ),
            ),
            // Outer Pulsing Ring
            Container(
              width: 80 * animation.value,
              height: 80 * animation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15 * (1 - animation.value)),
              ),
            ),
            // Center Core
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MerchantStorePreviewSheet extends StatelessWidget {
  final Map<String, dynamic> merchant;
  const _MerchantStorePreviewSheet({required this.merchant});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSimulation = merchant['store_name']?.toString().contains('Simulation') ?? false;

    return LiquidGlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSimulation ? Icons.biotech : Icons.storefront,
                  color: isSimulation ? Colors.orange : colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant['store_name'] ?? 'Local Store',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${merchant['city'] ?? 'Dar es Salaam'} • ${merchant['distance_km'] != null ? "${double.parse(merchant['distance_km'].toString()).toStringAsFixed(1)} km away" : "Nearby"}',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('STORE RATING', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${merchant['rating'] ?? 4.5}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text('(${merchant['total_orders'] ?? 0} orders)', style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // In a real app we'd navigate to the full store screen
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Shop from this Store'),
            ),
          ),
        ],
      ),
    );
  }
}
