import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchItemScreen extends StatefulWidget {
  const SearchItemScreen({super.key});

  @override
  State<SearchItemScreen> createState() => _SearchItemScreenState();
}

class _SearchItemScreenState extends State<SearchItemScreen> {
  final String vendorId = 'ce5b32ee-c038-4f89-ac75-3c1cdb3db566';

  final TextEditingController _searchController = TextEditingController();

  // Flattened list of all items (name + description)
  List<Map<String, String>> _allItems = [];
  List<Map<String, String>> _resultList = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    getItems();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    searchResultList();
  }

  Future<void> getItems() async {
    var data = await FirebaseFirestore.instance
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .get();

    // Reset and flatten all items across all categories
    List<Map<String, String>> tempList = [];

    for (var doc in data.docs) {
      final data = doc.data();
      final categories = data['categories'] as Map<String, dynamic>? ?? {};

      categories.forEach((categoryName, itemsMap) {
        final items = itemsMap as Map<String, dynamic>;

        items.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final name = value['Name'] ?? '';
            final description = value['Description'] ?? '';
            if (name.isNotEmpty) {
              tempList.add({
                'name': name,
                'description': description,
              });
            }
          }
        });
      });
    }

    setState(() {
      _allItems = tempList;
      _resultList = List.from(_allItems);
    });
  }

  void searchResultList() {
    List<Map<String, String>> showResults = [];

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      showResults = _allItems.where((item) {
        final name = item['name']?.toLowerCase() ?? '';
        final desc = item['description']?.toLowerCase() ?? '';
        return name.contains(query) || desc.contains(query);
      }).toList();
    } else {
      showResults = List.from(_allItems);
    }

    setState(() {
      _resultList = showResults;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Menu Items')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search items',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _resultList.length,
              itemBuilder: (context, index) {
                final item = _resultList[index];
                return ListTile(
                  title: Text(item['name'] ?? 'Unnamed'),
                  subtitle: Text(item['description'] ?? ''),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}




// class   SearchItemScreen extends StatefulWidget {
//   const SearchItemScreen({super.key});
//
//   @override
//   State<SearchItemScreen> createState() => _SearchItemScreenState();
// }
//
// class _SearchItemScreenState extends State<SearchItemScreen> {
//   final String vendorId = 'ce5b32ee-c038-4f89-ac75-3c1cdb3db566';
//
//   @override
//   void initState() {
//     _searchController.addListener(_onSearchChanged);
//     super.initState();
//   }
//
//   _onSearchChanged() {
//     searchResultList();
//   }
//
//   searchResultList() {
//     var showResults = [];
//     if (_searchController.text != "") {
//       for (var clientSnapShot in _allResults) {
//         var name = clientSnapShot['name'].toString().toLowerCase();
//         if (name.contains(_searchController.text.toLowerCase())) {
//           showResults.add(clientSnapShot);
//         }
//       }
//     }
//     else {
//       showResults = List.from(_allResults);
//     }
//
//     setState(() {
//       _resultList = showResults;
//     });
//   }
//
//   final TextEditingController _searchController = TextEditingController();
//   List _allResults = [];
//   List _resultList = [];
//
//   getItem() async {
//     var data = await FirebaseFirestore.instance
//         .collection('vendors')
//         .doc(vendorId)
//         .collection('menu')
//         .get();
//
//     setState(() {
//       _allResults = data.docs;
//     });
//
//     searchResultList();
//   }
//
//   void dispose() {
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   void didChangeDependencies() {
//     getItem();
//     super.didChangeDependencies();
//   }
//
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         // Remove default title spacing to make room for custom layout
//         automaticallyImplyLeading: false,
//         title: Row(
//           children: [
//             // Circular arrow button
//             Container(
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.grey[200], // Light gray background
//               ),
//               child: IconButton(
//                 icon: Icon(Icons.arrow_back, color: Colors.black),
//                 onPressed: () {
//                   Navigator.pop(context); // Or any custom action
//                 },
//               ),
//             ),
//             SizedBox(width: 10),
//             // Search bar
//             Expanded(
//               child: CupertinoSearchTextField(
//                 controller: _searchController,
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//
//       ),
//       body: ListView.builder(
//         itemCount: _resultList.length,
//         itemBuilder: (context, index) {
//           return ListTile(
//             leading: Icon(Icons.search),
//             title: Text(_resultList[index]['categories']['Appetizers'],),
//             subtitle: Text(_resultList[index]['description'],),
//           );
//         },
//       ),
//     );
//   }
// }