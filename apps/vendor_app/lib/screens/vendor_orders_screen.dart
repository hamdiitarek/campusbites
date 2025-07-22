import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart' as core;
import 'package:timeago/timeago.dart' as timeago;
import 'package:animated_custom_dropdown/custom_dropdown.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  late final String vendorId;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _sortBy = 'Newest';
  final core.OrderService _orderService = core.OrderService();

  final Map<String, GlobalKey> _orderStatusKeys = {};

  static const Color primaryColor = Color(0xFF0055FF); // Blue theme color

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      vendorId = currentUser.uid;
    } else {
      vendorId = "OxXH2puas7WJHxeZdKOfDZybyah2";
    }
  }

  String getDisplayStatus(String status) {
    if (status == 'All') return 'All';
    if (status.isEmpty) return '';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Live Orders'),
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: () async => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Updated Search Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search item...',
                    prefixIcon: const Icon(Icons.search, color: primaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim());
                  },
                ),
              ),
            ),

            // Filter + Sort Labels and Menus
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Text('Filter by Status',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Text('Sort by',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomDropdown<String>(
                          hintText: 'Filter by Status',
                          items: const [
                            'All',
                            'Pending',
                            'Confirmed',
                            'Ready',
                            'Completed',
                            'Cancelled'
                          ],
                          initialItem: getDisplayStatus(_statusFilter),
                          onChanged: (newDisplayStatus) {
                            setState(() {
                              if (newDisplayStatus == null ||
                                  newDisplayStatus == 'All') {
                                _statusFilter = 'All';
                              } else {
                                _statusFilter =
                                    newDisplayStatus.toLowerCase();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomDropdown<String>(
                          hintText: 'Sort by',
                          items: const ['Newest', 'Oldest'],
                          initialItem: _sortBy,
                          onChanged: (newValue) {
                            setState(() {
                              _sortBy = newValue ?? 'Newest';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Orders List
            Expanded(
              child: StreamBuilder<List<core.Order>>(
                stream: _orderService.getVendorOrders(vendorId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<core.Order> allOrders = snapshot.data ?? [];

                  if (allOrders.isEmpty) {
                    return const Center(child: Text('No orders found.'));
                  }

                  var filteredOrders = allOrders.where((order) {
                    final matchesSearch = _searchQuery.isEmpty ||
                        order.id
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                    final isFromToday = isToday(order.createdAt);
                    final matchesStatus = _statusFilter == 'All'
                        ? order.status != 'completed' &&
                        order.status != 'cancelled'
                        : order.status == _statusFilter;
                    return matchesSearch && matchesStatus && isFromToday;
                  }).toList();

                  if (_sortBy == 'Oldest') {
                    filteredOrders
                        .sort((a, b) => a.createdAt.compareTo(b.createdAt));
                  } else {
                    filteredOrders
                        .sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  }

                  return ListView.builder(
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final relativeTime = timeago.format(order.createdAt);
                      final statusColor = getStatusColor(order.status);

                      return Card(
                        key: ValueKey(order.id),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 120,
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ExpansionTile(
                                iconColor: primaryColor,
                                collapsedIconColor: primaryColor,
                                title: Text(
                                  'Order ID: ${order.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Status: ${order.status}'),
                                    Text('Payment: ${order.paymentMethod}'),
                                    Text(
                                        'Total: EGP ${order.total.toStringAsFixed(2)}'),
                                    Text('Placed: $relativeTime'),
                                  ],
                                ),
                                children: [
                                  ...order.items.map((item) => ListTile(
                                    title: Text(item.name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text('Qty: ${item.quantity}'),
                                        Text('Note: ${item.note}'),
                                        Text(
                                            'Price: ${item.price.toStringAsFixed(2)}'),
                                      ],
                                    ),
                                  )),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8),
                                    child: Builder(
                                      builder: (context) {
                                        _orderStatusKeys[order.id] ??=
                                            GlobalKey();

                                        final List<String> statusOptions = [
                                          'Pending',
                                          'Confirmed',
                                          'Ready',
                                          'Completed',
                                          'Cancelled'
                                        ];

                                        final Map<String, String>
                                        statusValueMap = {
                                          'Pending': 'pending',
                                          'Confirmed': 'confirmed',
                                          'Ready': 'ready',
                                          'Completed': 'completed',
                                          'Cancelled': 'cancelled'
                                        };

                                        String currentStatus =
                                        getDisplayStatus(order.status);

                                        return CustomDropdown<String>(
                                          hintText: 'Update Order Status',
                                          items: statusOptions,
                                          initialItem: currentStatus,
                                          onChanged: (newStatusDisplay) async {
                                            if (newStatusDisplay == null)
                                              return;

                                            final newStatus = statusValueMap[
                                            newStatusDisplay] ??
                                                'pending';
                                            try {
                                              await _orderService
                                                  .updateOrderStatus(order.id,
                                                  vendorId, newStatus);
                                            } catch (e) {
                                              debugPrint(
                                                  'Error updating order status: $e');
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
