import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      String identity = _loginController.text.trim();
      
      if (identity.startsWith('+')) {
        identity = identity.substring(1);
      }

      final success = await authProvider.login(
        identity,
        _passwordController.text,
      );

      if (success && mounted) {
        _navigateHome(authProvider.user);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? 'Login failed')),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    // Default to customer only if we don't know the role. 
    // In login, we usually don't know the role until they login.
    // However, we should allow them to pick or just detect it.
    final success = await authProvider.signInWithGoogle('customer');

    if (mounted) {
      if (success) {
        _navigateHome(authProvider.user);
      } else if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage!)),
        );
      }
    }
  }

  void _navigateHome(User? user) {
    if (user == null) {
      context.go('/role');
      return;
    }

    final userType = user.userType;
    if (userType == 'customer') {
      context.go('/customer/explore');
    } else if (userType == 'merchant') {
      context.go('/merchant/home');
    } else if (userType == 'rider') {
      context.go('/delivery-partner/home');
    } else {
      context.go('/role');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/images/patapoa logo.jpg',
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
                Text(
                  'Login to Patapoa',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return OutlinedButton.icon(
                      onPressed: auth.isLoading ? null : _handleGoogleSignIn,
                      icon: Image.network(
                        'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                        height: 18,
                        width: 18,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.login, size: 18),
                      ),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Colors.black12),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _loginController,
                  decoration: const InputDecoration(
                    labelText: 'Email or Phone Number',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 32),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
                      child: auth.isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('LOGIN'),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Register', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
