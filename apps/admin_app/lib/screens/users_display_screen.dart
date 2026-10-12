import 'package:core/theme/brand.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:core/core.dart' as core;

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterRole = 'all'; // 'all', 'user', 'vendor'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Brand.tomatoTint,
        elevation: 2,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.filter_alt_outlined,
                color: Brand.tomato,
                size: 24,
              ),
              onSelected: (value) {
                setState(() {
                  _filterRole = value;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(Icons.people, color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 12),
                      const Text('All Users'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'student',
                  child: Row(
                    children: [
                      Icon(Icons.school, color: Brand.tomato, size: 20),
                      const SizedBox(width: 12),
                      const Text('Students'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'vendor',
                  child: Row(
                    children: [
                      Icon(Icons.store,
                          color: Colors.orange.shade600, size: 20),
                      const SizedBox(width: 12),
                      const Text('Vendors'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Filter indicator
          if (_filterRole != 'all')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _filterRole == 'vendor'
                    ? Colors.orange.shade100
                    : Brand.tomatoTint,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _filterRole == 'vendor'
                      ? Colors.orange.shade300
                      : Brand.tomato,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _filterRole == 'vendor' ? Icons.store : Icons.school,
                    color: _filterRole == 'vendor'
                        ? Colors.orange.shade700
                        : Brand.tomatoDeep,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Showing ${_filterRole == 'vendor' ? 'Vendors' : 'Students'} only',
                    style: TextStyle(
                      color: _filterRole == 'vendor'
                          ? Colors.orange.shade700
                          : Brand.tomatoDeep,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _filterRole = 'all';
                      });
                    },
                    child: Icon(
                      Icons.close,
                      color: _filterRole == 'vendor'
                          ? Colors.orange.shade700
                          : Brand.tomatoDeep,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

          // Users list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filterRole == 'all'
                  ? _firestore.collection('users').snapshots()
                  : _firestore
                      .collection('users')
                      .where('role', isEqualTo: _filterRole)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading users...'),
                      ],
                    ),
                  );
                }

                final users = snapshot.data!.docs;

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData =
                        users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;

                    final user = core.User(
                      id: userId,
                      fullName: userData['fullName'] ?? '',
                      email: userData['email'] ?? '',
                      universityId: userData['universityId'] ?? '',
                      universityName: userData['universityName'] ?? '',
                      phoneNumber: userData['phoneNumber'] ?? '',
                      isEmailVerified: userData['isEmailVerified'] ?? false,
                      role: userData['role'] ?? 'student',
                      walletBalance: userData['walletBalance'] != null
                          ? (userData['walletBalance'] as num).toDouble()
                          : 0.0,
                      profileImageUrl: userData['profileImageUrl'] ?? '',
                    );

                    return UserCard(
                      user: user,
                      onDelete: () => _deleteUser(users[index].id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && currentUser.uid == userId) {
        await currentUser.delete();
      } else {
        throw Exception('Need admin privileges to delete other users');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auth Error: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: $e')),
        );
      }
    }
  }
}

class UserCard extends StatelessWidget {
  final core.User user;
  final VoidCallback onDelete;

  const UserCard({
    required this.user,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: user.role == 'vendor'
                      ? Colors.orange.shade100
                      : Brand.tomatoTint,
                  child: Icon(
                    user.role == 'vendor' ? Icons.store : Icons.person,
                    color: user.role == 'vendor'
                        ? Colors.orange.shade600
                        : Brand.tomato,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Role chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.role == 'vendor'
                        ? Colors.orange.shade100
                        : Brand.tomatoTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: TextStyle(
                      color: user.role == 'vendor'
                          ? Colors.orange.shade700
                          : Brand.tomatoDeep,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // User details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        user.phoneNumber.isEmpty
                            ? 'No phone number'
                            : user.phoneNumber,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (user.universityName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.school,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.universityName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon:
                        Icon(Icons.delete_outline, color: Colors.red.shade600),
                    onPressed: onDelete,
                    tooltip: 'Delete user',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
