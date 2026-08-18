import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RiderRegistrationStep1Screen extends StatefulWidget {
  const RiderRegistrationStep1Screen({super.key});

  @override
  State<RiderRegistrationStep1Screen> createState() => _RiderRegistrationStep1ScreenState();
}

class _RiderRegistrationStep1ScreenState extends State<RiderRegistrationStep1Screen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedCity = 'Select your city';
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms')),
      );
      return;
    }
    context.go('/delivery-partner/register/step2', extra: {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'city': _selectedCity,
    });
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
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Patapoa',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Step 1 of 3',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(color: colorScheme.primary),
                  ),
                  const Expanded(flex: 2, child: SizedBox()),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Let\'s start with your basic details to get you registered.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildLabel(textTheme, colorScheme, 'FULL NAME'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(colorScheme, 'Enter your full name', Icons.person),
                        validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel(textTheme, colorScheme, 'PHONE NUMBER'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        decoration: _inputDecoration(colorScheme, '07XX XXX XXX', Icons.call),
                        keyboardType: TextInputType.phone,
                        validator: (value) => value?.isEmpty ?? true ? 'Phone is required' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel(textTheme, colorScheme, 'EMAIL ADDRESS (OPTIONAL)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration(colorScheme, 'name@example.com', Icons.email),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel(textTheme, colorScheme, 'CITY OF OPERATION'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCity == 'Select your city' ? null : _selectedCity,
                        hint: Text(_selectedCity),
                        decoration: _inputDecoration(colorScheme, '', Icons.location_on),
                        items: ['Dar es Salaam', 'Arusha', 'Mwanza', 'Dodoma']
                            .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedCity = value!),
                        validator: (value) => value == null ? 'Please select a city' : null,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (v) => setState(() => _agreedToTerms = v!),
                          ),
                          Expanded(
                            child: Text(
                              'I agree to Patapoa\'s Terms of Service and Privacy Policy',
                              style: textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _nextStep,
                  child: const Text('Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(TextTheme textTheme, ColorScheme colorScheme, String text) {
    return Text(
      text,
      style: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }

  InputDecoration _inputDecoration(ColorScheme colorScheme, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
