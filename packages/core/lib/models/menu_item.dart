class MenuCategory {
  final String id;
  final String name;
  final int cid;
  final List<MenuItem> items;

  MenuCategory({
    required this.id,
    required this.name,
    required this.cid,
    required this.items,
  });

  factory MenuCategory.fromMap(
      String categoryId, Map<String, dynamic> categoryData) {
    final List<MenuItem> items = [];

    // Helper function to safely convert to int
    int parseCid(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    // Extract items from the category data
    categoryData.forEach((key, value) {
      if (key != 'Name' && key != 'CID' && value is Map<String, dynamic>) {
        // This is an item
        final itemData = Map<String, dynamic>.from(value);
        // Use the category's Name field if available, otherwise use the categoryId
        final categoryDisplayName = categoryData['Name'] ?? categoryId;
        items.add(MenuItem.fromNestedMap(key, itemData, categoryDisplayName));
      }
    });

    return MenuCategory(
      id: categoryId,
      name: categoryData['Name'] ?? categoryId,
      cid: parseCid(categoryData['CID']),
      items: items,
    );
  }
}

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imagePath;
  final int popularity;
  final String category;
  final bool isAvailable;
  final Map<String, dynamic> customizationOptions;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imagePath = '',
    required this.popularity,
    this.category = '',
    this.isAvailable = true,
    this.customizationOptions = const {},
  });

  factory MenuItem.fromMap(String id, Map<String, dynamic> map) {
    // Helper function to safely convert to double
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    // Helper function to safely convert to int
    int parsePopularity(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return MenuItem(
      id: id,
      name: map['Name'] ?? map['name'] ?? '',
      description: map['Description'] ?? map['description'] ?? '',
      price: parsePrice(map['Price'] ?? map['price']),
      imagePath: map['ImagePath'] ?? map['imagePath'] ?? map['imageUrl'] ?? '',
      popularity: parsePopularity(map['Popularity'] ?? map['popularity']),
      category: map['Category'] ?? map['category'] ?? '',
      isAvailable: map['IsAvailable'] ?? map['isAvailable'] ?? true,
      customizationOptions: Map<String, dynamic>.from(
          map['CustomizationOptions'] ?? map['customizationOptions'] ?? {}),
    );
  }

  // Factory for creating MenuItem from nested categories structure
  factory MenuItem.fromNestedMap(
      String itemId, Map<String, dynamic> itemData, String categoryName) {
    // Helper function to safely convert to double
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    // Helper function to safely convert to int
    int parsePopularity(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    // Check for popularity with different casing and handle missing values
    dynamic popularityValue;
    if (itemData.containsKey('Popularity')) {
      popularityValue = itemData['Popularity'];
    } else if (itemData.containsKey('popularity')) {
      popularityValue = itemData['popularity'];
    } else {
      popularityValue = 0;
    }

    print(
        'Final popularity value for $itemId: $popularityValue (${popularityValue.runtimeType})');

    return MenuItem(
      id: itemId,
      name: itemData['Name'] ?? itemData['name'] ?? '',
      description: itemData['Description'] ?? itemData['description'] ?? '',
      price: parsePrice(itemData['Price'] ?? itemData['price']),
      imagePath: itemData['ImagePath'] ?? itemData['imagePath'] ?? '',
      popularity: parsePopularity(popularityValue),
      category: categoryName,
      isAvailable: itemData['IsAvailable'] ?? itemData['isAvailable'] ?? true,
      customizationOptions: Map<String, dynamic>.from(
          itemData['CustomizationOptions'] ??
              itemData['customizationOptions'] ??
              {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Name': name,
      'Description': description,
      'Price': price,
      'ImagePath': imagePath,
      'Popularity': popularity,
      'Category': category,
      'IsAvailable': isAvailable,
      'CustomizationOptions': customizationOptions,
    };
  }

  MenuItem copyWith({
    String? name,
    String? description,
    double? price,
    String? imagePath,
    int? popularity,
    String? category,
    bool? isAvailable,
    Map<String, dynamic>? customizationOptions,
  }) {
    return MenuItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      popularity: popularity ?? this.popularity,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      customizationOptions: customizationOptions ?? this.customizationOptions,
    );
  }

  // Static method to extract all menu items from nested categories structure
  static List<MenuItem> extractFromCategories(
      Map<String, dynamic> categoriesData) {
    final List<MenuItem> allItems = [];

    print('Extracting from categories: ${categoriesData.keys.toList()}');

    categoriesData.forEach((categoryId, categoryData) {
      print('Processing category: $categoryId');
      if (categoryData is Map<String, dynamic>) {
        print('Category data keys: ${categoryData.keys.toList()}');
        try {
          final category = MenuCategory.fromMap(categoryId, categoryData);
          print(
              'Successfully created category with ${category.items.length} items');
          allItems.addAll(category.items);
        } catch (e) {
          print('Error creating category $categoryId: $e');
        }
      } else {
        print('Category data is not a Map: ${categoryData.runtimeType}');
      }
    });

    print('Total items extracted: ${allItems.length}');
    return allItems;
  }
}
