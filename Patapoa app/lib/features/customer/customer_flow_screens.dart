import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:patapoa/features/customer/customer_models.dart';
import 'package:patapoa/services/product_service.dart';
import 'package:patapoa/services/order_service.dart';
import 'package:patapoa/models/product.dart';
import 'package:patapoa/models/order.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:patapoa/utils/app_permissions.dart';
import 'package:patapoa/services/address_service.dart';
import 'package:patapoa/services/payment_service.dart';
import 'package:patapoa/providers/cart_provider.dart';
import 'package:patapoa/providers/auth_provider.dart';
import 'package:patapoa/providers/location_provider.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.child});

  final Widget child;

  static const _tabs = <_ShellTab>[
    _ShellTab(
      label: 'Explore',
      icon: Icons.explore_outlined,
      route: '/customer/explore',
    ),
    _ShellTab(
      label: 'Orders',
      icon: Icons.local_shipping_outlined,
      route: '/customer/orders',
    ),
    _ShellTab(
      label: 'Profile',
      icon: Icons.person_outline,
      route: '/customer/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = _tabs.indexWhere((t) => path.startsWith(t.route));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: BottomNavigationBar(
            currentIndex: max(0, selectedIndex),
            onTap: (index) {
              final tab = _tabs[index];
              context.go(tab.route);
            },
            items: _tabs
                .map(
                  (t) => BottomNavigationBarItem(
                    icon: Icon(t.icon),
                    label: t.label,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
      floatingActionButton: path.startsWith('/customer/explore')
          ? Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                return FloatingActionButton(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  onPressed: () => context.go('/customer/cart'),
                  child: Stack(
                    children: [
                      const Icon(Icons.shopping_cart_outlined),
                      if (cartProvider.itemCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${cartProvider.itemCount}',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onError,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            )
          : null,
    );
  }
}

class CustomerExploreScreen extends StatefulWidget {
  const CustomerExploreScreen({super.key});

  @override
  State<CustomerExploreScreen> createState() => _CustomerExploreScreenState();
}

class _CustomerExploreScreenState extends State<CustomerExploreScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedCategory = 'All Items';
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Pagination state
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Search mode state
  bool _isSearching = false;
  bool _isSearchLoading = false;
  String _searchQuery = '';
  String _searchFilter = 'Lowest Price';
  List<Product> _searchResults = [];

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchQuery = query.trim();
      _searchFilter = 'Lowest Price';
      _isSearchLoading = true;
    });

    try {
      final results = await _productService.searchProducts(_searchQuery);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearchLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSearchLoading = false;
        });
      }
    }
  }

  void _clearSearch() {
    setState(() {
      _isSearching = false;
      _isSearchLoading = false;
      _searchQuery = '';
      _searchController.clear();
      _searchResults.clear();
    });
  }

  List<Product> _sortedSearchOffers() {
    final sorted = [..._searchResults];
    if (_searchFilter == 'Lowest Price') {
      sorted.sort((a, b) => a.price.compareTo(b.price));
    }
    // 'Nearest' and 'Fastest Delivery' sorting can be added here
    // once geolocation fields are available on the Product model.
    return sorted;
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _requestPermissions();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _requestPermissions() async {
    // Request location for nearby shop search
    final locationGranted = await AppPermissions.requestLocationPermission(
      context,
    );
    if (locationGranted && mounted) {
      // Initialize location provider after permission is granted
      await context.read<LocationProvider>().initialize();
    }
    // Request notifications for order updates
    await AppPermissions.requestNotificationPermission(context);
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final products = await _productService.getProducts(page: 1, limit: 20);
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
          _hasMore = products.length >= 20;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final products = await _productService.getProducts(page: _currentPage + 1, limit: 20);
      if (mounted) {
        setState(() {
          _products.addAll(products);
          _currentPage++;
          _hasMore = products.length >= 20;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = const [
      _CategoryChipData(label: 'All Items', icon: Icons.all_inclusive),
      _CategoryChipData(label: 'Hardware', icon: Icons.foundation_outlined),
      _CategoryChipData(label: 'Electronics', icon: Icons.devices_outlined),
      _CategoryChipData(
        label: 'Groceries',
        icon: Icons.shopping_basket_outlined,
      ),
    ];

    final colorScheme = Theme.of(context).colorScheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final locationProvider = context.watch<LocationProvider>();
    final userLocation = locationProvider.currentPosition;
    final searchFilters = const [
      'Lowest Price',
      'Nearest',
      'Fastest Delivery',
      'Verified Only',
    ];
    final searchOffers = _isSearching
        ? _sortedSearchOffers()
        : <Product>[];

    return Stack(
      children: [
        Positioned.fill(
          child: _FlutterMapWidget(
            overlayOpacityTop: 0.86,
            overlayOpacityBottom: 0.92,
            center: userLocation,
            userPosition: userLocation,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: [
                if (userLocation == null)
                  Align(
                    alignment: Alignment.center,
                    child: _UserLocationDot(color: colorScheme.primary),
                  ),
                Positioned(
                  top: 140,
                  left: 64,
                  child: _DecorPin(
                    icon: Icons.storefront_outlined,
                    color: colorScheme.primaryContainer,
                  ),
                ),
                Positioned(
                  top: 210,
                  right: 68,
                  child: _DecorPin(
                    icon: Icons.construction_outlined,
                    color: colorScheme.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: max(12, topInset + 10),
          left: 12,
          right: 12,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: _FrostedCard(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Menu coming soon')),
                        );
                      },
                      icon: Icon(Icons.menu, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) {
                          final query = value.trim();
                          if (query.isEmpty) return;
                          _performSearch(query);
                          FocusScope.of(context).unfocus();
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search for any product...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_isSearching)
                      IconButton(
                        tooltip: 'Clear search',
                        onPressed: _clearSearch,
                        icon: Icon(Icons.close, color: colorScheme.onSurface),
                      )
                    else
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.primaryContainer
                            .withOpacity(0.25),
                        child: Icon(Icons.person, color: colorScheme.primary),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: max(84, topInset + 82),
          left: 0,
          right: 0,
          child: SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                if (_isSearching) {
                  final label = searchFilters[index];
                  final selected = label == _searchFilter;
                  final icon = switch (label) {
                    'Lowest Price' => Icons.sort,
                    'Nearest' => Icons.location_on_outlined,
                    'Fastest Delivery' => Icons.speed,
                    _ => Icons.verified_outlined,
                  };
                  return ChoiceChip(
                    selected: selected,
                    label: Text(label),
                    avatar: Icon(icon, size: 18),
                    onSelected: (_) => setState(() => _searchFilter = label),
                  );
                }

                final c = categories[index];
                final selected = c.label == _selectedCategory;
                return ChoiceChip(
                  selected: selected,
                  label: Text(c.label),
                  avatar: Icon(c.icon, size: 18),
                  onSelected: (_) =>
                      setState(() => _selectedCategory = c.label),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _isSearching
                  ? searchFilters.length
                  : categories.length,
            ),
          ),
        ),
        DraggableScrollableSheet(
          minChildSize: _isSearching ? 0.42 : 0.18,
          initialChildSize: _isSearching ? 0.62 : 0.38,
          maxChildSize: 0.84,
          builder: (context, scrollController) {
            return _BottomSheetContainer(
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _isSearching
                                  ? '${searchOffers.length} Shops found'
                                  : 'Nearby Products',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (_isSearching)
                            Text(
                              'NEAR DAR ES SALAAM',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                            )
                          else if (_isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              Icons.keyboard_arrow_up,
                              color: colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_isSearching && _isSearchLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_isSearching && searchOffers.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                        child: Center(
                          child: Text(
                            'No results found for "$_searchQuery"',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                    )
                  else if (_isSearching)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverList.separated(
                        itemBuilder: (context, index) {
                          final product = searchOffers[index];
                          return _ProductCard(
                            product: product,
                            onTap: () => context.push(
                              '/customer/product',
                              extra: product,
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: searchOffers.length,
                      ),
                    )
                  else if (_isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_errorMessage != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                'Error loading products',
                                style: TextStyle(color: colorScheme.error),
                              ),
                              const SizedBox(height: 8),
                              Text(_errorMessage!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadProducts,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (_products.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No products available',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.crossAxisExtent >= 620;
                          final grid = SliverGrid(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              if (index < _products.length) {
                                final product = _products[index];
                                return _ProductCard(
                                  product: product,
                                  onTap: () => context.push(
                                    '/customer/product',
                                    extra: product,
                                  ),
                                );
                              }
                              return _isLoadingMore
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }, childCount: _products.length + (_isLoadingMore ? 1 : 0)),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isWide ? 2 : 1,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: isWide ? 2.5 : 2.9,
                                ),
                          );
                          return grid;
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class CustomerProductDetailsScreen extends StatefulWidget {
  const CustomerProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  State<CustomerProductDetailsScreen> createState() =>
      _CustomerProductDetailsScreenState();
}

class _CustomerProductDetailsScreenState
    extends State<CustomerProductDetailsScreen> {
  int _quantity = 1;

  void _addToCart() {
    final cartProvider = context.read<CartProvider>();
    cartProvider.addItem(widget.product, quantity: _quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${widget.product.name} to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => context.go('/customer/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      'Product Details',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite_border),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: product.image != null
                                    ? Image.network(
                                        product.image!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => ColoredBox(
                                          color:
                                              colorScheme.surfaceContainerHigh,
                                          child: const Center(
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ColoredBox(
                                        color: colorScheme.surfaceContainerHigh,
                                        child: const Center(
                                          child: Icon(
                                            Icons.shopping_bag_outlined,
                                          ),
                                        ),
                                      ),
                              ),
                              if (!product.isAvailable)
                                Positioned(
                                  top: 14,
                                  right: 14,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'OUT OF STOCK',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (product.description != null)
                                    Text(
                                      product.description!,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'TZS ${product.price.toStringAsFixed(0)}',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Incl. VAT',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 520;
                            return GridView.count(
                              crossAxisCount: isWide ? 2 : 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: isWide ? 2.9 : 2.6,
                              children: [
                                _InfoCard(
                                  title: 'Stock',
                                  icon: Icons.inventory_2_outlined,
                                  content: product.stockQuantity != null
                                      ? '${product.stockQuantity} available'
                                      : 'In stock',
                                  accent: product.isAvailable
                                      ? colorScheme.primary
                                      : colorScheme.error,
                                ),
                                _InfoCardWide(
                                  title: 'Logistics',
                                  icon: Icons.local_shipping_outlined,
                                  leading: 'Delivery Estimate',
                                  trailing: 'LIVE TRACKING',
                                  content: 'Arriving in 15-30 mins',
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withOpacity(
                                0.4,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Select Quantity',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                                icon: const Icon(Icons.remove),
                              ),
                              SizedBox(
                                width: 34,
                                child: Text(
                                  '$_quantity',
                                  textAlign: TextAlign.center,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _quantity++),
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (product.description != null) ...[
                          Text(
                            'Product Description',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            product.description!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: product.isAvailable ? _addToCart : null,
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: Text(
                      product.isAvailable ? 'Add to Cart' : 'Out of Stock',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.undo),
                    label: const Text('Back to Results'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomerCartScreen extends StatefulWidget {
  const CustomerCartScreen({super.key});

  @override
  State<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends State<CustomerCartScreen> {
  final OrderService _orderService = OrderService();
  final AddressService _addressService = AddressService();
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;
  bool _isLoadingAddresses = false;
  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _selectedAddress;
  String _paymentMethod = 'mpesa';

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoadingAddresses = true);
    try {
      final addresses = await _addressService.getAddresses();
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _selectedAddress = addresses.isNotEmpty ? addresses.first : null;
          _isLoadingAddresses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAddresses = false);
    }
  }

  Future<void> _placeOrder() async {
    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to place an order')),
      );
      context.go('/login');
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a delivery address first')),
      );
      return;
    }

    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
      return;
    }

    // Show payment + address confirmation dialog
    final confirmed = await _showOrderConfirmationDialog();
    if (!confirmed || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final orderRequest = {
        'address_id': _selectedAddress!['id'],
        'items': cartProvider.items
            .map(
              (item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
              },
            )
            .toList(),
        'payment_method': _paymentMethod,
        'customer_notes': 'Order placed via mobile app',
      };

      final order = await _orderService.createOrder(orderRequest);

      // If M-Pesa, initiate payment
      if (_paymentMethod == 'mpesa' || _paymentMethod == 'tigo_pesa') {
        try {
          final paymentResult = await _paymentService.initiatePayment(
            orderId: order.id,
            paymentMethod: _paymentMethod,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Payment initiated: ${paymentResult['message'] ?? 'Please check your phone'}',
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Payment initiation failed: $e. Order was placed.',
                ),
              ),
            );
          }
        }
      }

      cartProvider.clear();

      if (mounted) {
        context.push('/customer/tracking', extra: order);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool> _showOrderConfirmationDialog() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.paddingOf(context).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Confirm Order',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Delivery Address',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingAddresses)
                    const Center(child: CircularProgressIndicator())
                  else if (_addresses.isEmpty)
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.pop(context, false);
                        context.go('/customer/profile');
                      },
                      child: const Text('Add Address'),
                    )
                  else
                    Column(
                      children: _addresses.map((addr) {
                        final selected = _selectedAddress?['id'] == addr['id'];
                        return RadioListTile<int>(
                          value: addr['id'],
                          groupValue: _selectedAddress?['id'],
                          onChanged: (val) {
                            setSheetState(() => _selectedAddress = addr);
                          },
                          title: Text(
                            addr['label'] ?? 'Address',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${addr['address_line_1']}, ${addr['city']}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          activeColor: colorScheme.primary,
                          selected: selected,
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Payment Method',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      _PaymentChip(
                        label: 'M-Pesa',
                        icon: Icons.account_balance_wallet_outlined,
                        selected: _paymentMethod == 'mpesa',
                        onTap: () =>
                            setSheetState(() => _paymentMethod = 'mpesa'),
                      ),
                      _PaymentChip(
                        label: 'Tigo Pesa',
                        icon: Icons.account_balance_wallet_outlined,
                        selected: _paymentMethod == 'tigo_pesa',
                        onTap: () =>
                            setSheetState(() => _paymentMethod = 'tigo_pesa'),
                      ),
                      _PaymentChip(
                        label: 'Cash',
                        icon: Icons.payments_outlined,
                        selected: _paymentMethod == 'cash',
                        onTap: () =>
                            setSheetState(() => _paymentMethod = 'cash'),
                      ),
                      _PaymentChip(
                        label: 'Wallet',
                        icon: Icons.wallet_outlined,
                        selected: _paymentMethod == 'wallet',
                        onTap: () =>
                            setSheetState(() => _paymentMethod = 'wallet'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm & Place Order'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add products to get started',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/customer/explore'),
                    child: const Text('Browse Products'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartProvider.items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: cartItem.product.image != null
                                    ? Image.network(
                                        cartItem.product.image!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => ColoredBox(
                                          color:
                                              colorScheme.surfaceContainerHigh,
                                          child: const Center(
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ColoredBox(
                                        color: colorScheme.surfaceContainerHigh,
                                        child: const Center(
                                          child: Icon(
                                            Icons.shopping_bag_outlined,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartItem.product.name,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'TZS ${cartItem.product.price.toStringAsFixed(0)}',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        cartProvider.updateQuantity(
                                          cartItem.product.id,
                                          cartItem.quantity - 1,
                                        );
                                      },
                                      icon: const Icon(Icons.remove, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    SizedBox(
                                      width: 30,
                                      child: Text(
                                        '${cartItem.quantity}',
                                        textAlign: TextAlign.center,
                                        style: textTheme.titleMedium,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        cartProvider.updateQuantity(
                                          cartItem.product.id,
                                          cartItem.quantity + 1,
                                        );
                                      },
                                      icon: const Icon(Icons.add, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () {
                                    cartProvider.removeItem(
                                      cartItem.product.id,
                                    );
                                  },
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: colorScheme.error,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total (${cartProvider.itemCount} items)',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'TZS ${cartProvider.totalAmount.toStringAsFixed(0)}',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isProcessing ? null : _placeOrder,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Place Order'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CustomerOrderSummaryScreen extends StatefulWidget {
  const CustomerOrderSummaryScreen({super.key, required this.draft});

  final CustomerOrderDraft draft;

  @override
  State<CustomerOrderSummaryScreen> createState() =>
      _CustomerOrderSummaryScreenState();
}

class _CustomerOrderSummaryScreenState
    extends State<CustomerOrderSummaryScreen> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final offer = draft.offer;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locationProvider = context.watch<LocationProvider>();
    final userLocation = locationProvider.currentPosition;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _FlutterMapWidget(
              overlayOpacityTop: 0.55,
              overlayOpacityBottom: 0.92,
              center: userLocation,
              userPosition: userLocation,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.menu),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Patapoa',
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.surfaceContainerHigh,
                        child: const Icon(Icons.person, size: 18),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          children: [
                            _Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'ESTIMATED ARRIVAL',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${offer.etaMinutes + 10} mins',
                                    style: textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Fast delivery from ${offer.shopName}',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Divider(
                                    color: colorScheme.outlineVariant
                                        .withOpacity(0.35),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'DELIVERY ADDRESS',
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                    color:
                                                        colorScheme.secondary,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 1,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Morogoro Road, Block G, DSM',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _Card(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 76,
                                      height: 76,
                                      child: Image.network(
                                        offer.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => ColoredBox(
                                          color:
                                              colorScheme.surfaceContainerHigh,
                                          child: const Center(
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SHOP: ${offer.shopName.toUpperCase()}',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.7,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          offer.productName,
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Qty: ${draft.quantity}',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceContainer,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.payments,
                                                color: colorScheme.secondary,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'M-Pesa Pay: 07XX XXX XXX',
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ORDER SUMMARY',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.secondary,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _PriceRow(
                                    label: 'Product Subtotal',
                                    value: formatTzs(draft.subtotalTzs),
                                  ),
                                  const SizedBox(height: 8),
                                  _PriceRow(
                                    label: 'Delivery Fee',
                                    value: formatTzs(draft.deliveryFeeTzs),
                                  ),
                                  const SizedBox(height: 8),
                                  _PriceRow(
                                    label: 'Platform Fee',
                                    value: formatTzs(draft.platformFeeTzs),
                                  ),
                                  const SizedBox(height: 12),
                                  Divider(
                                    color: colorScheme.outlineVariant
                                        .withOpacity(0.6),
                                    thickness: 1,
                                  ),
                                  const SizedBox(height: 12),
                                  _PriceRow(
                                    label: 'Total Amount',
                                    value: formatTzs(draft.totalTzs),
                                    bold: true,
                                    valueColor: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _processing
                    ? null
                    : () async {
                        setState(() => _processing = true);
                        await Future<void>.delayed(
                          const Duration(milliseconds: 900),
                        );
                        if (!mounted) return;
                        setState(() => _processing = false);
                        context.push(
                          '/customer/delivery-location',
                          extra: draft,
                        );
                      },
                icon: _processing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(_processing ? 'Processing...' : 'Confirm Order'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomerDeliveryLocationScreen extends StatefulWidget {
  const CustomerDeliveryLocationScreen({super.key, required this.draft});

  final CustomerOrderDraft draft;

  @override
  State<CustomerDeliveryLocationScreen> createState() =>
      _CustomerDeliveryLocationScreenState();
}

class _CustomerDeliveryLocationScreenState
    extends State<CustomerDeliveryLocationScreen> {
  bool _showConfirmed = false;
  LatLng? _selectedLocation;
  String _address = 'Current Location';
  bool _isLoadingAddress = false;

  Future<void> _fetchAddress(LatLng loc) async {
    setState(() {
      _selectedLocation = loc;
      _isLoadingAddress = true;
      _address = 'Fetching address...';
    });
    try {
      final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _address = [place.street, place.subLocality, place.locality].where((e) => e != null && e.isNotEmpty).join(', ');
          if (_address.isEmpty) _address = 'Selected Location';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Unknown Location';
        _isLoadingAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final offer = draft.offer;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final locationProvider = context.watch<LocationProvider>();
    final userLocation = locationProvider.currentPosition;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _FlutterMapWidget(
              overlayOpacityTop: 0.35,
              overlayOpacityBottom: 0.78,
              center: _selectedLocation ?? userLocation,
              userPosition: _selectedLocation ?? userLocation,
              onTap: (tapPosition, point) => _fetchAddress(point),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    top: 170,
                    left: MediaQuery.sizeOf(context).width * 0.52 - 10,
                    child: _LabelPin(
                      label: offer.shopName,
                      icon: Icons.storefront_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                  Positioned(
                    top: 380,
                    left: MediaQuery.sizeOf(context).width * 0.48 - 10,
                    child: _PulsingLocationPin(color: colorScheme.tertiary),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: max(12, topInset + 10),
            left: 12,
            right: 12,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _FrostedCard(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Text(
                          'Set Delivery Point',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.surfaceContainerHigh,
                        child: const Icon(Icons.person, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: max(92, topInset + 90),
            left: 12,
            right: 12,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _Card(
                  child: Column(
                    children: [
                      _RouteField(
                        title: 'PICKUP FROM',
                        titleColor: colorScheme.onSurfaceVariant,
                        bullet: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        value: offer.shopName,
                        trailing: const Icon(Icons.edit, size: 18),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DELIVER TO',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.tertiary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Autocomplete<Map<String, dynamic>>(
                            initialValue: TextEditingValue(text: _address),
                            displayStringForOption: (option) => option['display_name'] as String,
                            optionsBuilder: (TextEditingValue textEditingValue) async {
                              if (textEditingValue.text.isEmpty || textEditingValue.text.length < 3) {
                                return const Iterable<Map<String, dynamic>>.empty();
                              }
                              try {
                                final response = await http.get(
                                  Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(textEditingValue.text)}&format=json&limit=5'),
                                  headers: {'User-Agent': 'Patapoa Delivery App'},
                                );
                                if (response.statusCode == 200) {
                                  final List<dynamic> data = json.decode(response.body);
                                  return data.map((e) => e as Map<String, dynamic>).toList();
                                }
                              } catch (e) {
                                // Ignore
                              }
                              return const Iterable<Map<String, dynamic>>.empty();
                            },
                            onSelected: (Map<String, dynamic> selection) {
                              setState(() {
                                _address = selection['display_name'] as String;
                                final lat = double.tryParse(selection['lat'].toString());
                                final lon = double.tryParse(selection['lon'].toString());
                                if (lat != null && lon != null) {
                                  _selectedLocation = LatLng(lat, lon);
                                }
                              });
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              // We update the controller if the user tapped the map
                              if (!_isLoadingAddress && _address != 'Current Location' && controller.text != _address && !focusNode.hasFocus) {
                                controller.text = _address;
                              }
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Search delivery address...',
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(Icons.search, color: colorScheme.tertiary),
                                  suffixIcon: _isLoadingAddress 
                                    ? Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Icon(Icons.gps_fixed, color: colorScheme.primary),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: _BottomFixedSheet(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ESTIMATED ARRIVAL',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '24 - 32 mins',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'TRANSPORT FEE',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatTzs(draft.deliveryFeeTzs),
                                    style: textTheme.titleLarge?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 44,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _PaymentChip(
                                  label: 'M-PESA',
                                  icon: Icons.account_balance_wallet_outlined,
                                  selected: true,
                                ),
                                const SizedBox(width: 10),
                                _PaymentChip(
                                  label: 'ADD PAYMENT',
                                  icon: Icons.add_circle_outline,
                                  selected: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: () async {
                              final hasLocation =
                                  await AppPermissions.requestLocationPermission(
                                    context,
                                  );
                              if (!hasLocation) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Location permission is required to set delivery point.',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }
                              setState(() => _showConfirmed = true);
                              await Future<void>.delayed(
                                const Duration(milliseconds: 550),
                              );
                              if (!mounted) return;
                              final placed = CustomerPlacedOrder(
                                id: 'PT-${DateTime.now().millisecondsSinceEpoch % 100000}',
                                draft: draft,
                                pickupLabel: offer.shopName,
                                dropoffLabel: 'Kijitonyama',
                                riderName: 'Juma Hamisi',
                                riderRating: 4.9,
                                status: 'in_transit',
                                orderDate: DateTime.now(),
                              );
                              if (!mounted) return;
                              context.push(
                                '/customer/payment-gateway',
                                extra: placed,
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Confirm Location'),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_showConfirmed)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: colorScheme.primaryContainer,
                            size: 46,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Location Confirmed',
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CustomerTrackingScreen extends StatefulWidget {
  const CustomerTrackingScreen({super.key, required this.order});

  final Order order;

  @override
  State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  int _eta = 12;
  Timer? _timer;
  final OrderService _orderService = OrderService();
  LatLng? _riderLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _riderLocation = const LatLng(-6.7900, 39.2100);
    // Fetch immediately on open, then start 5-second polling
    _fetchLiveLocation();
    _startTrackingTimer();
  }

  // Pause polling when app goes to background (saves battery)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTrackingTimer();
    } else if (state == AppLifecycleState.paused) {
      _stopTrackingTimer();
    }
  }

  void _startTrackingTimer() {
    // Cancel any existing timer first to prevent duplicate ticks
    _stopTrackingTimer();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _fetchLiveLocation();
    });
  }

  void _stopTrackingTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetchLiveLocation() async {
    try {
      // Uses the existing OrderService.getOrderTracking() → GET /orders/{id}/tracking
      final data = await _orderService.getOrderTracking(widget.order.id);

      if (!mounted) return;

      final double? lat = (data['latitude'] as num?)?.toDouble();
      final double? lng = (data['longitude'] as num?)?.toDouble();
      final String? status = data['status'] as String?;
      final int? eta = (data['eta_minutes'] as num?)?.toInt();

      if (lat != null && lng != null) {
        setState(() {
          _riderLocation = LatLng(lat, lng);
          if (eta != null) _eta = eta;
        });
      }

      // Auto-stop polling once the order is delivered
      if (status == 'DELIVERED' || status == 'delivered') {
        _stopTrackingTimer();
      }
    } catch (e) {
      // Network errors are skipped silently; next tick will retry
      debugPrint('[TrackingScreen] Location fetch failed: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTrackingTimer();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final locationProvider = context.watch<LocationProvider>();
    final userLocation = locationProvider.currentPosition;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _FlutterMapWidget(
              overlayOpacityTop: 0.85,
              overlayOpacityBottom: 0.9,
              center: userLocation,
              userPosition: userLocation,
              polylines: [
                if (userLocation != null && _riderLocation != null)
                  Polyline(
                    points: [_riderLocation!, userLocation],
                    color: colorScheme.primaryContainer,
                    strokeWidth: 5,
                    isDotted: true,
                  ),
              ],
              markers: [
                if (_riderLocation != null)
                  Marker(
                    point: _riderLocation!,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          border: Border.all(color: Colors.white, width: 2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: max(12, topInset + 10),
            left: 12,
            right: 12,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _FrostedCard(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.arrow_back,
                          color: colorScheme.primary,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${order.id}',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Arriving in $_eta mins',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.surfaceContainerHigh,
                        child: const Icon(Icons.person, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: max(84, topInset + 82),
            left: 12,
            right: 12,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _FrostedCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Rider On The Way',
                                style: textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Text(
                              '75% Complete',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: SizedBox(
                            height: 6,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ColoredBox(color: colorScheme.primary),
                                ),
                                Expanded(
                                  child: ColoredBox(color: colorScheme.primary),
                                ),
                                Expanded(
                                  child: AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, _) {
                                      final alpha =
                                          0.25 +
                                          sin(
                                                _controller.value * pi * 2,
                                              ).abs() *
                                              0.55;
                                      return ColoredBox(
                                        color: colorScheme.primaryContainer
                                            .withOpacity(alpha),
                                      );
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: ColoredBox(
                                    color: colorScheme.surfaceContainerHighest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Preparing',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Picked Up',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Delivering',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withOpacity(
                                  0.55,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: _Card(
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 5,
                            decoration: BoxDecoration(
                              color: colorScheme.outlineVariant.withOpacity(
                                0.6,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: colorScheme.primaryContainer
                                    .withOpacity(0.22),
                                child: Icon(
                                  Icons.pedal_bike,
                                  color: colorScheme.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.riderName ?? 'Rider',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 18,
                                          color: Color(0xFFFFB800),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          order.riderRating?.toStringAsFixed(
                                                1,
                                              ) ??
                                              '0.0',
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '• Gold Member',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$_eta',
                                    style: textTheme.headlineSmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'MINS ETA',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.secondary,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: () async {
                                    final hasPermission =
                                        await AppPermissions.requestMicrophonePermission(
                                          context,
                                        );
                                    if (hasPermission && mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Chat feature coming soon',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    Icons.chat,
                                    color: colorScheme.primary,
                                  ),
                                  label: const Text('Chat'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                  ),
                                  onPressed: () async {
                                    final hasPermission =
                                        await AppPermissions.requestPhonePermission(
                                          context,
                                        );
                                    if (hasPermission && mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Call feature coming soon',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.call),
                                  label: const Text('Call Rider'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            color: colorScheme.outlineVariant.withOpacity(0.35),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: colorScheme.tertiaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.shopping_bag,
                                      color: colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${order.items?.length ?? 1} Items from Demo Store',
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          order.items?.isNotEmpty == true
                                              ? (order
                                                        .items!
                                                        .first
                                                        .productName ??
                                                    'Your order')
                                              : 'Your order',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: colorScheme.secondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                            ),
                            onPressed: () =>
                                context.push('/customer/success', extra: order),
                            child: const Text('Mark Delivered (demo)'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 330,
            child: Column(
              children: [
                FloatingActionButton.small(
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.secondary,
                  onPressed: () async {
                    await context.read<LocationProvider>().refreshPosition();
                  },
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.secondary,
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerSuccessScreen extends StatelessWidget {
  const CustomerSuccessScreen({super.key, required this.order});

  final CustomerPlacedOrder order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.28),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 52,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Delivered Successfully!',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your order has been handed over. Enjoy your product',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  _Card(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Row(
                            children: [
                              Text(
                                'ORDER RECEIPT',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '#${order.id}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: colorScheme.outlineVariant.withOpacity(0.55),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _PriceRow(
                                label: 'Product Total',
                                value: formatTzs(order.draft.subtotalTzs),
                              ),
                              const SizedBox(height: 10),
                              _PriceRow(
                                label: 'Delivery Fee',
                                value: formatTzs(order.draft.deliveryFeeTzs),
                              ),
                              const SizedBox(height: 12),
                              Divider(
                                color: colorScheme.outlineVariant.withOpacity(
                                  0.75,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _PriceRow(
                                label: 'Grand Total',
                                value: formatTzs(order.draft.totalTzs),
                                bold: true,
                                valueColor: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&w=1200&q=80',
                                fit: BoxFit.cover,
                                color: Colors.white.withOpacity(0.7),
                                colorBlendMode: BlendMode.modulate,
                                errorBuilder: (_, __, ___) => ColoredBox(
                                  color: colorScheme.surfaceContainerHigh,
                                ),
                              ),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface.withOpacity(
                                      0.92,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: colorScheme.primary.withOpacity(
                                        0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Dar es Salaam, TZ',
                                        style: textTheme.labelLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Card(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: colorScheme.primaryContainer
                              .withOpacity(0.22),
                          child: Icon(
                            Icons.pedal_bike,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.riderName,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Rate Rider',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StarRow(colorScheme: colorScheme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 48,
                            height: 48,
                            color: colorScheme.surfaceContainerHigh,
                            child: Icon(
                              Icons.storefront,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.draft.offer.shopName,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Rate Shop',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: colorScheme.secondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () => context.go('/customer/explore'),
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Done'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () => context.go('/customer/explore'),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reorder'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final orders = CustomerDemoData.getOrderHistory();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;

    final filters = ['All', 'Pending', 'In Transit', 'Delivered'];

    final filteredOrders = _selectedFilter == 'All'
        ? orders
        : orders.where((order) {
            final status = order.status.toLowerCase().replaceAll(' ', '_');
            return status == _selectedFilter.toLowerCase().replaceAll(' ', '_');
          }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, max(12, topInset + 8), 16, 12),
              child: Row(
                children: [
                  Text(
                    'My Orders',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${orders.length}',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final selected = filter == _selectedFilter;
                  return FilterChip(
                    selected: selected,
                    label: Text(filter),
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: filters.length,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No orders found',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return _OrderCard(
                          order: order,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Order ${order.id} details coming soon',
                                ),
                              ),
                            );
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: filteredOrders.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, max(12, topInset + 8), 16, 120),
          child: Column(
            children: [
              _Card(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: colorScheme.primaryContainer.withOpacity(
                        0.3,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'John Doe',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+255 712 345 678',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'john.doe@email.com',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACCOUNT SETTINGS',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ProfileTile(
                      icon: Icons.location_on_outlined,
                      title: 'Delivery Addresses',
                      subtitle: 'Manage your delivery locations',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Delivery addresses coming soon'),
                          ),
                        );
                      },
                    ),
                    Divider(
                      color: colorScheme.outlineVariant.withOpacity(0.3),
                      height: 1,
                    ),
                    _ProfileTile(
                      icon: Icons.payment_outlined,
                      title: 'Payment Methods',
                      subtitle: 'M-Pesa, Cards, etc.',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment methods coming soon'),
                          ),
                        );
                      },
                    ),
                    Divider(
                      color: colorScheme.outlineVariant.withOpacity(0.3),
                      height: 1,
                    ),
                    _ProfileTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Push notifications, SMS',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notifications settings coming soon'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUPPORT',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ProfileTile(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      subtitle: 'FAQs, Contact support',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Help center coming soon'),
                          ),
                        );
                      },
                    ),
                    Divider(
                      color: colorScheme.outlineVariant.withOpacity(0.3),
                      height: 1,
                    ),
                    _ProfileTile(
                      icon: Icons.info_outline,
                      title: 'About Patapoa',
                      subtitle: 'Version 1.0.0',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('About coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logout coming soon')),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final CustomerPlacedOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final statusColor = switch (order.status) {
      'pending' => colorScheme.secondary,
      'in_transit' => colorScheme.primary,
      'delivered' => colorScheme.tertiary,
      _ => colorScheme.onSurfaceVariant,
    };

    final statusLabel = switch (order.status) {
      'pending' => 'Pending',
      'in_transit' => 'In Transit',
      'delivered' => 'Delivered',
      _ => 'Unknown',
    };

    return GestureDetector(
      onTap: onTap,
      child: _Card(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.id,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.draft.offer.productName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: colorScheme.outlineVariant.withOpacity(0.3),
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.draft.offer.shopName,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    formatTzs(order.draft.totalTzs),
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class _CategoryChipData {
  const _CategoryChipData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _FrostedCard extends StatelessWidget {
  const _FrostedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.9),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.25),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BottomSheetContainer extends StatelessWidget {
  const _BottomSheetContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BottomFixedSheet extends StatelessWidget {
  const _BottomFixedSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.35)),
        ),
      ),
      child: child,
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final style = bold
        ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)
        : textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant);
    final valueStyle = bold
        ? textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: valueColor,
          )
        : textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor ?? colorScheme.onSurface,
          );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: product.image != null
                      ? Image.network(
                          product.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: colorScheme.surfaceContainerHigh,
                            child: const Center(
                              child: Icon(Icons.image_not_supported_outlined),
                            ),
                          ),
                        )
                      : ColoredBox(
                          color: colorScheme.surfaceContainerHigh,
                          child: const Center(
                            child: Icon(Icons.shopping_bag_outlined),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.description ?? 'No description',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'TZS ${product.price.toStringAsFixed(0)}',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        if (!product.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Out of Stock',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.onTap});

  final CustomerOffer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: Image.network(
                    offer.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: colorScheme.surfaceContainerHigh,
                      child: const Center(
                        child: Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              offer.rating.toStringAsFixed(1),
                              style: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatTzs(offer.priceTzs),
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${offer.distanceKm.toStringAsFixed(1)}km away',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.offer, required this.onTap});

  final CustomerOffer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: Image.network(
                    offer.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: colorScheme.surfaceContainerHigh,
                      child: const Center(
                        child: Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            offer.productName,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _compactTzs(offer.priceTzs),
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 16,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            offer.shopName,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _Badge(
                          icon: Icons.social_distance_outlined,
                          label: '${offer.distanceKm.toStringAsFixed(1)}km',
                          background: colorScheme.surfaceContainerHighest,
                          foreground: colorScheme.onSurfaceVariant,
                        ),
                        _Badge(
                          icon: Icons.schedule,
                          label: '${offer.etaMinutes} mins',
                          background: colorScheme.primaryContainer.withOpacity(
                            0.22,
                          ),
                          foreground: colorScheme.primary,
                          pulse: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _compactTzs(int amount) {
  if (amount >= 1000 && amount < 1000000) {
    final k = (amount / 1000).round();
    return 'TZS ${k}k';
  }
  return formatTzs(amount);
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.pulse = false,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOut,
              builder: (context, value, child) =>
                  Opacity(opacity: value, child: child),
              child: Icon(icon, size: 16, color: foreground),
            )
          else
            Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bg = selected
        ? scheme.primaryContainer.withOpacity(0.22)
        : scheme.surfaceContainerHigh;
    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.content,
    this.accent,
  });

  final String title;
  final IconData icon;
  final String content;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iconColor = accent ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  content,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCardWide extends StatelessWidget {
  const _InfoCardWide({
    required this.title,
    required this.icon,
    required this.leading,
    required this.content,
    required this.trailing,
  });

  final String title;
  final IconData icon;
  final String leading;
  final String content;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, color: scheme.secondary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leading,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      content,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    trailing,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteField extends StatelessWidget {
  const _RouteField({
    required this.title,
    required this.titleColor,
    required this.bullet,
    required this.value,
    required this.trailing,
    this.valueStyle,
  });

  final String title;
  final Color titleColor;
  final Widget bullet;
  final String value;
  final Widget trailing;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            children: [
              bullet,
              Container(
                width: 2,
                height: 26,
                color: scheme.outlineVariant.withOpacity(0.7),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.labelSmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style:
                          valueStyle ??
                          textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  trailing,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(Icons.star_border, color: colorScheme.primaryContainer),
      ),
    );
  }
}

class _MapBackground extends StatelessWidget {
  const _MapBackground({
    required this.imageUrl,
    required this.overlayOpacityTop,
    required this.overlayOpacityBottom,
  });

  final String imageUrl;
  final double overlayOpacityTop;
  final double overlayOpacityBottom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              ColoredBox(color: scheme.surfaceContainerHigh),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.surface.withOpacity(overlayOpacityTop),
                scheme.surface.withOpacity(0),
                scheme.surface.withOpacity(0),
                scheme.surface.withOpacity(overlayOpacityBottom),
              ],
              stops: const [0, 0.22, 0.78, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _FlutterMapWidget extends StatelessWidget {
  const _FlutterMapWidget({
    required this.overlayOpacityTop,
    required this.overlayOpacityBottom,
    this.center,
    this.showUserLocation = true,
    this.userPosition,
    this.onTap,
    this.markers = const [],
    this.polylines = const [],
  });

  final double overlayOpacityTop;
  final double overlayOpacityBottom;
  final LatLng? center;
  final bool showUserLocation;
  final LatLng? userPosition;
  final void Function(TapPosition, LatLng)? onTap;
  final List<Marker> markers;
  final List<Polyline> polylines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mapCenter = center ?? const LatLng(-6.7924, 39.2083);
    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          options: MapOptions(
            center: mapCenter, 
            zoom: 13.0,
            onTap: onTap,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.patapoa',
            ),
            if (polylines.isNotEmpty)
              PolylineLayer(polylines: polylines),
            if (showUserLocation && userPosition != null || markers.isNotEmpty)
              MarkerLayer(
                markers: [
                  if (showUserLocation && userPosition != null)
                    Marker(
                      point: userPosition!,
                      width: 48,
                      height: 48,
                      child: _UserLocationDot(color: scheme.primary),
                    ),
                  ...markers,
                ],
              ),
          ],
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.surface.withOpacity(overlayOpacityTop),
                scheme.surface.withOpacity(0),
                scheme.surface.withOpacity(0),
                scheme.surface.withOpacity(overlayOpacityBottom),
              ],
              stops: const [0, 0.22, 0.78, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _UserLocationDot extends StatelessWidget {
  const _UserLocationDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.white, width: 2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DecorPin extends StatelessWidget {
  const _DecorPin({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _LabelPin extends StatelessWidget {
  const _LabelPin({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }
}

class _PulsingLocationPin extends StatelessWidget {
  const _PulsingLocationPin({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.7, end: 1.4),
              duration: const Duration(milliseconds: 1600),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return Opacity(
                  opacity: (1.6 - value).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: value,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Icon(
                Icons.my_location,
                size: 14,
                color: scheme.onTertiaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            'Your Location (Kijitonyama)',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.primary,
    required this.shopColor,
    required this.customerColor,
  });

  final Color primary;
  final Color shopColor;
  final Color customerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Offset(size.width * 0.25, size.height * 0.28);
    final p2 = Offset(size.width * 0.55, size.height * 0.48);
    final p3 = Offset(size.width * 0.75, size.height * 0.70);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..quadraticBezierTo(size.width * 0.38, size.height * 0.42, p2.dx, p2.dy)
      ..quadraticBezierTo(size.width * 0.66, size.height * 0.56, p3.dx, p3.dy);

    final paint = Paint()
      ..color = primary.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    _drawMarker(canvas, p1, shopColor, Icons.storefront_outlined);
    _drawMarker(canvas, p3, customerColor, Icons.home_outlined);
    _drawRider(canvas, p2);
  }

  void _drawMarker(Canvas canvas, Offset center, Color color, IconData icon) {
    final outer = Paint()..color = Colors.white.withOpacity(0.92);
    final inner = Paint()..color = color;
    canvas.drawCircle(center, 12, outer);
    canvas.drawCircle(center, 10, inner);
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawRider(Canvas canvas, Offset center) {
    final ring = Paint()..color = primary.withOpacity(0.25);
    final core = Paint()..color = shopColor;
    canvas.drawCircle(center, 18, ring);
    canvas.drawCircle(center, 14, core);
    final icon = Icons.pedal_bike;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CustomerPaymentGatewayScreen extends StatefulWidget {
  const CustomerPaymentGatewayScreen({super.key, required this.order});

  final CustomerPlacedOrder order;

  @override
  State<CustomerPaymentGatewayScreen> createState() =>
      _CustomerPaymentGatewayScreenState();
}

class _CustomerPaymentGatewayScreenState
    extends State<CustomerPaymentGatewayScreen> {
  String _selectedPayment = 'M-Pesa';
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _FlutterMapWidget(
              overlayOpacityTop: 0.86,
              overlayOpacityBottom: 0.92,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Text(
                          'Select Payment Method',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.secondaryContainer,
                        child: Icon(
                          Icons.person,
                          size: 18,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TOTAL AMOUNT',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.secondary,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatTzs(order.draft.totalTzs),
                                        style: textTheme.headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer
                                          .withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.account_balance_wallet,
                                      color: colorScheme.primary,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Payment Channels',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentOption(
                              title: 'M-Pesa',
                              subtitle: 'Vodacom Tanzania',
                              iconBg: Colors.red.shade600,
                              iconText: 'M',
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentOption(
                              title: 'Airtel Money',
                              subtitle: 'Airtel Tanzania',
                              iconBg: Colors.red.shade500,
                              iconText: 'A',
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentOption(
                              title: 'Tigo Pesa',
                              subtitle: 'Tigo Tanzania',
                              iconBg: Colors.blue.shade900,
                              iconText: 'T',
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentOption(
                              title: 'HaloPesa',
                              subtitle: 'Halotel Tanzania',
                              iconBg: Colors.orange.shade500,
                              iconText: 'H',
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentOption(
                              title: 'Bank Card',
                              subtitle: 'Visa, Mastercard',
                              iconBg: colorScheme.surfaceContainerHigh,
                              iconText: '',
                              iconData: Icons.credit_card,
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentOption(
                              title: 'Cash on Delivery',
                              subtitle: 'Pay when you receive',
                              iconBg: colorScheme.surfaceContainerHigh,
                              iconText: '',
                              iconData: Icons.payments_outlined,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.verified_user,
                                  size: 16,
                                  color: colorScheme.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'SECURE 256-BIT ENCRYPTED PAYMENT',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_processing)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          max(24, MediaQuery.paddingOf(context).bottom + 12),
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Final Total',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                  Text(
                    formatTzs(order.draft.totalTzs),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: _processing
                    ? null
                    : () async {
                        setState(() => _processing = true);
                        await Future<void>.delayed(const Duration(seconds: 2));
                        if (!context.mounted) return;
                        setState(() => _processing = false);
                        context.push('/customer/tracking', extra: order);
                      },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required Color iconBg,
    required String iconText,
    IconData? iconData,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _selectedPayment == title;

    return InkWell(
      onTap: () => setState(() => _selectedPayment = title),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: iconData != null
                  ? Icon(iconData, color: colorScheme.onSurfaceVariant)
                  : Text(
                      iconText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
