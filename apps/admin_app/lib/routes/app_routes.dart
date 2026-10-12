import 'package:flutter/material.dart';
import 'package:core/core.dart';
import '../screens/admin_screen.dart';
import '../screens/users_display_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String adminHome = '/admin-home';
  static const String usersDisplay = '/users-display';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => LoginScreen(
            demoEmail: DemoAccounts.admin,
            onLoginSuccess: (context, userRole, isEmailVerified) {
              if (userRole != 'admin') {
                _showAccessDenied(context);
              } else if (!isEmailVerified) {
                Navigator.pushReplacementNamed(context, emailVerification);
              } else {
                Navigator.pushReplacementNamed(context, adminHome);
              }
            },
          ),
      signup: (context) => const SignupScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      emailVerification: (context) => EmailVerificationScreen(
            onVerificationSuccess: (context, userRole) {
              if (userRole == 'admin') {
                Navigator.pushReplacementNamed(context, adminHome);
              } else {
                _showAccessDenied(context);
              }
            },
          ),
      '/access-denied': (context) => _buildAccessDeniedScreen(),
      adminHome: (context) => const AdminVendorManagementScreen(),
      usersDisplay: (context) => const AdminUsersScreen(),
    };
  }

  // Helper methods for access denied handling
  static void _showAccessDenied(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/access-denied');
  }

  static Widget _buildAccessDeniedScreen() {
    return Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text('This app is only for administrators.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Sign out user and go back to login
                  Navigator.pushReplacementNamed(context, login);
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to push route and remove all previous routes
  static void navigateToAndRemoveUntil(BuildContext context, String routeName) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
    );
  }
}
