import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _selectedRole = 'customer';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Image.asset(
                      'assets/images/patapoa new logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Join Patapoa',
                      style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Select how you want to use the platform'),
                    const SizedBox(height: 40),
                    _roleTile('customer', 'Customer', 'Order products nearby', Icons.shopping_bag_outlined),
                    const SizedBox(height: 16),
                    _roleTile('merchant', 'Merchant', 'Sell your products', Icons.storefront_outlined),
                    const SizedBox(height: 16),
                    _roleTile('rider', 'Deliverer', 'Earn by delivering', Icons.motorcycle_outlined),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedRole == 'rider') {
                    context.go('/delivery-partner/login');
                  } else {
                    context.go('/register', extra: _selectedRole);
                  }
                },
                child: const Text('CONTINUE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleTile(String id, String title, String subtitle, IconData icon) {
    final isSelected = _selectedRole == id;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: () => setState(() => _selectedRole = id),
      leading: Icon(icon, color: isSelected ? colorScheme.primary : null, size: 24),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10)),
      trailing: Transform.scale(
        scale: 0.7,
        child: Radio<String>(
          value: id,
          groupValue: _selectedRole,
          onChanged: (v) => setState(() => _selectedRole = v!),
        ),
      ),
      dense: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? colorScheme.primary : Colors.black12, width: isSelected ? 1.5 : 1),
      ),
    );
  }
}
