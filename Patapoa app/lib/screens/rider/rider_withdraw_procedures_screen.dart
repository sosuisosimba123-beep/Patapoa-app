import 'package:flutter/material.dart';

class RiderWithdrawProceduresScreen extends StatelessWidget {
  const RiderWithdrawProceduresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawal Procedures')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to Withdraw', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStep(
              number: '1',
              title: 'Accumulate Earnings',
              description: 'Deliver orders and earn delivery fees. Your balance will be updated instantly after every successful delivery.',
            ),
            _buildStep(
              number: '2',
              title: 'Set Payout Method',
              description: 'Ensure you have a registered M-Pesa, Tigo Pesa, or Airtel Money number in your profile settings.',
            ),
            _buildStep(
              number: '3',
              title: 'Request Withdrawal',
              description: 'Go to your Wallet and enter the amount you wish to withdraw. Minimum amount is TZS 5,000.',
            ),
            _buildStep(
              number: '4',
              title: 'Receive Funds',
              description: 'Requests are processed within 30 minutes. You will receive an SMS confirmation from your mobile provider.',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colorScheme.secondaryContainer.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.secondary),
                  const SizedBox(width: 16),
                  const Expanded(child: Text('Note: COD orders deduct the platform commission from your digital balance. Keep your balance positive to continue receiving orders.')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({required String number, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 14, child: Text(number, style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
