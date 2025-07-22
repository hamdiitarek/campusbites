import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/services/user_provider.dart';

/// Callback function type for handling post-verification navigation
typedef EmailVerificationSuccessCallback = void Function(
    BuildContext context, String userRole);

class EmailVerificationScreen extends StatefulWidget {
  final EmailVerificationSuccessCallback? onVerificationSuccess;

  const EmailVerificationScreen({super.key, this.onVerificationSuccess});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = true;
  bool _emailSent = true;
  Timer? _timer;
  bool _isVerified = true;

  @override
  void initState() {
    super.initState();
    _checkInitialVerificationStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialVerificationStatus() async {
    setState(() {
      _isLoading = true;
    });

    final isVerified = true;
    //await userProvider.checkEmailVerification();

    if (mounted) {
      setState(() {
        _isVerified = isVerified;
        _isLoading = false;
      });

      if (isVerified) {
        _proceedToHome();
      } else {
        // Start polling for verification status
        _startVerificationCheck();
      }
    }
  }

  void _startVerificationCheck() {
    // Check every 5 seconds if the email has been verified
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      // Commented out for testing
      // final userProvider = Provider.of<UserProvider>(context, listen: false);
      // final isVerified = await userProvider.checkEmailVerification();
      final isVerified = true; // Force verified for testing

      if (mounted) {
        setState(() {
          _isVerified = isVerified;
        });

        if (isVerified) {
          _timer?.cancel();
          _proceedToHome();
        }
      }
    });
  }

  Future<void> _sendVerificationEmail() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    // Commented out for testing
    // final success = await userProvider.sendVerificationEmail();
    final success = true; // Force success for testing

    if (mounted) {
      setState(() {
        _isLoading = false;
        _emailSent = success;
      });

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _proceedToHome() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final role = userProvider.user?.role ?? 'student';

    // Use callback for app-specific navigation
    if (widget.onVerificationSuccess != null) {
      widget.onVerificationSuccess!(context, role);
    } else {
      // Default behavior if no callback is provided
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : _buildVerificationContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.email_outlined,
          size: 80,
          color: Colors.blue,
        ),
        const SizedBox(height: 24),
        Text(
          _isVerified ? 'Email Verified!' : 'Verify Your Email',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isVerified
              ? 'Your email has been successfully verified.'
              : 'We\'ve sent a verification email to your registered email address. '
                  'Please check your inbox and click the verification link.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),
        if (_isVerified) ...[
          ElevatedButton(
            onPressed: _proceedToHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Continue to Home'),
          ),
        ] else ...[
          const Text(
            'Didn\'t receive the email?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _emailSent ? null : _sendVerificationEmail,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child:
                Text(_emailSent ? 'Email Sent' : 'Resend Verification Email'),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () async {
              // Sign out and return to login
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              await userProvider.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('Back to Login'),
          ),
        ],
      ],
    );
  }
}
