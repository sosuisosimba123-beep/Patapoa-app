import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/merchant_service.dart';
import '../../models/product.dart';
import '../../widgets/patapoa_product_image.dart';
import '../../widgets/liquid_glass_container.dart';

class MerchantInventoryScreen extends StatefulWidget {
  const MerchantInventoryScreen({super.key});

  @override
  State<MerchantInventoryScreen> createState() => _MerchantInventoryScreenState();
}

class _MerchantInventoryScreenState extends State<MerchantInventoryScreen> {
  final _scrollController = ScrollController();
  final MerchantService _merchantService = MerchantService();
  List<Product> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadProducts() async {
    setState(() { _isLoading = true; _currentPage = 1; _hasMore = true; });
    try {
      final products = await _merchantService.getProducts(page: 1, limit: 20);
      if (mounted) setState(() { _products = products; _isLoading = false; _hasMore = products.length >= 20; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final products = await _merchantService.getProducts(page: _currentPage + 1, limit: 20);
      if (mounted) {
        setState(() { _products.addAll(products); _currentPage++; _hasMore = products.length >= 20; _isLoadingMore = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) _loadMoreProducts();
  }

  Future<void> _deleteProduct(String id) async {
    try {
      await _merchantService.deleteProduct(id);
      setState(() => _products.removeWhere((p) => p.id == id));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filtered = _products.where((p) => p.fullDisplayName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(textTheme, context),
            _buildSearchField(colorScheme),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                  ? Center(child: Text('No products found', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)))
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
                      itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, i) => i < filtered.length
                        ? _ProductCard(
                            product: filtered[i],
                            onEdit: () => context.go('/merchant/edit-product', extra: filtered[i]),
                            onDelete: () => _deleteProduct(filtered[i].id))
                        : const Center(child: CircularProgressIndicator()),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/merchant/add-product'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Text('Inventory', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const Spacer(),
          // Replaced header button with FAB for better UX
        ],
      ),
    );
  }

  Widget _buildSearchField(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LiquidGlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        borderRadius: 16,
        opacity: 0.1,
        blur: 10,
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search products...',
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LiquidGlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      opacity: 0.1,
      blur: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: PatapoaProductImage(
              imageUrl: product.displayImage,
              categorySlug: product.categorySlug,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.fullDisplayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('TZS ${product.price.toStringAsFixed(0)}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: FilledButton.tonal(
                      onPressed: onEdit, 
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ), 
                      child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
                    )),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: onDelete,
                        icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
