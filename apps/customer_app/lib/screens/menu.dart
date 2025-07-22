import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'cart.dart';

class MenuScreen extends StatefulWidget {
  final String vendorId;
  final List<Map<String, dynamic>> cart;

  const MenuScreen({
    super.key,
    required this.vendorId,
    this.cart = const [],
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Map<String, Map<String, dynamic>> categories = {};
  late List<Map<String, dynamic>> cart;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cart = List<Map<String, dynamic>>.from(widget.cart);
    fetchMenu();
  }

  Future<void> fetchMenu() async {
    try {
      // Fetch the single menu document — you might need to replace 'menuDocId' with actual ID
      // Or if you know the menu doc ID is fixed or only one doc, just get it
      final menuCollection = FirebaseFirestore.instance
          .collection('vendors')
          .doc(widget.vendorId)
          .collection('menu');

      // Get all documents in 'menu' collection
      final menuDocs = await menuCollection.get();

      if (menuDocs.docs.isEmpty) {
        setState(() {
          isLoading = false;
          categories = {};
        });
        return;
      }

      // Assuming only 1 document for menu
      final menuDoc = menuDocs.docs.first;
      final data = menuDoc.data();

      // Filter fields that are Map<String, dynamic> (categories)
      final filteredCategories = <String, Map<String, dynamic>>{};
      data.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          filteredCategories[key] = value;
        }
      });

      setState(() {
        categories = filteredCategories;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching menu: $e');
      setState(() {
        isLoading = false;
        categories = {};
      });
    }
  }

  void _showItemModal(
      String name, dynamic price, String photo, String description) {
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // adapts to content height
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _buildItemImage(photo),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(name,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(description,
                          style:
                              TextStyle(fontSize: 15, color: Colors.grey[650])),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (quantity > 1)
                                    setModalState(() => quantity--);
                                },
                                icon: const Icon(Icons.remove),
                              ),
                              Text('$quantity',
                                  style: const TextStyle(fontSize: 20)),
                              IconButton(
                                onPressed: () {
                                  setModalState(() => quantity++);
                                },
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            onPressed: () {
                              setState(() {
                                cart.add({
                                  'name': name,
                                  'price': price,
                                  'quantity': quantity,
                                  'photo': photo,
                                  'vendorId': widget.vendorId,
                                });
                              });
                              Navigator.pop(context);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Add Item    ',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (Widget child,
                                      Animation<double> animation) {
                                    return ScaleTransition(
                                        scale: animation, child: child);
                                  },
                                  child: Text(
                                    'EGP ${quantity * price}',
                                    key: ValueKey(quantity * price),
                                    style: const TextStyle(
                                        fontSize: 18, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
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

  Future<String> _getImageUrl(String imagePath) async {
    try {
      final downloadUrl =
          await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error loading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Menu')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Menu')),
        body: const Center(child: Text('No menu available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, {
              'vendorId': widget.vendorId,
              'cart': cart,
            });
          },
        ),
        title: const Text('Menu'),
      ),
      body: Stack(
        children: [
          ListView(
            children: categories.entries.map((entry) {
              final categoryName = entry.key;
              final itemsMap = entry.value;

              final itemWidgets = <Widget>[];

              itemWidgets.add(
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 16.0),
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
              );

              final itemEntries = itemsMap.entries.toList();

              for (int i = 0; i < itemEntries.length; i++) {
                final item = itemEntries[i].value;
                if (item is Map<String, dynamic>) {
                  final name = item['Name'] ?? 'Unnamed item';
                  final description = item['Description'] ?? '';
                  final price = item['Price'] ?? 0;
                  final imagePath = item['ImagePath'] ?? '';
                  final isAvailable = item['IsAvailable'] ?? true;

                  // Only show available items to customers
                  if (!isAvailable) continue;

                  itemWidgets.add(
                    GestureDetector(
                      onTap: () {
                        _showItemModal(name, price, imagePath, description);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildItemImage(imagePath),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(description,
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Text('EGP ${price.toString()}',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  if (i < itemEntries.length - 1) {
                    itemWidgets.add(
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Divider(thickness: 1, height: 32),
                      ),
                    );
                  }
                }
              }

              itemWidgets.add(const SizedBox(height: 50));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: itemWidgets,
              );
            }).toList(),
          ),
          if (cart.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(cart: cart),
                    ),
                  );
                  setState(() {});
                },
                child: const Text(
                  "View Cart",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
