import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/order.dart';
import '../../widgets/liquid_glass_container.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(children: [
          _buildCelebrationHeader(colorScheme, textTheme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              _buildDigitalReceipt(colorScheme, textTheme),
              const SizedBox(height: 24),
              if (order.riderName != null)
                _buildRatingTile(
                  title: order.riderName!,
                  subtitle: 'Rate Rider',
                  icon: Icons.person,
                  colorScheme: colorScheme,
                ),
              const SizedBox(height: 12),
              _buildRatingTile(
                title: order.merchantName,
                subtitle: 'Rate Shop',
                icon: Icons.storefront,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 40),
              _buildActions(context, colorScheme),
              const SizedBox(height: 40),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildCelebrationHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [colorScheme.primaryContainer.withValues(alpha: 0.4), Colors.transparent],
        ),
      ),
      child: Column(children: [
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text('Delivered Successfully!', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
        const SizedBox(height: 8),
        Text('Your order has been handed over. Enjoy!', style: textTheme.bodyLarge, textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildDigitalReceipt(ColorScheme colorScheme, TextTheme textTheme) {
    return LiquidGlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      opacity: 0.1,
      blur: 15,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('ORDER RECEIPT', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 12)),
            Text(order.displayId, style: const TextStyle(fontSize: 12)),
          ]),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            _ReceiptRow(label: 'Product Total', value: 'TZS ${order.subtotal.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            _ReceiptRow(label: 'Delivery Fee', value: 'TZS ${order.deliveryFee.toStringAsFixed(0)}'),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Grand Total', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text('TZS ${order.total.toStringAsFixed(0)}', style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ]),
          ]),
        ),
        Container(
          height: 120, width: double.infinity,
          color: Colors.grey.withValues(alpha: 0.05),
          child: Stack(alignment: Alignment.center, children: [
            Opacity(opacity: 0.3, child: Image.network('https://tile.openstreetmap.org/15/300/600.png', fit: BoxFit.cover, width: double.infinity)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.location_on, size: 16, color: Colors.green), SizedBox(width: 4), Text('Dar es Salaam, TZ', style: TextStyle(fontSize: 12))])),
          ]),
        ),
      ]),
    );
  }

  Widget _buildRatingTile({required String title, required String subtitle, required IconData icon, required ColorScheme colorScheme}) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      opacity: 0.05,
      blur: 5,
      child: Row(children: [
        CircleAvatar(child: Icon(icon)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 12)),
        ])),
        const Row(children: [
          Icon(Icons.star_outline, color: Colors.amber, size: 20),
          Icon(Icons.star_outline, color: Colors.amber, size: 20),
          Icon(Icons.star_outline, color: Colors.amber, size: 20),
          Icon(Icons.star_outline, color: Colors.amber, size: 20),
          Icon(Icons.star_outline, color: Colors.amber, size: 20),
        ]),
      ]),
    );
  }

  Widget _buildActions(BuildContext context, ColorScheme colorScheme) {
    return Column(children: [
      SizedBox(width: double.infinity, height: 56, child: FilledButton(onPressed: () => context.go('/customer/explore'), child: const Text('Done'))),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, height: 56, child: OutlinedButton(onPressed: () => context.go('/customer/explore'), child: const Text('Reorder'))),
    ]);
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label, value;
  const _ReceiptRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]);
  }
}
