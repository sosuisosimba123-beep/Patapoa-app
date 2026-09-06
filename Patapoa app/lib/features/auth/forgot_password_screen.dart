import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/pocketbase_services.dart';
import '../../widgets/liquid_glass_container.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      
      // Request password reset via PocketBase
      await pb.collection('users').requestPasswordReset(email);

      if (!mounted) return;
      
      // Show success dialog or snackbar
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Check Your Email'),
          content: Text('A password reset link has been sent to $email. Please check your inbox and follow the instructions.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                context.go('/login'); // Go back to login
              },
              child: const Text('Back to Login'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => context.go('/login'),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedLiquidBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LiquidGlassContainer(
                padding: const EdgeInsets.all(32),
                borderRadius: 40,
                opacity: 0.15,
                blur: 25,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.lock_reset,
                        size: 80,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Forgot Password',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter your email address and we\'ll send you a link to reset your password.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
                      ),
                      const SizedBox(height: 32),
    
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
    
                      // Reset Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleResetPassword,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Send Reset Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
