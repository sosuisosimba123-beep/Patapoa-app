import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../services/pocketbase_services.dart';
import '../../features/role_selection/role_selection_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isLoading = false;

  Future<void> _resendEmail() async {
    try {
      await pb.collection('users').requestVerification(widget.email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email resent! Check your inbox.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isLoading = true);
    try {
      await pb.collection('users').authRefresh();
      final model = pb.authStore.model as RecordModel?;
      final isVerified = model != null && model.data['verified'] == true;

      if (isVerified) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email not verified yet. Please check your link!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking status: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Your Email', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Check Your Inbox!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We sent a verification link to\n${widget.email}.\nClick the link in the email, then click the button below.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading ? null : _checkVerificationStatus,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('I Have Verified My Email', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resendEmail,
              child: const Text('Resend Verification Email', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }
}