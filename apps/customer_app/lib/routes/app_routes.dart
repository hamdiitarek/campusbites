import 'package:flutter/material.dart';
import 'package:core/core.dart';
import '../screens/menu.dart';
import '../screens/search_vendor.dart';
import '../screens/search_item.dart';
import '../screens/notifications_screen.dart';
import '../navigation/main_tab_navigation.dart';
import '../screens/order_status.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String searchVendor = '/search';
  static const String searchItem = '/search_item';
  static const String emailVerification = '/email-verification';
  static const String home = '/home';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String menu = '/menu';
  static const String notifications = '/notifications';
  static const String orderStatus = '/order-status';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => LoginScreen(
            demoEmail: DemoAccounts.student,
            onLoginSuccess: (context, userRole, isEmailVerified) {
              if (userRole != 'student') {
                _showAccessDenied(context);
              } else if (!isEmailVerified) {
                Navigator.pushReplacementNamed(context, emailVerification);
              } else {
                Navigator.pushReplacementNamed(context, home);
              }
            },
          ),
      signup: (context) => const SignupScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      emailVerification: (context) => EmailVerificationScreen(
            onVerificationSuccess: (context, userRole) {
              if (userRole == 'student') {
                Navigator.pushReplacementNamed(context, home);
              } else {
                _showAccessDenied(context);
              }
            },
          ),
      '/access-denied': (context) => _buildAccessDeniedScreen(),
      home: (context) => const MainTabNavigation(initialIndex: 0),
      history: (context) => const MainTabNavigation(initialIndex: 1),
      profile: (context) => const MainTabNavigation(initialIndex: 2),
      searchVendor: (context) => const SearchScreen(),
      searchItem: (context) => const SearchItemScreen(),
      menu: (context) => const MenuScreen(vendorId: ""),
      notifications: (context) => const NotificationsScreen(),
      orderStatus: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final orderId = args?['orderId'] as String?;
        final userId = args?['userId'] as String?;

        if (orderId == null || userId == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Text('Missing order information. Please try again.'),
            ),
          );
        }

        return OrderStatusScreen(
          orderId: orderId,
          userId: userId,
        );
      },
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
              const Text('This app is only for students.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Sign out user and go back to login
                  Navigator.pushReplacementNamed(context, '/login');
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
