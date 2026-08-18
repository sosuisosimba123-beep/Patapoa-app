import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/patapoa_product_image.dart';
import '../../widgets/liquid_glass_container.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  void _addToCart() async {
    final cart = provider.Provider.of<CartProvider>(context, listen: false);
    final error = cart.addItem(widget.product, quantity: _quantity);

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
      appBar: AppBar(title: const Text('Product Details'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildImage(product, colorScheme),
          const SizedBox(height: 24),
          _buildInfoRow(product, textTheme, colorScheme),
          const SizedBox(height: 24),
          _buildQuantitySelector(textTheme, colorScheme),
          const SizedBox(height: 24),
          if (product.displayName != product.name) ...[
             Text('Category', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
             Text(product.name ?? 'Unspecified', style: TextStyle(color: colorScheme.onSurfaceVariant)),
             const SizedBox(height: 16),
          ],
          _buildDescription(product, textTheme, colorScheme),
          const SizedBox(height: 24),
          _buildMerchantCard(product, colorScheme),
        ]),
      ),
      bottomNavigationBar: _buildBottomBar(product, colorScheme),
    );
  }

  Widget _buildImage(Product product, ColorScheme colorScheme) {
    return PatapoaProductImage(
      imageUrl: product.displayImage,
      categorySlug: product.categorySlug,
      borderRadius: BorderRadius.circular(20),
      height: 350,
      width: double.infinity,
    );
  }

  Widget _buildInfoRow(Product product, TextTheme textTheme, ColorScheme colorScheme) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.fullDisplayName, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(product.isAvailable ? 'In Stock' : 'Out of Stock', style: TextStyle(color: product.isAvailable ? colorScheme.primary : colorScheme.error)),
        ])),
        Text('TZS ${product.price.toStringAsFixed(0)}', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildQuantitySelector(TextTheme textTheme, ColorScheme colorScheme) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 16,
      opacity: 0.05,
      blur: 5,
      child: Row(children: [
        const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null, icon: const Icon(Icons.remove)),
        Text('$_quantity', style: textTheme.titleMedium),
        IconButton(onPressed: () => setState(() => _quantity++), icon: const Icon(Icons.add)),
      ]),
    );
  }

  Widget _buildDescription(Product product, TextTheme textTheme, ColorScheme colorScheme) {
    final desc = product.description ?? product.masterProduct?.description ?? 'Locally sourced quality product.';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Description', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(desc, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
    ]);
  }

  Widget _buildMerchantCard(Product product, ColorScheme colorScheme) {
    final merchant = product.merchant;
    if (merchant == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.primaryContainer.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(Icons.storefront, size: 32),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(merchant['store_name'] ?? 'Store', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(merchant['city'] ?? 'Dar es Salaam', style: const TextStyle(fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _buildBottomBar(Product product, ColorScheme colorScheme) {
    return SafeArea(child: Padding(
      padding: const EdgeInsets.all(16),
      child: FilledButton(
        onPressed: product.isAvailable ? _addToCart : null,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        child: Text(product.isAvailable ? 'Add to Cart' : 'Out of Stock'),
      ),
    ));
  }
}
