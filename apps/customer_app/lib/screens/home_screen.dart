import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu.dart';
import 'search_vendor.dart';
import 'cart.dart';

class HomeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final String? cartVendorId;

  const HomeScreen({
    Key? key,
    this.cart = const [],
    this.cartVendorId,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _cart = [];
  String? _cartVendorId;
  List<Vendor> _vendors = [];
  bool _isLoading = true;
  final Map<String, List<DocumentSnapshot>> _vendorMenus = {};
  List<Map<String, dynamic>> _popularMeals = [];
  bool _isLoadingPopularMeals = true;

  @override
  void initState() {
    super.initState();
    //_checkEmailVerification();
    _loadVendors();
    _loadPopularMeals();

    // Listen for notification taps
    NotificationService().notificationStream.listen((data) {
      if (mounted &&
          data.containsKey('orderId') &&
          data.containsKey('userId')) {}
    });
  }

  Future<void> _loadVendors() async {
    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userUniversityName = userProvider.user?.universityName;

      if (userUniversityName == null) {
        setState(() {
          _vendors = [];
          _isLoading = false;
        });
        return;
      }

      // Get vendors from the same university as the user
      final vendorsSnapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .where('universityName', isEqualTo: userUniversityName)
          .where('isApproved', isEqualTo: true)
          .get();

      final vendors = vendorsSnapshot.docs.map((doc) {
        return Vendor.fromMap(doc.id, doc.data());
      }).toList();

      setState(() {
        _vendors = vendors;
        _isLoading = false;
      });

      for (var vendor in vendors) {
        _loadVendorMenu(vendor.id);
      }
    } catch (e) {
      setState(() {
        _vendors = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVendorMenu(String vendorId) async {
    try {
      final menuSnapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .collection('menu')
          .get();

      setState(() {
        _vendorMenus[vendorId] = menuSnapshot.docs;
      });
    } catch (e) {}
  }

  // Email verification method removed for testing purposes

  Future<void> _loadPopularMeals() async {
    setState(() => _isLoadingPopularMeals = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userUniversityName = userProvider.user?.universityName;

      if (userUniversityName == null) {
        setState(() {
          _popularMeals = [];
          _isLoadingPopularMeals = false;
        });
        return;
      }

      // Get all vendors from the same university
      final vendorsSnapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .where('universityName', isEqualTo: userUniversityName)
          .where('isApproved', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> allMeals = [];

      // Fetch menu items from each vendor
      for (var vendorDoc in vendorsSnapshot.docs) {
        final menuSnapshot = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendorDoc.id)
            .collection('menu')
            .get();

        for (var menuDoc in menuSnapshot.docs) {
          final menuData = menuDoc.data();

          if (menuData.containsKey('categories')) {
            final categoriesData =
                menuData['categories'] as Map<String, dynamic>;

            final menuItems = MenuItem.extractFromCategories(categoriesData);

            for (var menuItem in menuItems) {
              if (menuItem.isAvailable) {
                allMeals.add({
                  'menuItem': menuItem,
                  'vendorId': vendorDoc.id,
                  'vendorName': vendorDoc.data()['name'] ?? '',
                });
              }
            }
          } else {
            // Filter out metadata fields to get only category data
            final categoryData = Map<String, dynamic>.from(menuData);
            categoryData.removeWhere((key, value) =>
                key == 'createdAt' ||
                key == '_placeholder' ||
                key.startsWith('_') ||
                value is! Map<String, dynamic>);

            if (categoryData.isNotEmpty) {
              final menuItems = MenuItem.extractFromCategories(categoryData);

              for (var menuItem in menuItems) {
                if (menuItem.isAvailable) {
                  allMeals.add({
                    'menuItem': menuItem,
                    'vendorId': vendorDoc.id,
                    'vendorName': vendorDoc.data()['name'] ?? '',
                  });
                }
              }
            } else {}
          }
        }
      }

      // Sort by popularity
      allMeals.sort((a, b) => (b['menuItem'] as MenuItem)
          .popularity
          .compareTo((a['menuItem'] as MenuItem).popularity));

      for (int i = 0; i < allMeals.length && i < 6; i++) {
        final meal = allMeals[i]['menuItem'] as MenuItem;
      }

      final topMeals = allMeals.take(6).toList();

      setState(() {
        _popularMeals = topMeals;
        _isLoadingPopularMeals = false;
      });
    } catch (e) {
      setState(() {
        _popularMeals = [];
        _isLoadingPopularMeals = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final fullName = userProvider.user?.fullName ?? '';

    final Set<String> uniqueCategories = {'All'};
    for (var vendor in _vendors) {
      uniqueCategories.addAll(vendor.categories);
    }
    final categories = uniqueCategories.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Padding(
          padding: const EdgeInsets.all(15),
          child: Text(
            'Hi, ${fullName.split(' ').first} 👋',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.blue),
            onPressed: () {
              if (_cart.isNotEmpty) {
                Navigator.of(context, rootNavigator: true).push(
                  CupertinoPageRoute(
                    builder: (_) => CartScreen(cart: _cart),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadVendors();
          await _loadPopularMeals();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                GestureDetector(
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      CupertinoPageRoute(
                        builder: (_) => const SearchScreen(),
                      ),
                    );
                  },
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 4),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: Icon(Icons.search,
                                  color: Colors.grey.shade500),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 4),
                                child: Text(
                                  'Search for meals or vendors...',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),
                Container(
                  height: 60,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        categories.length,
                        (index) => Row(
                          children: [
                            _buildToggleButton(categories[index], index),
                            if (index != categories.length - 1)
                              SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),
                Text(
                  'Popular Vendors',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
                SizedBox(height: 16),
                if (_isLoading)
                  Center(child: CircularProgressIndicator())
                else if (_vendors.isEmpty)
                  Center(
                    child: Text(
                      'No vendors available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Container(
                    height: 160,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _vendors.where((vendor) {
                          if (categories[_selectedIndex] == 'All') {
                            return true;
                          }
                          return vendor.categories
                              .contains(categories[_selectedIndex]);
                        }).map((vendor) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () async {
                                if (_cart.isNotEmpty &&
                                    _cartVendorId != vendor.id) {
                                  bool clearCart = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text(
                                          "Different Vendor Detected"),
                                      content: const Text(
                                          "You already have items in the cart from another vendor. Do you want to clear the cart?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("No"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Yes"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (!clearCart) return;

                                  setState(() {
                                    _cart.clear();
                                    _cartVendorId = null;
                                  });
                                }

                                final result = await Navigator.of(context,
                                        rootNavigator: true)
                                    .push(
                                  CupertinoPageRoute(
                                    builder: (_) => MenuScreen(
                                      vendorId: vendor.id,
                                      cart: _cart,
                                    ),
                                  ),
                                );

                                if (result != null && result['cart'] != null) {
                                  setState(() {
                                    _cart = List<Map<String, dynamic>>.from(
                                        result['cart']);
                                    _cartVendorId = result['vendorId'];
                                  });
                                }
                              },
                              child: Container(
                                width: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(15)),
                                      child: vendor.imageUrl.isNotEmpty
                                          ? Image.network(
                                              vendor.imageUrl,
                                              height: 100,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              height: 100,
                                              color: Colors.grey[300],
                                              child: Icon(Icons.restaurant,
                                                  color: Colors.grey[600]),
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            vendor.name,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.star,
                                                  size: 16,
                                                  color: Colors.amber),
                                              SizedBox(width: 4),
                                              Text(
                                                  '${vendor.rating.toStringAsFixed(1)} (${vendor.reviewCount})'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                Text(
                  'Popular Meals',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
                SizedBox(height: 16),
                // Popular meals from Firestore
                Container(
                  height: 180,
                  child: _isLoadingPopularMeals
                      ? Center(child: CircularProgressIndicator())
                      : _popularMeals.isEmpty
                          ? Center(
                              child: Text(
                                'No popular meals found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _popularMeals.map((mealData) {
                                  final MenuItem meal = mealData['menuItem'];
                                  final String _vendorId = mealData['vendorId'];

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () async {
                                        if (_cart.isNotEmpty &&
                                            _cartVendorId != _vendorId) {
                                          bool clearCart = await showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                  "Different Vendor Detected"),
                                              content: const Text(
                                                  "You already have items in the cart from another vendor. Do you want to clear the cart?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text("No"),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text("Yes"),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (!clearCart) return;

                                          setState(() {
                                            _cart.clear();
                                            _cartVendorId = null;
                                          });
                                        }

                                        final result = await Navigator.of(
                                                context,
                                                rootNavigator: true)
                                            .push(
                                          CupertinoPageRoute(
                                            builder: (_) => MenuScreen(
                                              vendorId: _vendorId,
                                              cart: _cart,
                                            ),
                                          ),
                                        );

                                        if (result != null &&
                                            result['cart'] != null) {
                                          setState(() {
                                            _cart =
                                                List<Map<String, dynamic>>.from(
                                                    result['cart']);
                                            _cartVendorId = result['vendorId'];
                                          });
                                        }
                                      },
                                      child: Container(
                                        width: 200,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.2),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(15)),
                                              child: meal.imagePath.isNotEmpty
                                                  ? Image.network(
                                                      meal.imagePath,
                                                      height: 100,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Container(
                                                          height: 80,
                                                          color:
                                                              Colors.grey[300],
                                                          child: Icon(
                                                              Icons.fastfood,
                                                              color: Colors
                                                                  .grey[600]),
                                                        );
                                                      },
                                                    )
                                                  : Container(
                                                      height: 80,
                                                      color: Colors.grey[300],
                                                      child: Icon(
                                                          Icons.fastfood,
                                                          color:
                                                              Colors.grey[600]),
                                                    ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    meal.name,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    mealData['vendorName'],
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.trending_up,
                                                          size: 16,
                                                          color: Colors.orange),
                                                      SizedBox(width: 4),
                                                      Text(
                                                          '${meal.popularity} orders'),
                                                    ],
                                                  ),
                                                  Text(
                                                    'EGP ${meal.price.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.green),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _selectedIndex = 0;

  Widget _buildToggleButton(String text, int index) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        backgroundColor: _selectedIndex == index ? Colors.blue : Colors.white,
        foregroundColor: _selectedIndex == index ? Colors.white : Colors.black,
      ),
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Text(text),
    );
  }
}
