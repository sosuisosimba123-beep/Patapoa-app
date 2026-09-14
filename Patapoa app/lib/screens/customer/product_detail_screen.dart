import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/patapoa_product_image.dart';
import '../../widgets/liquid_glass_container.dart';
import '../../utils/analytics_service.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logItemViewed(
      itemId: widget.product.id.toString(),
      itemName: widget.product.fullDisplayName,
      category: widget.product.categorySlug,
      price: widget.product.price,
    );
  }

  void _addToCart() async {
    final cart = provider.Provider.of<CartProvider>(context, listen: false);
    final error = cart.addItem(widget.product, quantity: _quantity);
    
    if (error == null) {
      AnalyticsService.logAddToCart(
        itemId: widget.product.id.toString(),
        itemName: widget.product.fullDisplayName,
        category: widget.product.categorySlug,
        price: widget.product.price,
        quantity: _quantity,
      );
    }

    if (error == "DIFFERENT_MERCHANT") {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear Cart?'),
          content: const Text('Your cart already contains items from another shop. Would you like to clear it and add this item instead?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('CLEAR & ADD', style: TextStyle(color: Colors.red))),
          ],
        ),
      );

      if (confirm == true) {
        cart.addItem(widget.product, quantity: _quantity, force: true);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart cleared and item added')));
        }
      }
    } else if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Added ${widget.product.fullDisplayName} to cart'),
        action: SnackBarAction(label: 'View Cart', onPressed: () => context.push('/customer/cart')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Product Details'), 
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildImage(product, colorScheme),
          const SizedBox(height: 28),
          _buildInfoRow(product, textTheme, colorScheme),
          const SizedBox(height: 28),
          _buildQuantitySelector(textTheme, colorScheme),
          const SizedBox(height: 28),
          _buildDescription(product, textTheme, colorScheme),
          const SizedBox(height: 28),
          _buildMerchantCard(product, colorScheme),
          const SizedBox(height: 100),
        ]),
      ),
      bottomSheet: _buildBottomBar(product, colorScheme, textTheme),
    );
  }

  Widget _buildImage(Product product, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: PatapoaProductImage(
          imageUrl: product.displayImage,
          categorySlug: product.categorySlug,
          borderRadius: BorderRadius.circular(32),
          height: 380,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildInfoRow(Product product, TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.fullDisplayName, 
                style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'TZS ${product.price.toStringAsFixed(0)}', 
              style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w900)
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: product.isAvailable ? colorScheme.primary.withValues(alpha: 0.1) : colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: product.isAvailable ? colorScheme.primary.withValues(alpha: 0.2) : colorScheme.error.withValues(alpha: 0.2)),
          ),
          child: Text(
            product.isAvailable ? 'AVAILABLE IN STOCK' : 'OUT OF STOCK',
            style: TextStyle(
              color: product.isAvailable ? colorScheme.primary : colorScheme.error,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            )
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(TextTheme textTheme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const SizedBox(width: 12),
        const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white70)),
        const Spacer(),
        IconButton.filledTonal(
          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
          icon: const Icon(Icons.remove),
          style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(width: 16),
        Text('$_quantity', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(width: 16),
        IconButton.filledTonal(
          onPressed: () => setState(() => _quantity++),
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]),
    );
  }

  Widget _buildDescription(Product product, TextTheme textTheme, ColorScheme colorScheme) {
    final desc = product.description ?? product.masterProduct?.description ?? 'Locally sourced quality product.';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ABOUT PRODUCT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white54, letterSpacing: 1.5)),
      const SizedBox(height: 12),
      Text(desc, style: textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.8), height: 1.6)),
    ]);
  }

  Widget _buildMerchantCard(Product product, ColorScheme colorScheme) {
    final merchant = product.merchant;
    if (merchant == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.storefront, color: colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(merchant['store_name'] ?? 'Store', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
          Text(merchant['city'] ?? 'Dar es Salaam', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
        ])),
        const Icon(Icons.chevron_right, color: Colors.white24),
      ]),
    );
  }

  Widget _buildBottomBar(Product product, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: product.isAvailable ? _addToCart : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: product.isAvailable ? colorScheme.primary : colorScheme.error.withValues(alpha: 0.3),
          ),
          child: Text(product.isAvailable ? 'ADD TO BASKET' : 'OUT OF STOCK'),
        ),
      ),
    );
  }
}
