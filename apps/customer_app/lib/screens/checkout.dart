import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'order_status.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final double total;
  final String? vendorId;

  const CheckoutScreen({
    super.key,
    required this.cart,
    required this.total,
    this.vendorId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isWalletSelected = true;
  bool _isProcessingOrder = false;
  final OrderService _orderService = OrderService();
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    double walletBalance = userProvider.user?.walletBalance ?? 0;
    final String userId = userProvider.user!.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Method Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isWalletSelected = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isWalletSelected
                              ? Colors.blue
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: _isWalletSelected
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Wallet',
                              style: TextStyle(
                                color: _isWalletSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isWalletSelected = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isWalletSelected
                              ? Colors.blue
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.money,
                              color: !_isWalletSelected
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cash',
                              style: TextStyle(
                                color: !_isWalletSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Wallet Balance
            if (_isWalletSelected)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Wallet Balance: \EGP ${walletBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isWalletSelected && walletBalance < widget.total
                            ? Colors.red
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Total Price
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Price:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '\EGP ${widget.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Checkout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isProcessingOrder
                    ? null
                    : () async {
                        if (_isWalletSelected && walletBalance < widget.total) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Insufficient wallet balance'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (_isWalletSelected) {
                          double newBalance = walletBalance - widget.total;
                          bool success = await userProvider.updateProfile(
                              walletBalance: newBalance);
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(userProvider.error.isNotEmpty
                                    ? userProvider.error
                                    : 'Failed to process payment'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        }

                        setState(() {
                          _isProcessingOrder = true;
                        });

                        try {
                          // Get vendor ID from widget or extract from cart items
                          String vendorId = widget.vendorId ??
                              (widget.cart.isNotEmpty &&
                                      widget.cart.first['vendorId'] != null
                                  ? widget.cart.first['vendorId']
                                  : 'vendor_123'); // Fallback

                          // Create the order first
                          final orderId = await _orderService.createOrder(
                            Order(
                              id: '',
                              userId: userId,
                              vendorId: vendorId,
                              items: widget.cart
                                  .map((item) => OrderItem(
                                        id: item['id'] ?? '',
                                        name: item['name'] ?? '',
                                        price: item['price']?.toDouble() ?? 0.0,
                                        quantity:
                                            item['quantity']?.toInt() ?? 0,
                                        note: item['note'] ?? '',
                                        customizations:
                                            item['customizations'] ?? {},
                                      ))
                                  .toList(),
                              total: widget.total,
                              status: 'pending',
                              paymentMethod:
                                  _isWalletSelected ? 'Wallet' : 'Cash',
                              createdAt: DateTime.now(),
                            ),
                          );

                          // Navigate to order status screen with the order ID
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderStatusScreen(
                                isFromCheckout: true,
                                orderId: orderId,
                                userId: userId,
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to create order: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          setState(() {
                            _isProcessingOrder = false;
                          });
                        }
                      },
                child: _isProcessingOrder
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Checkout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
