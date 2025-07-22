import 'package:flutter/material.dart';

class OrderStatusScreen extends StatelessWidget {
  final String orderId;
  final String userId;

  const OrderStatusScreen({
    super.key,
    required this.orderId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Status'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt, size: 64),
            const SizedBox(height: 16),
            Text('Order ID: $orderId'),
            const SizedBox(height: 8),
            const Text('Order tracking functionality coming soon!'),
          ],
        ),
      ),
    );
  }
}
