import 'package:flutter/material.dart';
import 'package:core/core.dart';
import '../screens/order_status.dart';
import '../screens/profile.dart';

/// Customer app implementation of notification navigation
class CustomerNotificationNavigationHandler
    implements NotificationNavigationHandler {
  @override
  void navigateToOrderStatus(
      BuildContext context, String orderId, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderStatusScreen(
          orderId: orderId,
          userId: userId,
        ),
      ),
    );
  }

  @override
  void navigateToVendorScreen(BuildContext context, String vendorId) {
    // Navigate to vendor details or menu screen
    // This would be implemented based on customer app's vendor screen
    debugPrint('Navigate to vendor: $vendorId');
    // Example:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => VendorMenuScreen(vendorId: vendorId),
    //   ),
    // );
  }

  @override
  void navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }
}
