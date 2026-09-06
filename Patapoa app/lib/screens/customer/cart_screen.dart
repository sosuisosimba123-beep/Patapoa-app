import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/address_service.dart';
import '../../widgets/patapoa_product_image.dart';
import '../../widgets/liquid_glass_container.dart';
import '../../utils/analytics_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final AddressService _addressService = AddressService();
  bool _isProcessing = false;
  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final addresses = await _addressService.getAddresses();
      if (mounted) setState(() { _addresses = addresses; _selectedAddress = addresses.isNotEmpty ? addresses.first : null; });
    } catch (_) {}
  }

  Future<void> _checkout() async {
    final auth = provider.Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) { context.go('/login'); return; }
    if (_selectedAddress == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a delivery address'))); return; }

    final cart = provider.Provider.of<CartProvider>(context, listen: false);
    AnalyticsService.logBeginCheckout(
      value: cart.totalAmount,
      items: cart.items.map((i) => AnalyticsEventItem(
        itemId: i.product.id.toString(),
        itemName: i.product.fullDisplayName,
        itemCategory: i.product.categorySlug,
        price: i.product.price,
        quantity: i.quantity,
      )).toList(),
    );

    setState(() => _isProcessing = true);
    // Proceed to order summary/checkout
    context.push('/customer/order-summary', extra: {
      'address_id': _selectedAddress!['id'],
    });
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = provider.Provider.of<CartProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart'), actions: [
        if (cart.items.isNotEmpty)
          IconButton(onPressed: () => cart.clear(), icon: const Icon(Icons.delete_outline, color: Colors.red))
      ]),
      body: cart.items.isEmpty
        ? _buildEmptyState(colorScheme)
        : Column(children: [
            if (cart.items.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Text(
                  'Shopping from: ${cart.items.first.product.merchant?['store_name'] ?? 'Local Store'}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: cart.items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                   final item = cart.items[i];
                   return _CartItemTile(item: item);
                }
              )
            ),
            _buildCheckoutSection(cart, colorScheme),
          ]),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.shopping_cart_outlined, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
      const SizedBox(height: 16),
      const Text('Your cart is empty'),
      const SizedBox(height: 8),
      TextButton(onPressed: () => context.go('/customer/explore'), child: const Text('Start Shopping')),
    ]));
  }

  Widget _buildCheckoutSection(CartProvider cart, ColorScheme colorScheme) {
    return LiquidGlassContainer(
      borderRadius: 0,
      blur: 20,
      opacity: 0.9,
      padding: const EdgeInsets.all(24),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_addresses.isNotEmpty) ...[
          const Row(children: [Icon(Icons.location_on_outlined, size: 16), SizedBox(width: 8), Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8),
          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: _selectedAddress,
            items: _addresses.map((a) => DropdownMenuItem(value: a, child: Text(a['address_line_1'], overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setState(() => _selectedAddress = v),
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
          ),
          const SizedBox(height: 16),
        ],
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${cart.itemCount} items', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          Text('TZS ${cart.totalAmount.toStringAsFixed(0)}', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: _isProcessing ? null : _checkout,
            child: _isProcessing ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Checkout')
          )
        ),
      ])),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = provider.Provider.of<CartProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LiquidGlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        opacity: 0.05,
        blur: 5,
        child: Row(children: [
          PatapoaProductImage(
            imageUrl: item.product.displayImage,
            categorySlug: item.product.categorySlug,
            width: 60, height: 60,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.product.fullDisplayName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('TZS ${item.product.price.toStringAsFixed(0)} each', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ])),
          Row(children: [
            IconButton(onPressed: () => cart.updateQuantity(item.product.id, item.quantity - 1), icon: const Icon(Icons.remove_circle_outline, size: 20)),
            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => cart.updateQuantity(item.product.id, item.quantity + 1), icon: const Icon(Icons.add_circle_outline, size: 20)),
          ]),
        ]),
      ),
    );
  }
}
