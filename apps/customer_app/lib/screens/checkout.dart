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

  List<Map<String, dynamic>> get _lines {
    final lines = <Map<String, dynamic>>[];
    for (final item in widget.cart) {
      final key = item['lineKey'] ?? item['name'];
      final i = lines.indexWhere((l) => (l['lineKey'] ?? l['name']) == key);
      if (i == -1) {
        lines.add(Map<String, dynamic>.from(item));
      } else {
        lines[i]['quantity'] += item['quantity'];
      }
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    double walletBalance = userProvider.user?.walletBalance ?? 0;
    final String userId = userProvider.user!.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
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
                              ? Brand.tomato
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
                              ? Brand.tomato
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
                        color: Brand.basil),
                    const SizedBox(width: 10),
                    const Text('Wallet balance',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      Brand.egp(walletBalance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: walletBalance < widget.total
                            ? Colors.red
                            : Brand.grill,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order summary',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 14),
                  for (final line in _lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text('${line['quantity']}×',
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(line['name'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                if ((line['customizations'] as Map?)
                                        ?.isNotEmpty ??
                                    false)
                                  Text(
                                    (line['customizations'] as Map)
                                        .keys
                                        .join(' · '),
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),
                          Text(Brand.egp(((line['price'] as num?) ?? 0) *
                              ((line['quantity'] as num?) ?? 1))),
                        ],
                      ),
                    ),
                  const Divider(height: 12),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        Brand.egp(widget.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Brand.tomato,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.storefront_outlined,
                    size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pick up at the counter. We\'ll notify you when it\'s ready.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Checkout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Brand.tomato,
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

                        // Lock the button first so a double tap can't pay twice.
                        setState(() => _isProcessingOrder = true);
                        var charged = false;

                        try {
                          if (_isWalletSelected) {
                            charged = await userProvider.updateProfile(
                                walletBalance: walletBalance - widget.total);
                            if (!charged) {
                              throw userProvider.error.isNotEmpty
                                  ? userProvider.error
                                  : 'Failed to process payment';
                            }
                          }

                          // Get vendor ID from widget or extract from cart items
                          String vendorId = widget.vendorId ??
                              (widget.cart.isNotEmpty &&
                                      widget.cart.first['vendorId'] != null
                                  ? widget.cart.first['vendorId']
                                  : 'vendor_123'); // Fallback

                          final orderId = await _orderService.createOrder(
                            Order(
                              id: '',
                              userId: userId,
                              vendorId: vendorId,
                              items: _lines
                                  .map((item) => OrderItem(
                                        id: item['id'] ?? '',
                                        name: item['name'] ?? '',
                                        price: (item['price'] as num?)
                                                ?.toDouble() ??
                                            0.0,
                                        quantity: (item['quantity'] as num?)
                                                ?.toInt() ??
                                            0,
                                        note: item['note'] ?? '',
                                        customizations:
                                            Map<String, dynamic>.from(
                                                item['customizations'] ?? {}),
                                      ))
                                  .toList(),
                              total: widget.total,
                              status: 'pending',
                              paymentMethod:
                                  _isWalletSelected ? 'Wallet' : 'Cash',
                              createdAt: DateTime.now(),
                            ),
                          );

                          if (!context.mounted) return;
                          // The order is placed: empty the cart and go back to
                          // the tabs, with the live status on top.
                          widget.cart.clear();
                          final navigator = Navigator.of(context);
                          navigator.popUntil((route) => route.isFirst);
                          navigator.push(
                            MaterialPageRoute(
                              builder: (context) => OrderStatusScreen(
                                isFromCheckout: true,
                                orderId: orderId,
                                userId: userId,
                              ),
                            ),
                          );
                        } catch (e) {
                          // The order was never written: give the money back.
                          if (charged) {
                            await userProvider.updateProfile(
                                walletBalance: walletBalance);
                          }
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not place order: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isProcessingOrder = false);
                          }
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
                    : Text(
                        'Place order  ·  ${Brand.egp(widget.total)}',
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
