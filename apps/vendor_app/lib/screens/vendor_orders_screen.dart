import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart' as core;
import 'package:core/theme/brand.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
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

  static const Color primaryColor = Brand.tomato;

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
        return Brand.tomato;
      case 'ready':
        return Brand.basil;
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
                                _statusFilter = newDisplayStatus.toLowerCase();
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
                    final query = _searchQuery.toLowerCase();
                    final matchesSearch = query.isEmpty ||
                        order.id.toLowerCase().contains(query) ||
                        order.items
                            .any((i) => i.name.toLowerCase().contains(query));
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
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          iconColor: primaryColor,
                          collapsedIconColor: Colors.grey[600],
                          shape: const Border(),
                          collapsedShape: const Border(),
                          tilePadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
                          title: Row(
                            children: [
                              Text(
                                '#${order.id.substring(0, 6).toUpperCase()}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  getDisplayStatus(order.status),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.items
                                      .map((i) => '${i.quantity}× ${i.name}')
                                      .join(', '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 15, color: Brand.grill),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${Brand.egp(order.total)} · ${order.paymentMethod} · '
                                  '${DateFormat('HH:mm').format(order.createdAt)}'
                                    '${DateTime.now().difference(order.createdAt).inMinutes >= 1 ? ' ($relativeTime)' : ''}',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          children: [
                            const Divider(height: 1),
                            ...order.items.map((item) => ListTile(
                                  dense: true,
                                  title: Text('${item.quantity}× ${item.name}',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                  subtitle: item.customizations.isEmpty &&
                                          item.note.isEmpty
                                      ? null
                                      : Text([
                                          ...item.customizations.keys,
                                          if (item.note.isNotEmpty)
                                            '"${item.note}"',
                                        ].join(' · ')),
                                  trailing: Text(
                                      Brand.egp(item.price * item.quantity)),
                                )),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                              child: Builder(
                                builder: (context) {
                                  _orderStatusKeys[order.id] ??= GlobalKey();

                                  final List<String> statusOptions = [
                                    'Pending',
                                    'Confirmed',
                                    'Ready',
                                    'Completed',
                                    'Cancelled'
                                  ];

                                  final Map<String, String> statusValueMap = {
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
                                      if (newStatusDisplay == null) return;

                                      final newStatus =
                                          statusValueMap[newStatusDisplay] ??
                                              'pending';
                                      try {
                                        await _orderService.updateOrderStatus(
                                            order.id, vendorId, newStatus);
                                      } catch (e) {
                                        debugPrint(
                                            'Error updating order status: $e');
                                      }
                                    },
                                  );
                                },
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
