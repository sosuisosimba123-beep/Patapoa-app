import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/liquid_glass_container.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _selectedRole = 'customer';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: AnimatedLiquidBackground(
        child: Column(
          children: [
            // Top Space Section - Glass Header with Logo
            LiquidGlassContainer(
              borderRadius: 0,
              padding: EdgeInsets.zero,
              blur: 20,
              opacity: 0.8,
              color: const Color(0xFF181C1C),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.35,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/patapoa new logo.png',
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'PATAPOA',
                          style: textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join Patapoa as...',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your role to get started with the best local commerce experience in Tanzania.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
    
                    // Role Cards
                    _buildRoleCard(
                      id: 'customer',
                      title: 'Customer',
                      subtitle: 'Get products nearby instantly',
                      icon: Icons.shopping_bag_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      id: 'merchant',
                      title: 'Merchant',
                      subtitle: 'Sell to local customers daily',
                      icon: Icons.storefront_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      id: 'rider',
                      title: 'Deliverer',
                      subtitle: 'Earn by delivering orders',
                      icon: Icons.motorcycle_outlined,
                    ),
    
                    const SizedBox(height: 40),
    
                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward),
                                ],
                              ),
                      ),
                    ),
    
                    const SizedBox(height: 24),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text(
                              'Log in',
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == id;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = id),
      child: LiquidGlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        opacity: isSelected ? 0.2 : 0.05,
        blur: isSelected ? 10 : 5,
        color: isSelected ? colorScheme.primary : Colors.white,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Custom Radio built with Container to avoid deprecated members
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                  width: 2,
                ),
              ),
              child: isSelected
                ? Center(child: Container(width: 12, height: 12, decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle)))
                : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (_selectedRole == 'customer') {
      context.go('/register', extra: 'customer');
    } else if (_selectedRole == 'merchant') {
      context.go('/register', extra: 'merchant');
    } else if (_selectedRole == 'rider') {
      context.go('/delivery-partner/login');
    }
  }
}
