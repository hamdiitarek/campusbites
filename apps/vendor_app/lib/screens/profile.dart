import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Builder(builder: (context) {
          return SafeArea(
              child: Padding(
            padding: const EdgeInsets.all(15.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 0),
            ]),
          ));
        }),
        actions: [
          Tooltip(
            message: 'Logout',
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await userProvider.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ),
        ],
      ),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.fastfood_outlined,
                      size: 80,
                      color: Brand.tomato,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome ${userProvider.user?.fullName ?? "to BrainFuel"}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your university food platform',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // User information card
                    if (userProvider.user != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(80),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Your Profile Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildProfileRow(Icons.person, 'Name',
                                userProvider.user!.fullName),
                            if (userProvider.user!.role != 'vendor')
                              _buildProfileRow(
                                  Icons.account_balance_wallet,
                                  'Wallet',
                                  userProvider.user!.walletBalance
                                      .toStringAsFixed(2)),
                            _buildProfileRow(
                                Icons.email, 'Email', userProvider.user!.email),
                            _buildProfileRow(Icons.school, 'University',
                                userProvider.user!.universityName),

                            // Conditional Univ. ID to not show in vendor profile
                            if (userProvider.user!.role != 'vendor')
                              _buildProfileRow(Icons.badge, 'Univ. ID',
                                  userProvider.user!.universityId),

                            _buildProfileRow(Icons.phone, 'Phone',
                                userProvider.user!.phoneNumber),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 20),
                    // Recharge Wallet Button
                    if (userProvider.user!.role != 'vendor')
                      ElevatedButton.icon(
                        onPressed: () {
                          print(
                              'Recharge button pressed'); // Debug print to confirm button press
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            builder: (context) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom +
                                          60, // Add extra padding for nav bar
                                  left: 16,
                                  right: 16,
                                  top: 16,
                                ),
                                child: SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Recharge Wallet',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Brand.tomatoDeep,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      TextField(
                                        controller: _amountController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Amount',
                                          hintText: 'Enter amount to recharge',
                                          prefixIcon: Icon(Icons.attach_money,
                                              color: Brand.tomato),
                                          filled: true,
                                          fillColor: Colors.grey.shade100,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: Brand.tomato, width: 2),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              _amountController.clear();
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              final amount = double.tryParse(
                                                  _amountController.text);
                                              if (amount != null &&
                                                  amount > 0) {
                                                final newBalance = userProvider
                                                        .user!.walletBalance +
                                                    amount;
                                                userProvider.updateProfile(
                                                    walletBalance: newBalance);
                                                _amountController.clear();
                                                Navigator.pop(context);
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Please enter a valid amount')),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Brand.tomato,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 24, vertical: 12),
                                            ),
                                            child: Text(
                                              'Recharge',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        icon: Icon(Icons.add_circle_outline, size: 20),
                        label: Text('Recharge Wallet'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Brand.tomato,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Brand.tomato),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SelectableText(
                  // changed to make it copyable too
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
