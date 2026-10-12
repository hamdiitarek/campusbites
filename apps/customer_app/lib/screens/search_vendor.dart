import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  void initState() {
    _searchController.addListener(_onSearchChanged);
    super.initState();
  }

  _onSearchChanged() {
    searchResultList();
  }

  searchResultList() {
    var showResults = [];
    if (_searchController.text != "") {
      for (var clientSnapShot in _allResults) {
        var name = clientSnapShot['name'].toString().toLowerCase();
        if (name.contains(_searchController.text.toLowerCase())) {
          showResults.add(clientSnapShot);
        }
      }
    } else {
      showResults = List.from(_allResults);
    }

    // Limit results to 5 vendors
    if (showResults.length > 5) {
      showResults = showResults.sublist(0, 5);
    }

    setState(() {
      _resultList = showResults;
    });
  }

  final TextEditingController _searchController = TextEditingController();
  List _allResults = [];
  List _resultList = [];

  getVendor() async {
    var data = await FirebaseFirestore.instance
        .collection('vendors')
        .orderBy('name')
        .get();

    setState(() {
      _allResults = data.docs;
    });

    searchResultList();
  }

  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void didChangeDependencies() {
    getVendor();
    super.didChangeDependencies();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Remove default title spacing to make room for custom layout
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Circular arrow button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200], // Light gray background
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context); // Or any custom action
                },
              ),
            ),
            SizedBox(width: 10),
            // Search bar
            Expanded(
              child: CupertinoSearchTextField(
                controller: _searchController,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: _resultList.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.search),
            title: Text(
              _resultList[index]['name'],
            ),
            subtitle: Text(
              _resultList[index]['description'],
            ),
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                CupertinoPageRoute(
                  builder: (_) => MenuScreen(vendorId: _resultList[index].id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
