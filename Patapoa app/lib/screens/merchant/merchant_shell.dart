import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/liquid_glass_container.dart';

class MerchantShell extends StatefulWidget {
  const MerchantShell({super.key, required this.child});
  final Widget child;

  @override
  State<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<MerchantShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedLiquidBackground(child: widget.child),
      bottomNavigationBar: LiquidGlassContainer(
        borderRadius: 0,
        padding: EdgeInsets.zero,
        blur: 10,
        opacity: 0.8,
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            switch (index) {
              case 0: context.go('/merchant/home'); break;
              case 1: context.go('/merchant/orders'); break;
              case 2: context.go('/merchant/inventory'); break;
              case 3: context.go('/merchant/payouts'); break;
              case 4: context.go('/merchant/profile'); break;
            }
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
            NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
