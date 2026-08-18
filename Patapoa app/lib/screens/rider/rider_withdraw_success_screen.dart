import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RiderWithdrawSuccessScreen extends StatelessWidget {
  const RiderWithdrawSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle, size: 100, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text('Success!', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Your withdrawal request has been processed', textAlign: TextAlign.center),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 56, child: FilledButton(onPressed: () => context.go('/delivery-partner/earnings'), child: const Text('Back to Wallet'))),
        ]),
      ))),
    );
  }
}
