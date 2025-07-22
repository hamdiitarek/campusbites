import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';
import '../screens/home_screen.dart';
import '../screens/history.dart';
import '../screens/profile.dart';
import '../screens/search_vendor.dart';

class MainTabNavigation extends StatelessWidget {
  final int initialIndex;

  const MainTabNavigation({
    super.key,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        height: 60,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(CupertinoIcons.home),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(CupertinoIcons.clock),
            ),
            label: 'Order History',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(CupertinoIcons.person),
            ),
            label: 'Profile',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          routes: {
            //'/menu': (context) => const MenuScreen(),
            // '/search_vendor': (context) => const SearchVendorScreen(),
            '/email-verification': (context) => const EmailVerificationScreen(),
          },
          builder: (BuildContext context) {
            Widget child;
            switch (index) {
              case 0:
                child = const HomeScreen();
                break;
              case 1:
                child = const HistoryScreen();
                break;
              case 2:
                child = const ProfileScreen();
                break;
              default:
                child = const HomeScreen();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: child,
            );
          },
        );
      },
    );
  }
}
