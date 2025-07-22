// Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart' as core;
import 'package:timeago/timeago.dart' as timeago;
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class VendorSalesScreen extends StatefulWidget {
  const VendorSalesScreen({super.key});

  @override
  State<VendorSalesScreen> createState() => _VendorSalesScreenState();
}

final currentUser = FirebaseAuth.instance.currentUser;
final String? vendorId = currentUser?.uid;

class _VendorSalesScreenState extends State<VendorSalesScreen> {
  String _statusFilter = 'All';
  String _dateFilter = 'Today';
  String _searchQuery = '';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  static const Color primaryColor = Color(0xFF0055FF);

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  bool isInDateRange(DateTime orderDate) {
    if (_dateFilter == 'Custom Range') {
      if (_customStartDate == null || _customEndDate == null) return false;
      final inclusiveEnd = _customEndDate!.add(const Duration(days: 1));
      return (orderDate.isAtSameMomentAs(_customStartDate!) ||
          orderDate.isAfter(_customStartDate!)) &&
          orderDate.isBefore(inclusiveEnd);
    }

    final now = DateTime.now();
    switch (_dateFilter) {
      case 'Today':
        return orderDate.year == now.year &&
            orderDate.month == now.month &&
            orderDate.day == now.day;
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        return orderDate.year == yesterday.year &&
            orderDate.month == yesterday.month &&
            orderDate.day == yesterday.day;
      case 'Last 7 Days':
        return orderDate.isAfter(now.subtract(const Duration(days: 7)));
      case 'This Month':
        return orderDate.year == now.year && orderDate.month == now.month;
      default:
        return true;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _customStartDate = picked;
        } else {
          _customEndDate = picked;
        }
        _dateFilter = 'Custom Range';
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _searchQuery = value.trim());
      }
    });
  }

  double computeRevenue(List<core.Order> orders) {
    return orders
        .where((o) => o.status == 'completed')
        .fold(0.0, (sum, o) => sum + o.total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Sales History'),
      ),
      body: GestureDetector(
        onTap: () => _searchFocusNode.unfocus(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search by Order ID',
                        prefixIcon: const Icon(Icons.search,
                            color: primaryColor), // Blue icon
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Expanded(
                        child: Text('Filter by Date',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text('Status',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: CustomDropdown<String>(
                            hintText: 'Date Filter',
                            items: const [
                              'Today',
                              'Yesterday',
                              'Last 7 Days',
                              'This Month',
                              'Custom Range',
                              'All'
                            ],
                            initialItem: _dateFilter,
                            onChanged: (val) {
                              setState(() => _dateFilter = val ?? 'Today');
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: CustomDropdown<String>(
                            hintText: 'Status',
                            items: const ['All', 'completed', 'cancelled'],
                            initialItem: _statusFilter,
                            onChanged: (val) {
                              setState(() => _statusFilter = val ?? 'All');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_dateFilter == 'Custom Range') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _customStartDate == null
                                        ? 'Start Date'
                                        : DateFormat('MMM d, y')
                                        .format(_customStartDate!),
                                  ),
                                  const Icon(Icons.calendar_today, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _customEndDate == null
                                        ? 'End Date'
                                        : DateFormat('MMM d, y')
                                        .format(_customEndDate!),
                                  ),
                                  const Icon(Icons.calendar_today, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vendors')
                  .doc(vendorId)
                  .collection('orders')
                  .where('status', whereIn: ['completed', 'cancelled'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final orders = docs
                    .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return core.Order.fromMap(doc.id, data);
                })
                    .where((order) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      order.id
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                  final matchesStatus = _statusFilter == 'All' ||
                      order.status.toLowerCase() ==
                          _statusFilter.toLowerCase();
                  final inDateRange = isInDateRange(order.createdAt);
                  return matchesSearch && matchesStatus && inDateRange;
                })
                    .toList();

                final totalRevenue = computeRevenue(orders);
                final completedOrders =
                    orders.where((o) => o.status == 'completed').length;

                return Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: Column(
                      children: [
                        Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: ListTile(
                            title: const Text('Total Sales'),
                            subtitle:
                            Text('$completedOrders completed orders'),
                            trailing:
                            Text('EGP ${totalRevenue.toStringAsFixed(2)}'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              final statusColor = order.status == 'completed'
                                  ? Colors.grey
                                  : Colors.red;
                              final relativeTime =
                              timeago.format(order.createdAt);

                              return Card(
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
                                        title: Text('Order ID: ${order.id}'),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text('Status: ${order.status}'),
                                            Text(
                                                'Payment: ${order.paymentMethod}'),
                                            Text(
                                                'Total: EGP ${order.total.toStringAsFixed(2)}'),
                                            Text('Placed: $relativeTime'),
                                          ],
                                        ),
                                        children: order.items
                                            .map((item) => ListTile(
                                          title: Text(item.name),
                                          subtitle: Text(
                                              'Qty: ${item.quantity}, Price: ${item.price}'),
                                        ))
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
