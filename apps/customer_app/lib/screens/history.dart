import 'package:core/core.dart';
import 'order_status.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, Vendor> _vendors = {};

  @override
  void initState() {
    super.initState();
    // A campus has a handful of vendors; load them once for names and photos.
    VendorService().getVendors().then((vendors) {
      if (mounted)
        setState(() => _vendors = {for (final v in vendors) v.id: v});
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Brand.cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text(
          'Order History',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // OrderService writes orders to /orders and the vendor's copy only,
        // so history reads the main collection (same query as order status).
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Brand.tomato),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final orders = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final items = order['items'] as List<dynamic>? ?? [];
              final status = order['status']?.toString() ?? 'Unknown';

              return _buildOrderCard(
                  context, order, orderId, items, status, userId);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order,
      String orderId, List<dynamic> items, String status, String userId) {
    final vendor = _vendors[order['vendorId']];
    final total = (order['total'] as num?) ??
        items.fold<num>(
            0,
            (sum, item) =>
                sum +
                ((item['price'] as num? ?? 0) *
                    (item['quantity'] as num? ?? 0)));
    final createdAt = order['createdAt'] is Timestamp
        ? (order['createdAt'] as Timestamp).toDate()
        : null;
    final summary = items
        .map((item) => '${item['name'] ?? 'Item'} ×${item['quantity'] ?? 1}')
        .join(', ');

    return GestureDetector(
      onTap: () => _navigateToOrderStatus(context, orderId, userId),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  StorageImage(vendor?.imageUrl ?? '', width: 56, height: 56),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor?.name ?? 'Order #${orderId.substring(0, 8)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  if (createdAt != null)
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    summary.isEmpty ? 'No items in this order' : summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Brand.egp(total),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _buildStatusChip(status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final time = DateFormat('HH:mm').format(date);
    if (DateUtils.isSameDay(date, now)) return 'Today · $time';
    if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday · $time';
    }
    return '${DateFormat('EEE d MMM').format(date)} · $time';
  }

  Widget _buildStatusChip(String status) {
    final statusData = _getStatusData(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: statusData['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusData['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusData['color'],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusData['label'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusData['color'],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusData(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return {
          'color': Colors.grey[700],
          'label': 'Completed',
        };
      case 'confirmed':
        return {
          'color': Brand.tomatoDeep,
          'label': 'Confirmed',
        };
      case 'pending':
        return {
          'color': Colors.orange[800],
          'label': 'Pending',
        };
      case 'cancelled':
        return {
          'color': Colors.red[600],
          'label': 'Cancelled',
        };
      case 'ready':
        return {
          'color': Brand.basil,
          'label': 'Ready',
        };
      default:
        return {
          'color': Colors.grey[600],
          'label': status.toUpperCase(),
        };
    }
  }

  void _navigateToOrderStatus(
      BuildContext context, String orderId, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderStatusScreen(
          isFromCheckout: false,
          orderId: orderId,
          userId: userId,
        ),
      ),
    );
  }
}
