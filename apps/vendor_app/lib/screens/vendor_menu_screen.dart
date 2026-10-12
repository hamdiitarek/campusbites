import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path/path.dart' as path;
import 'package:core/core.dart';

class VendorMenuScreen extends StatefulWidget {
  const VendorMenuScreen({super.key});
  @override
  State<VendorMenuScreen> createState() => _VendorMenuScreenState();
}

class _VendorMenuScreenState extends State<VendorMenuScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Widget> _imageWidgets = {};
  List<MenuCategory> _categories = [];
  List<MenuCategory> _filteredCategories = [];
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMenu();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _applySearchFilter();
      });
    });
  }

  Future<void> _fetchMenu() async {
    setState(() => _loading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(currentUser!.uid)
          .collection('menu')
          .get();

      final List<MenuCategory> loaded = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            loaded.add(MenuCategory.fromMap(key, value));
          }
        });
      }

      setState(() {
        _categories = loaded;
        _applySearchFilter();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredCategories = _categories;
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredCategories = _categories
          .map((category) {
            final filteredItems = category.items
                .where((item) =>
                    item.name.toLowerCase().contains(query) ||
                    item.description.toLowerCase().contains(query))
                .toList();
            return MenuCategory(
              id: category.id,
              name: category.name,
              cid: category.cid,
              items: filteredItems,
            );
          })
          .where((c) => c.items.isNotEmpty)
          .toList();
    }
  }

  Future<String> _getImageUrl(String imagePath) =>
      StorageImage.resolve(imagePath);

  Widget _getCachedImage(String imagePath) {
    if (_imageWidgets.containsKey(imagePath)) return _imageWidgets[imagePath]!;
    final widget = FutureBuilder<String>(
      future: _getImageUrl(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data!.isNotEmpty) {
          return CachedNetworkImage(
            imageUrl: snapshot.data!,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          );
        }
        return const Icon(Icons.image, size: 50, color: Colors.grey);
      },
    );
    _imageWidgets[imagePath] = widget;
    return widget;
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Category"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter category name"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Category name cannot be empty")));
                return;
              }

              final isDuplicate = _categories
                  .any((c) => c.name.toLowerCase() == name.toLowerCase());
              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Category already exists")));
                return;
              }

              final menuDoc = await FirebaseFirestore.instance
                  .collection('vendors')
                  .doc(currentUser!.uid)
                  .collection('menu')
                  .limit(1)
                  .get();

              if (menuDoc.docs.isNotEmpty) {
                final docRef = menuDoc.docs.first.reference;
                await docRef.set({
                  name: {
                    "Name": name,
                    "CID": _categories.length + 1,
                  }
                }, SetOptions(merge: true));
                Navigator.pop(context);
                _fetchMenu();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Category \"$name\" created")));
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _renameCategory(String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Category"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty ||
                  newName.toLowerCase() == oldName.toLowerCase()) return;

              final isDuplicate = _categories
                  .any((c) => c.name.toLowerCase() == newName.toLowerCase());
              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Category name already exists")));
                return;
              }

              final menuDoc = await FirebaseFirestore.instance
                  .collection('vendors')
                  .doc(currentUser!.uid)
                  .collection('menu')
                  .limit(1)
                  .get();
              if (menuDoc.docs.isEmpty) return;

              final docRef = menuDoc.docs.first.reference;
              final data = menuDoc.docs.first.data();

              final oldData = data[oldName];
              if (oldData == null) return;

              final newData = Map<String, dynamic>.from(oldData);
              newData["Name"] = newName;

              await docRef.set({newName: newData}, SetOptions(merge: true));
              await docRef.update({oldName: FieldValue.delete()});
              Navigator.pop(context);
              _fetchMenu();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Renamed \"$oldName\" to \"$newName\"")));
            },
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category"),
        content: Text(
            "Are you sure you want to delete \"$name\" and all its items?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final menuDoc = await FirebaseFirestore.instance
                  .collection('vendors')
                  .doc(currentUser!.uid)
                  .collection('menu')
                  .limit(1)
                  .get();

              if (menuDoc.docs.isEmpty) return;

              final docRef = menuDoc.docs.first.reference;
              await docRef.update({name: FieldValue.delete()});
              Navigator.pop(context);
              _fetchMenu();
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Category \"$name\" deleted")));
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showItemActions(MenuItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Brand.tomato),
              title: const Text("Edit Item"),
              onTap: () {
                Navigator.pop(context);
                _showItemFormDialog(existingItem: item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete Item"),
              onTap: () async {
                Navigator.pop(context);
                final menuDoc = await FirebaseFirestore.instance
                    .collection('vendors')
                    .doc(currentUser!.uid)
                    .collection('menu')
                    .limit(1)
                    .get();
                if (menuDoc.docs.isNotEmpty) {
                  final docRef = menuDoc.docs.first.reference;
                  await docRef.update(
                      {"${item.category}.${item.id}": FieldValue.delete()});
                  _fetchMenu();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showItemFormDialog({MenuItem? existingItem}) {
    final _formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existingItem?.name ?? '');
    final descCtrl =
        TextEditingController(text: existingItem?.description ?? '');
    final priceCtrl =
        TextEditingController(text: existingItem?.price.toString() ?? '');
    String imagePath = existingItem?.imagePath ?? '';
    String category = existingItem?.category ??
        (_categories.isNotEmpty ? _categories.first.name : '');
    bool isAvailable = existingItem?.isAvailable ?? true;

    List<Map<String, TextEditingController>> customizationControllers = [];

    if (existingItem?.customizationOptions != null) {
      existingItem!.customizationOptions.forEach((name, price) {
        customizationControllers.add({
          'name': TextEditingController(text: name),
          'price': TextEditingController(text: price.toString()),
        });
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(existingItem == null ? "Add Item" : "Edit Item",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) => v!.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      validator: (v) => v!.isEmpty ? 'Enter description' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Enter price' : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: _categories
                          .map((c) => DropdownMenuItem(
                              value: c.name, child: Text(c.name)))
                          .toList(),
                      onChanged: (val) => setModalState(() => category = val!),
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload),
                        label: const Text("Upload Image"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Brand.tomato),
                        onPressed: () async {
                          final picked = await ImagePicker()
                              .pickImage(source: ImageSource.gallery);
                          if (picked != null) {
                            final file = File(picked.path);
                            final filename = path.basename(picked.path);
                            final ref = FirebaseStorage.instance
                                .ref("Default Vendor/menu_images/$filename");
                            await ref.putFile(file);
                            final uploadedPath = ref.fullPath;
                            setModalState(() {
                              imagePath = uploadedPath;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Customization Options",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Brand.tomato),
                          onPressed: () {
                            setModalState(() {
                              customizationControllers.add({
                                'name': TextEditingController(),
                                'price': TextEditingController(),
                              });
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(customizationControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: customizationControllers[index]
                                    ['name'],
                                decoration: const InputDecoration(
                                    labelText: 'Option Name'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: customizationControllers[index]
                                    ['price'],
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(labelText: 'Price'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red),
                              onPressed: () {
                                setModalState(() {
                                  customizationControllers.removeAt(index);
                                });
                              },
                            )
                          ],
                        ),
                      );
                    }),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Available"),
                        Switch(
                          value: isAvailable,
                          onChanged: (val) =>
                              setModalState(() => isAvailable = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Brand.tomato),
                        child: const Text("Save",
                            style: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          final menuDoc = await FirebaseFirestore.instance
                              .collection('vendors')
                              .doc(user.uid)
                              .collection('menu')
                              .limit(1)
                              .get();
                          if (menuDoc.docs.isEmpty) return;

                          final docRef = menuDoc.docs.first.reference;
                          final id = existingItem?.id ??
                              "item${DateTime.now().millisecondsSinceEpoch}";

                          final customizationMap = <String, int>{};
                          for (var pair in customizationControllers) {
                            final name = pair['name']!.text.trim();
                            final priceText = pair['price']!.text.trim();
                            if (name.isNotEmpty &&
                                int.tryParse(priceText) != null) {
                              customizationMap[name] = int.parse(priceText);
                            }
                          }

                          final itemData = {
                            "Name": nameCtrl.text.trim(),
                            "Description": descCtrl.text.trim(),
                            "Price":
                                double.tryParse(priceCtrl.text.trim()) ?? 0,
                            "ImagePath": imagePath,
                            "Popularity": existingItem?.popularity ?? 0,
                            "Category": category,
                            "IsAvailable": isAvailable,
                            "CustomizationOptions": customizationMap,
                          };

                          // Get the current category CID to preserve it
                          final currentDoc = await docRef.get();
                          final currentData = currentDoc.data();
                          final currentCategory =
                              currentData?[category] as Map<String, dynamic>?;
                          final currentCID = currentCategory?['CID'] ?? 1;

                          await docRef.update({
                            "$category.CID": currentCID,
                            "$category.Name": category,
                            "$category.$id": itemData,
                          });

                          Navigator.pop(context);
                          _fetchMenu();
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text(
          'My Menu',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Brand.tomato),
            onPressed: _fetchMenu,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search item...',
                  prefixIcon: Icon(Icons.search, color: Brand.tomato),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),



      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Categories",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: Brand.tomato),
                        onPressed: _showAddCategoryDialog,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = _filteredCategories[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(category.name,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'rename')
                                      _renameCategory(category.name);
                                    if (value == 'delete')
                                      _deleteCategory(category.name);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                        value: 'rename', child: Text('Rename')),
                                    const PopupMenuItem(
                                        value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ...category.items.map((item) {
                            return GestureDetector(
                              onTap: () => _showItemActions(item),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: _getCachedImage(item.imagePath),
                                  ),
                                ),
                                title: Text(item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!item.isAvailable)
                                      const Text("Unavailable",
                                          style: TextStyle(
                                              color: Colors.red, fontSize: 12)),
                                    Text(item.description),
                                  ],
                                ),
                                trailing: Text(
                                  Brand.egp(item.price),
                                  style: const TextStyle(
                                      color: Brand.basil,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Brand.tomato,
        child: const Icon(Icons.add),
        onPressed: () => _showItemFormDialog(),
      ),
    );
  }
}
