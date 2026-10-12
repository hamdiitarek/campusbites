import 'dart:async';
import 'package:core/core.dart';
import 'package:flutter/material.dart';

class OrderStatusScreen extends StatefulWidget {
  final bool isFromCheckout;
  final String orderId;
  final String userId;

  const OrderStatusScreen({
    super.key,
    required this.orderId,
    required this.userId,
    this.isFromCheckout = false,
  });

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final OrderService orderService = OrderService();
  final VendorService vendorService = VendorService();
  Order? currentOrder;
  Vendor? currentVendor;
  StreamSubscription<List<Order>>? _orderSubscription;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderAndSubscribe();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderAndSubscribe() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // First, try to get the order directly
      await _getOrderDirectly();

      // Subscribe to real-time updates for this specific order
      _orderSubscription = orderService.getUserOrders(widget.userId).listen(
        (orders) {
          // Find the current order in the list
          final orderIndex =
              orders.indexWhere((Order o) => o.id == widget.orderId);
          final order = orderIndex != -1 ? orders[orderIndex] : null;

          if (order != null) {
            setState(() {
              currentOrder = order;
              _isLoading = false;
            });

            // Load vendor information
            _loadVendorInfo(order.vendorId);
          }
        },
        onError: (error) {
          print('Stream error: $error');
          // If stream fails, try to get the order directly
          _getOrderDirectly();
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading order: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getOrderDirectly() async {
    try {
      final order = await orderService.getOrderById(widget.orderId);

      if (order != null) {
        setState(() {
          currentOrder = order;
          _isLoading = false;
        });

        // Load vendor information
        _loadVendorInfo(order.vendorId);
      } else {
        setState(() {
          _errorMessage = 'Order not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading order: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVendorInfo(String vendorId) async {
    try {
      final vendor = await vendorService.getVendorById(vendorId);
      if (vendor != null && mounted) {
        setState(() {
          currentVendor = vendor;
        });
      }
    } catch (e) {
      print('Error loading vendor info: $e');
    }
  }

  Color _getStatusColor() {
    if (currentOrder == null) return Colors.orange;

    switch (currentOrder!.status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Brand.tomato;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Brand.basil;
      case 'completed':
        return Brand.basil;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Brand.cream,
        appBar: AppBar(
          title:
              const Text('Order Status', style: TextStyle(color: Colors.black)),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              // if (widget.isFromCheckout) {
              //   _navigateToHome();
              // } else {
              Navigator.pop(context);
              // }
            },
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Brand.cream,
        appBar: AppBar(
          title:
              const Text('Order Status', style: TextStyle(color: Colors.black)),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              // if (widget.isFromCheckout) {
              //   _navigateToHome();
              // } else {
              Navigator.pop(context);
              // }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrderAndSubscribe,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (currentOrder == null) {
      return Scaffold(
        backgroundColor: Brand.cream,
        appBar: AppBar(
          title:
              const Text('Order Status', style: TextStyle(color: Colors.black)),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              // if (widget.isFromCheckout) {
              //   _navigateToHome();
              // } else {
              Navigator.pop(context);
              // }
            },
          ),
        ),
        body: const Center(
          child: Text('No order found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Brand.cream,
      appBar: AppBar(
        title:
            const Text('Order Status', style: TextStyle(color: Colors.black)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // if (widget.isFromCheckout) {
            //   _navigateToHome();
            // } else {
            Navigator.pop(context);
            // }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Restaurant Info
            _buildRestaurantInfo(),

            // Where the order is right now
            _buildProgress(),

            const SizedBox(height: 16),

            // Order Items
            _buildOrderItems(),

            const SizedBox(height: 16),

            // Delivery Info
            _buildDeliveryInfo(),

            const SizedBox(height: 16),

            // Payment Summary
            _buildPaymentSummary(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: StorageImage(currentVendor?.imageUrl ?? '',
                width: 60, height: 60),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentVendor?.name ?? 'Loading...',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order #${currentOrder?.id.substring(0, 8) ?? 'Loading...'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentOrder?.status.toUpperCase() ?? 'PENDING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _steps = ['pending', 'confirmed', 'ready', 'completed'];
  static const _stepLabels = ['Placed', 'Confirmed', 'Ready', 'Picked up'];

  String _headline(String status) {
    final vendor = currentVendor?.name ?? 'The vendor';
    switch (status) {
      case 'pending':
        return 'Waiting for $vendor to accept';
      case 'confirmed':
        return '$vendor is preparing your order';
      case 'ready':
        return 'Ready! Pick it up at the counter';
      case 'completed':
        return 'Picked up. Enjoy your meal';
      case 'cancelled':
        return 'This order was cancelled';
      default:
        return status;
    }
  }

  Widget _buildProgress() {
    final status = currentOrder?.status ?? 'pending';
    final current = _steps.indexOf(status);
    final cancelled = status == 'cancelled';

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _headline(status),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: cancelled ? Colors.red[700] : Brand.grill,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 3,
                      color: !cancelled && i <= current
                          ? Brand.tomato
                          : Colors.grey[300],
                    ),
                  ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !cancelled && i <= current
                        ? Brand.tomato
                        : Colors.grey[300],
                    border: i == current && !cancelled
                        ? Border.all(color: Brand.tomatoTint, width: 4)
                        : null,
                  ),
                  child: !cancelled && i < current
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _steps.length; i++)
                Text(
                  _stepLabels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        i == current ? FontWeight.w700 : FontWeight.w500,
                    color: !cancelled && i <= current
                        ? Brand.grill
                        : Colors.grey[500],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    final items = currentOrder?.items ?? [];

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Your Order',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No items in order'),
            )
          else
            ...items.map((item) => _buildOrderItem(item)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${item.quantity}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Brand.basil,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Note: ${item.note}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                if (item.customizations.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.customizations.keys.join(' · '),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            Brand.egp(item.price * item.quantity),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pickup Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });

                  // Refresh order data
                  if (currentOrder != null) {
                    final refreshedOrder = await orderService.getOrderById(
                      currentOrder!.id,
                      vendorId: currentOrder!.vendorId,
                    );

                    if (refreshedOrder != null) {
                      setState(() {
                        currentOrder = refreshedOrder;
                        _isLoading = false;
                      });
                    } else {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh order status',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red[400], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentVendor?.universityName ?? 'Location not available',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          if (currentOrder?.createdAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Order placed: ${_formatDateTime(currentOrder!.createdAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildPaymentSummary() {
    final items = currentOrder?.items ?? [];
    final subtotal = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Subtotal', subtotal),
          _buildSummaryRow('Pickup Fee', 0),
          _buildSummaryRow('Tax', 0),
          const Divider(thickness: 1),
          _buildSummaryRow('Total', currentOrder?.total ?? 0.0, isTotal: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                (currentOrder?.paymentMethod ?? '')
                        .toLowerCase()
                        .contains('card')
                    ? Icons.credit_card
                    : Icons.account_balance_wallet,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                currentOrder?.paymentMethod == 'Cash'
                    ? 'Pay in cash at the counter'
                    : 'Paid with ${currentOrder?.paymentMethod ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            Brand.egp(amount),
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
