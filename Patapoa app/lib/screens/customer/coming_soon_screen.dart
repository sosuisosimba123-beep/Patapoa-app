import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../services/api_service.dart';

class ComingSoonScreen extends StatefulWidget {
  final LatLng position;
  final String? initialSearch;

  const ComingSoonScreen({
    super.key,
    required this.position,
    this.initialSearch,
  });

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isSubmitting = false;
  bool _submitted = false;

  Future<void> _submitWaitlist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final contact = _contactController.text;
      final isEmail = contact.contains('@');

      await _apiService.post('/waitlist', {
        if (isEmail) 'email': contact else 'phone': contact,
        'latitude': widget.position.latitude,
        'longitude': widget.position.longitude,
        'city': context.read<LocationProvider>().currentAddress,
        'requested_product': widget.initialSearch,
      });

      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join waitlist: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coming Soon'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_outlined, size: 80, color: colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Patapoa is coming to your area!',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We currently don\'t operate in this region yet, but we are expanding fast.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!_submitted) ...[
                Text(
                  'Join the waitlist to be the first to know when we launch here:',
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      hintText: 'Email or Phone Number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.contact_mail_outlined),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submitWaitlist,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Join Waitlist'),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Thanks! We\'ve added you to the waitlist. We\'ll reach out soon!',
                          style: TextStyle(color: Colors.green.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go back to Map'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
