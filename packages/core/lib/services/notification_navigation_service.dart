import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Interface for app-specific navigation handlers
abstract class NotificationNavigationHandler {
  void navigateToOrderStatus(
      BuildContext context, String orderId, String userId);
  void navigateToVendorScreen(BuildContext context, String vendorId);
  void navigateToProfile(BuildContext context);
  // Add more navigation methods as needed
}

/// Service to handle navigation from notifications
class NotificationNavigationService {
  static final NotificationNavigationService _instance =
      NotificationNavigationService._internal();

  factory NotificationNavigationService() {
    return _instance;
  }

  NotificationNavigationService._internal();

  NotificationNavigationHandler? _navigationHandler;

  /// Set the app-specific navigation handler
  void setNavigationHandler(NotificationNavigationHandler handler) {
    _navigationHandler = handler;
  }

  /// Navigate to the appropriate screen based on notification data
  void navigateFromNotification(
      BuildContext context, Map<String, dynamic> data) {
    if (_navigationHandler == null) {
      debugPrint('No navigation handler set for notifications');
      _showError(context, 'Navigation not configured');
      return;
    }

    // Handle order status navigation
    if (_isOrderStatusNotification(data)) {
      _navigateToOrderStatus(context, data);
    }
    // Add more notification types here as needed
  }

  /// Check if notification is for order status
  bool _isOrderStatusNotification(Map<String, dynamic> data) {
    return data.containsKey('orderId') &&
        ((data.containsKey('route') && data['route'] == 'order_status') ||
            (data.containsKey('navigateTo') &&
                data['navigateTo'] == 'order_status'));
  }

  /// Navigate to the order status screen
  void _navigateToOrderStatus(BuildContext context, Map<String, dynamic> data) {
    final orderId = data['orderId'];

    // Get userId from notification or current user
    final userId = data.containsKey('userId')
        ? data['userId']
        : FirebaseAuth.instance.currentUser?.uid;

    // Check if we have the required data and user is authenticated
    if (orderId == null || userId == null) {
      debugPrint('Cannot navigate to order status: Missing orderId or userId');
      _showError(context, 'Cannot view order: Missing information');
      return;
    }

    // Handle JSON orderData if available
    if (data.containsKey('orderData')) {
      try {
        // If any additional processing is needed for orderData
        debugPrint('Using additional order data for navigation');
      } catch (e) {
        debugPrint('Error parsing orderData: $e');
      }
    }

    // Navigate using the app-specific handler
    debugPrint('Navigating to order status: orderId=$orderId, userId=$userId');
    _navigationHandler!.navigateToOrderStatus(context, orderId, userId);
  }

  /// Show error message
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Check if user is authenticated
  bool isUserAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }
}
