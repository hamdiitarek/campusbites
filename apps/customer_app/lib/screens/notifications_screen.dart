import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:core/core.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Listen for notification taps from the service
    NotificationService().notificationStream.listen((data) {
      _handleNotificationTap(data);
    });
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // Use the notification navigation service to handle navigation
    if (!mounted) {
      debugPrint('Widget not mounted, skipping navigation');
      return;
    }

    // Let the notification navigation service handle the routing
    NotificationNavigationService().navigateFromNotification(context, data);
  }

  // Mark notification as read
  Future<void> _markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _auth.currentUser == null
          ? const Center(
              child: Text('You need to be logged in to view notifications'),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('notifications')
                  .where('userId', isEqualTo: _auth.currentUser!.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No notifications found'),
                  );
                }

                final notifications = snapshot.data!.docs
                    .map((doc) => OrderNotification.fromJson(
                        doc.data() as Map<String, dynamic>, doc.id))
                    .toList();

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Dismissible(
                      key: Key(notification.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        _firestore
                            .collection('notifications')
                            .doc(notification.id)
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification deleted'),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: _getNotificationIcon(notification.status),
                        title: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.read
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(notification.body),
                        trailing: Text(
                          _formatDate(notification.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          // Mark as read when tapped
                          if (!notification.read) {
                            _markAsRead(notification.id);
                          }

                          // Create data map similar to notification payload
                          final data = {
                            'orderId': notification.orderId,
                            'userId': notification.userId,
                            'route': 'order_status',
                            'status': notification.status
                          };

                          // Use navigation service to navigate to order status
                          NotificationNavigationService()
                              .navigateFromNotification(context, data);
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _getNotificationIcon(String status) {
    switch (status) {
      case 'confirmed':
        return const CircleAvatar(
          backgroundColor: Brand.tomato,
          child: Icon(Icons.soup_kitchen_outlined, color: Colors.white),
        );
      case 'ready':
        // Pickup, not delivery: the order waits at the counter.
        return const CircleAvatar(
          backgroundColor: Brand.basil,
          child: Icon(Icons.storefront_outlined, color: Colors.white),
        );
      case 'completed':
        return const CircleAvatar(
          backgroundColor: Brand.grill,
          child: Icon(Icons.done_all, color: Colors.white),
        );
      case 'cancelled':
        return const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.cancel, color: Colors.white),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.notifications, color: Colors.white),
        );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
