import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/liquid_glass_container.dart';
import '../../screens/common/verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String? initialRole;
  const RegisterScreen({super.key, this.initialRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late String _selectedUserType;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _selectedUserType = widget.initialRole ?? 'customer';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Privacy Policy to continue.')),
      );
      return;
    }
    
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      passwordConfirmation: _confirmPasswordController.text.trim(),
      userType: _selectedUserType,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyEmailScreen(email: _emailController.text.trim()),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Registration failed')),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle(_selectedUserType);

    if (mounted) {
      if (success) {
        context.go('/role'); // AuthProvider will handle further redirection
      } else if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
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
                      // Logo/Brand
                      Image.asset(
                        'assets/images/patapoa new logo.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 32),
    
                      // User Type Selection
                      Text(
                        'I am a:',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text('Customer'),
                            value: 'customer',
                            groupValue: _selectedUserType,
                            onChanged: (value) => setState(() => _selectedUserType = value!),
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<String>(
                            title: const Text('Merchant'),
                            value: 'merchant',
                            groupValue: _selectedUserType,
                            onChanged: (value) => setState(() => _selectedUserType = value!),
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<String>(
                            title: const Text('Rider'),
                            value: 'rider',
                            groupValue: _selectedUserType,
                            onChanged: (value) => setState(() => _selectedUserType = value!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
    
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          // Filter out potentially harmful characters
                          if (RegExp(r'[<>{}\[\]\\]').hasMatch(value)) {
                            return 'Invalid characters in name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
    
                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(Icons.phone),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          // Strict phone validation
                          if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value.trim())) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
    
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is mandatory';
                          }
                          // Strict email validation
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
    
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
    
                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
    
                      // Privacy Policy Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptedTerms,
                            onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                              child: const Text.rich(
                                TextSpan(
                                  text: 'I agree to the ',
                                  children: [
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    TextSpan(text: ' and Terms of Service'),
                                  ],
                                ),
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
    
                      // Register Button
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
                                icon: Image.network(
                                  'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                                  height: 20,
                                  width: 20,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.login),
                                ),
                                label: const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF1F1F1F),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1F1F1F),
                                  side: const BorderSide(color: Color(0xFFD1D1D1)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 1,
                                  shadowColor: Colors.black12,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
    
                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? '),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text('Login', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                          ),
                        ],
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
