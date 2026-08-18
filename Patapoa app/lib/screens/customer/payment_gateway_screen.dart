import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order.dart';
import '../../services/payment_service.dart';

class PaymentGatewayScreen extends StatefulWidget {
  const PaymentGatewayScreen({super.key, required this.order});
  final Order order;

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  late String _selectedPayment;
  bool _processing = false;
  bool _isPolling = false;
  final PaymentService _paymentService = PaymentService();
  Timer? _statusTimer;
  int _pollCount = 0;
  static const int maxPolls = 60; // 5 minutes

  @override
  void initState() {
    super.initState();
    _selectedPayment = _mapMethodToName(widget.order.paymentMethod);
  }

  String _mapMethodToName(String method) {
    return switch (method) {
      'mpesa' => 'M-Pesa',
      'airtel_money' => 'Airtel Money',
      'tigo_pesa' => 'Tigo Pesa',
      'halopesa' => 'HaloPesa',
      'card' => 'Bank Card',
      _ => 'M-Pesa',
    };
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling(int orderId) {
    _statusTimer?.cancel();
    _pollCount = 0;
    setState(() => _isPolling = true);

    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _pollCount++;
      if (_pollCount > maxPolls) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _processing = false;
            _isPolling = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment verification timeout. If you paid, please check your orders later.'),
              duration: Duration(seconds: 10),
            ),
          );
        }
        return;
      }

      try {
        final data = await _paymentService.checkPaymentStatus(orderId);
        if (data['payment_status'] == 'paid' || data['status'] == 'confirmed') {
          timer.cancel();
          if (mounted) {
            setState(() {
              _processing = false;
              _isPolling = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment confirmed!'), backgroundColor: Colors.green),
            );
            context.pushReplacement('/customer/tracking', extra: widget.order);
          }
        }
      } catch (e) {
        debugPrint('Error polling status: $e');
      }
    });
  }

  Future<void> _handlePayment() async {
    setState(() => _processing = true);

    try {
      final method = switch (_selectedPayment) {
        'M-Pesa' => 'mpesa',
        'Airtel Money' => 'airtel_money',
        'Tigo Pesa' => 'tigo_pesa',
        'HaloPesa' => 'halopesa',
        'Bank Card' => 'card',
        _ => 'mpesa',
      };

      final response = await _paymentService.initiatePayment(
        orderId: widget.order.id,
        paymentMethod: method,
      );

      final String? instruction = response['data']?['instruction'] ?? response['instruction'];
      if (mounted && instruction != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(instruction),
            duration: const Duration(seconds: 8),
          ),
        );
      }

      final String? paymentUrl = response['data']?['payment_url'] ?? response['payment_url'];
      if (paymentUrl != null) {
        final uri = Uri.parse(paymentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      _startStatusPolling(widget.order.id);

    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildBalanceCard(colorScheme, textTheme),
          const SizedBox(height: 24),
          if (_isPolling) _buildPollingStatus(colorScheme, textTheme) else ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption('M-Pesa', 'Powered by ClickPesa', Colors.red.shade600),
            _buildPaymentOption('Airtel Money', 'Powered by ClickPesa', Colors.red.shade500),
            _buildPaymentOption('Tigo Pesa', 'Powered by ClickPesa', Colors.blue.shade900),
            _buildPaymentOption('HaloPesa', 'Powered by ClickPesa', Colors.orange.shade500),
            _buildPaymentOption('Bank Card', 'Visa/Mastercard via ClickPesa', Colors.grey),
          ],
          const SizedBox(height: 24),
          Opacity(
            opacity: 0.6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 14),
                const SizedBox(width: 8),
                Text('Secure Encrypted Payments', style: textTheme.labelSmall),
              ],
            ),
          ),
        ]),
      ),
      bottomNavigationBar: SafeArea(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isPolling)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextButton.icon(
                  onPressed: () => _startStatusPolling(widget.order.id),
                  icon: const Icon(Icons.refresh),
                  label: const Text('I have completed the payment (Manual Check)'),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_processing || _isPolling) ? null : _handlePayment,
                child: (_processing || _isPolling)
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm Payment'),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildPollingStatus(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Waiting for USSD Confirmation...',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Please complete the payment on your phone. This screen will automatically update once done.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }


  Widget _buildBalanceCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TOTAL AMOUNT'),
              Text('TZS ${widget.order.total.toStringAsFixed(0)}', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const Icon(Icons.account_balance_wallet, size: 40),
          ]),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order ID', style: textTheme.bodyMedium),
              Text(widget.order.displayId, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, String subtitle, Color color) {
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: title,
      groupValue: _selectedPayment,
      onChanged: (v) => setState(() => _selectedPayment = v!),
      secondary: CircleAvatar(backgroundColor: color, radius: 20),
    );
  }
}
