import 'package:flutter/material.dart';
import 'checkout.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;

  const CartScreen({super.key, required this.cart});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> get mergedCart {
    final List<Map<String, dynamic>> merged = [];

    for (var item in widget.cart) {
      final index = merged.indexWhere((e) => e['name'] == item['name']);
      if (index != -1) {
        merged[index]['quantity'] += item['quantity'];
      } else {
        merged.add(Map<String, dynamic>.from(item));
      }
    }

    return merged;
  }

  double get totalPrice {
    double total = 0.0;
    for (var item in mergedCart) {
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      final quantity = item['quantity'] ?? 1;
      total += price * quantity;
    }
    return total;
  }

  Future<String> _getImageUrl(String imagePath) async {
    try {
      final downloadUrl =
          await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error loading image: $e');
    }
  }

  Widget _buildItemImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.restaurant,
          size: 40,
          color: Colors.grey,
        ),
      );
    }

    return FutureBuilder<String>(
      future: _getImageUrl(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.broken_image,
              size: 40,
              color: Colors.grey,
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: snapshot.data!,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 80,
              height: 80,
              color: Colors.grey[300],
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.broken_image,
                size: 40,
                color: Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: mergedCart.length,
              itemBuilder: (context, index) {
                final item = mergedCart[index];

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Square image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: _buildItemImage(item['photo']),
                        ),
                      ),
                      const SizedBox(width: 16), // Space between image and text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 24), // 3-line spacing
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'EGP ${(double.tryParse(item['price'].toString()) ?? 0.0) * (item['quantity'] ?? 1)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                        icon: const Icon(Icons.remove_circle),
                                        onPressed: () {
                                          setState(() {
                                            for (int i = widget.cart.length - 1;
                                                i >= 0;
                                                i--) {
                                              if (widget.cart[i]['name'] ==
                                                  item['name']) {
                                                widget.cart[i]['quantity']--;
                                                if (widget.cart[i]
                                                        ['quantity'] <=
                                                    0) {
                                                  widget.cart.removeAt(i);
                                                }
                                                break;
                                              }
                                            }

                                            if (widget.cart.isEmpty) {
                                              Navigator.pop(context, []);
                                            }
                                          });
                                        }),
                                    Text(
                                      '${item['quantity']}',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    IconButton(
                                        icon: const Icon(Icons.add_circle),
                                        onPressed: () {
                                          setState(() {
                                            for (var originalItem
                                                in widget.cart) {
                                              if (originalItem['name'] ==
                                                  item['name']) {
                                                originalItem['quantity']++;
                                                break;
                                              }
                                            }
                                          });
                                        }),
                                  ],
                                ),
                              ],
                            ),
                            Divider(thickness: 2),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(thickness: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'EGP ${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {
                      // Get vendor ID from the first cart item (all items should be from same vendor)
                      final String? vendorId = widget.cart.isNotEmpty
                          ? widget.cart.first['vendorId']
                          : null;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(
                            cart: widget.cart,
                            total: totalPrice,
                            vendorId: vendorId,
                          ),
                        ),
                      );
                    },
                    child: const Text('Checkout'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to menu
                    },
                    child: const Text('Add More Items'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
