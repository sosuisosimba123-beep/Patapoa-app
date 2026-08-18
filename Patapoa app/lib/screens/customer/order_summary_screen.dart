import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/liquid_glass_container.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key, required this.addressId});
  final int addressId;

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final OrderService _orderService = OrderService();
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'mpesa';

  // These would ideally come from an API call to calculate fees
  double get _deliveryFee => 2000.0; // Base fee from backend

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final order = await _orderService.createOrder({
        'address_id': widget.addressId,
        'items': cart.getOrderItems(),
        'payment_method': _selectedPaymentMethod,
      });

      if (mounted) {
        // Clear cart AFTER successful order creation
        cart.clear();
        context.go('/customer/payment-gateway', extra: order);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (cart.items.isEmpty && !_isProcessing) {
        return Scaffold(
          appBar: AppBar(title: const Text('Order Summary')),
          body: const Center(child: Text('Your cart is empty')),
        );
    }

    // Safely get the store name
    final storeName = cart.items.isNotEmpty
        ? (cart.items.first.product.merchant?['store_name'] ?? 'Local Store')
        : 'Store';

    return Scaffold(
      appBar: AppBar(title: const Text('Order Summary')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LiquidGlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items from $storeName',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 16),
                  ...cart.items.map((item) => _buildItemTile(item, textTheme)),
                  const Divider(height: 40),
                  _buildBillDetails(cart, colorScheme, textTheme),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Payment Method', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPaymentSelector(colorScheme),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isProcessing ? null : _placeOrder,
                child: _isProcessing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Proceed to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSelector(ColorScheme colorScheme) {
    return Column(
      children: [
        _paymentOption('mpesa', 'M-Pesa / ClickPesa', Icons.phone_android, colorScheme),
        _paymentOption('card', 'Credit/Debit Card', Icons.credit_card, colorScheme),
      ],
    );
  }

  Widget _paymentOption(String value, String title, IconData icon, ColorScheme colorScheme) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedPaymentMethod,
      onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
      title: Text(title),
      secondary: Icon(icon, color: _selectedPaymentMethod == value ? colorScheme.primary : null),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildItemTile(CartItem item, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8)
            ),
            child: Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(item.product.fullDisplayName, style: textTheme.bodyLarge, overflow: TextOverflow.ellipsis)),
          Text('TZS ${(item.product.price * item.quantity).toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _buildBillDetails(CartProvider cart, ColorScheme colorScheme, TextTheme textTheme) {
    final subtotal = cart.totalAmount;
    final total = subtotal + _deliveryFee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bill Details', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _BillRow(label: 'Items Total', value: subtotal),
        _BillRow(label: 'Delivery Fee', value: _deliveryFee),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total to Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('TZS ${total.toStringAsFixed(0)}',
              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20)
            ),
          ],
        ),
      ]
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final double value;
  const _BillRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text('TZS ${value.toStringAsFixed(0)}'),
        ],
      ),
    );
  }
}
