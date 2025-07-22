import 'package:flutter/material.dart';

class SearchItemScreen extends StatelessWidget {
  const SearchItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Items'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64),
            SizedBox(height: 16),
            Text('Item search functionality coming soon!'),
          ],
        ),
      ),
    );
  }
}
