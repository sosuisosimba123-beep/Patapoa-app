import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class RiderRegistrationStep2Screen extends StatefulWidget {
  final Map<String, dynamic> registrationData;
  const RiderRegistrationStep2Screen({super.key, required this.registrationData});

  @override
  State<RiderRegistrationStep2Screen> createState() => _RiderRegistrationStep2ScreenState();
}

class _RiderRegistrationStep2ScreenState extends State<RiderRegistrationStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _driverLicenseController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedVehicleType = 'bicycle';
  bool _isLoading = false;

  @override
  void dispose() {
    _licensePlateController.dispose();
    _driverLicenseController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = widget.registrationData;
      await _authService.register(
        name: data['name'] ?? '',
        phone: data['phone'] ?? '',
        password: _passwordController.text,
        userType: 'rider',
        email: data['email'],
        city: data['city'],
        additionalData: {
          'vehicle_type': _selectedVehicleType,
          'license_plate': _licensePlateController.text,
          'driver_license': _driverLicenseController.text,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful. Please login.')),
        );
        context.go('/delivery-partner/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topInset = math.max(12.0, MediaQuery.paddingOf(context).top);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vehicle Details',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'STEP 2 OF 3',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: index < 2
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'Tell us about your ride',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose the vehicle you\'ll be using for deliveries to get the right tasks.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _VehicleTypeOption(
                              icon: Icons.pedal_bike,
                              label: 'Bicycle',
                              isSelected: _selectedVehicleType == 'bicycle',
                              onTap: () => setState(() => _selectedVehicleType = 'bicycle'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _VehicleTypeOption(
                              icon: Icons.motorcycle,
                              label: 'Boda Boda',
                              isSelected: _selectedVehicleType == 'boda',
                              onTap: () => setState(() => _selectedVehicleType = 'boda'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _VehicleTypeOption(
                              icon: Icons.directions_car,
                              label: 'Car',
                              isSelected: _selectedVehicleType == 'car',
                              onTap: () => setState(() => _selectedVehicleType = 'car'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        label: 'License Plate (Optional)',
                        icon: Icons.tag,
                        placeholder: 'E.g. T 123 ABC',
                        controller: _licensePlateController,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'License Number (Optional)',
                        icon: Icons.badge,
                        placeholder: 'Enter license number',
                        controller: _driverLicenseController,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Choose a Password',
                        icon: Icons.lock,
                        placeholder: '••••••••',
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) => (value?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _register,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.arrow_forward),
                          label: Text(_isLoading ? 'Processing...' : 'Complete Registration'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required String placeholder,
    required TextEditingController controller,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            hintText: placeholder,
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _VehicleTypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleTypeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}
