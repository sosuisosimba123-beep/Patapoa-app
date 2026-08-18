import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/delivery_partner_service.dart';

class RiderCashReceivedScreen extends StatefulWidget {
  const RiderCashReceivedScreen({super.key, required this.orderId, required this.amount});
  final int orderId;
  final double amount;

  @override
  State<RiderCashReceivedScreen> createState() => _RiderCashReceivedScreenState();
}

class _RiderCashReceivedScreenState extends State<RiderCashReceivedScreen> {
  final DeliveryPartnerService _riderService = DeliveryPartnerService();
  bool _isLoading = false;

  Future<void> _confirmReceipt() async {
    setState(() => _isLoading = true);
    try {
      await _riderService.updateOrderStatus(widget.orderId, 'delivered');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment confirmed and order completed!')));
        context.go('/delivery-partner/home');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: colorScheme.primaryContainer.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(Icons.payments, size: 64, color: colorScheme.primary),
              ),
              const SizedBox(height: 32),
              Text('Cash Received?', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Please confirm that you have received the exact amount from the customer for Order #${widget.orderId}.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount to Collect', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('TZS ${widget.amount.toStringAsFixed(0)}', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _confirmReceipt,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirm & Complete Order'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.pop(), child: const Text('Go Back')),
            ],
          ),
        ),
      ),
    );
  }
}
