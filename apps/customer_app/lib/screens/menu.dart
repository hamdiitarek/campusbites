import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  Vendor? vendor;

  @override
  void initState() {
    super.initState();
    cart = List<Map<String, dynamic>>.from(widget.cart);
    fetchMenu();
    VendorService().getVendorById(widget.vendorId).then((v) {
      if (mounted) setState(() => vendor = v);
    });
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

      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        isLoading = false;
        categories = {};
      });
    }
  }

  void _showItemModal(String itemId, Map<String, dynamic> item) {
    final String name = item['Name'] ?? 'Unnamed item';
    final num price = (item['Price'] as num?) ?? 0;
    final String photo = item['ImagePath'] ?? '';
    final String description = item['Description'] ?? '';
    final options =
        Map<String, dynamic>.from(item['CustomizationOptions'] ?? {});
    final selected = <String, num>{};
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          final unit = price + selected.values.fold<num>(0, (a, b) => a + b);
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child:
                              StorageImage(photo, fallbackIcon: Icons.fastfood),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(name,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(Brand.egp(price),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Brand.basil)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(description,
                          style:
                              TextStyle(fontSize: 15, color: Colors.grey[700])),
                      // Vendors set these in the vendor app (CustomizationOptions).
                      if (options.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text('Extras',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: options.entries.map((option) {
                            final extra = (option.value as num?) ?? 0;
                            final isOn = selected.containsKey(option.key);
                            return FilterChip(
                              label: Text(extra > 0
                                  ? '${option.key}  +${Brand.egp(extra).substring(4)}'
                                  : option.key),
                              selected: isOn,
                              onSelected: (on) => setModalState(() => on
                                  ? selected[option.key] = extra
                                  : selected.remove(option.key)),
                              backgroundColor: Colors.white,
                              selectedColor: Brand.tomatoTint,
                              checkmarkColor: Brand.tomatoDeep,
                              labelStyle: TextStyle(
                                color: isOn ? Brand.tomatoDeep : Brand.grill,
                                fontWeight:
                                    isOn ? FontWeight.w600 : FontWeight.w500,
                              ),
                              side: BorderSide(
                                  color: isOn
                                      ? Brand.tomato
                                      : Colors.grey.shade300),
                              shape: const StadiumBorder(),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: quantity > 1
                                      ? () => setModalState(() => quantity--)
                                      : null,
                                  icon: const Icon(Icons.remove),
                                ),
                                Text('$quantity',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                                IconButton(
                                  onPressed: () =>
                                      setModalState(() => quantity++),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final keys = selected.keys.toList()..sort();
                                setState(() {
                                  cart.add({
                                    'id': itemId,
                                    // Same item with different extras is a separate cart line.
                                    'lineKey': '$itemId|${keys.join(',')}',
                                    'name': name,
                                    'price': unit,
                                    'quantity': quantity,
                                    'photo': photo,
                                    'vendorId': widget.vendorId,
                                    'customizations':
                                        Map<String, dynamic>.from(selected),
                                  });
                                });
                                Navigator.pop(context);
                              },
                              child: Text(
                                  'Add  ·  ${Brand.egp(unit * quantity)}',
                                  style: const TextStyle(fontSize: 17)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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

  Future<String> _getImageUrl(String imagePath) =>
      StorageImage.resolve(imagePath);

  int get _cartCount =>
      cart.fold(0, (n, line) => n + ((line['quantity'] as num?) ?? 0).toInt());

  num get _cartTotal => cart.fold<num>(
      0,
      (sum, line) =>
          sum +
          ((line['price'] as num?) ?? 0) * ((line['quantity'] as num?) ?? 0));

  static num _popularity(dynamic item) =>
      item is Map ? (item['Popularity'] as num? ?? 0) : 0;

  // Categories in the order the vendor created them (CID).
  List<MapEntry<String, Map<String, dynamic>>> get sortedCategories =>
      categories.entries.toList()
        ..sort((a, b) => ((a.value['CID'] as num?) ?? 0)
            .compareTo((b.value['CID'] as num?) ?? 0));

  Widget _buildVendorHeader(Vendor vendor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: StorageImage(vendor.imageUrl,
                height: 150, width: double.infinity),
          ),
          const SizedBox(height: 14),
          Text(vendor.description,
              style: TextStyle(fontSize: 15, color: Colors.grey[700])),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 20, color: Brand.saffron),
              const SizedBox(width: 4),
              Text(vendor.rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('  (${vendor.reviewCount} reviews)',
                  style: TextStyle(color: Colors.grey[600])),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: vendor.isOpen
                      ? Brand.basil.withValues(alpha: 0.12)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  vendor.isOpen ? 'Open now' : 'Closed',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: vendor.isOpen ? Brand.basil : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
        title: Text(vendor?.name ?? 'Menu'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              if (vendor != null) _buildVendorHeader(vendor!),
              ...sortedCategories.map((entry) {
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

                // Most-ordered first; skips the category's Name/CID fields.
                final itemEntries = itemsMap.entries
                    .where((e) => e.value is Map<String, dynamic>)
                    .toList()
                  ..sort((a, b) =>
                      _popularity(b.value).compareTo(_popularity(a.value)));

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
                        onTap: () => _showItemModal(itemEntries[i].key, item),
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
                                    Text(Brand.egp(price as num),
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Brand.basil)),
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
              }),
            ],
          ),
          if (cart.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Brand.tomato,
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
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$_cartCount',
                          style: const TextStyle(fontSize: 16)),
                    ),
                    const Expanded(
                      child: Text('View cart',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18)),
                    ),
                    Text(Brand.egp(_cartTotal),
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
