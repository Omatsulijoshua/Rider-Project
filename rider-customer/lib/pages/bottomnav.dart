import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:rider/pages/home.dart';
import 'package:rider/pages/order.dart';
import 'package:rider/pages/post.dart';
import 'package:rider/pages/profile_page.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  late final List<Widget> pages;
  int currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    pages = [
      Home(),
      PostPage(),
      Order(), // Orders
      ProfilePage(), // Profile
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        height: 70,
        backgroundColor: Colors.white,
        color: Colors.black,
        animationDuration: const Duration(milliseconds: 500),
        onTap: (int index) => setState(() => currentTabIndex = index),
        items: const [
          Icon(Icons.home, color: Colors.white, size: 34.0),
          Icon(Icons.post_add, color: Colors.white, size: 34.0),
          Icon(Icons.shopping_bag, color: Colors.white, size: 34.0),
          Icon(Icons.person, color: Colors.white, size: 34.0),
        ],
      ),
      body: pages[currentTabIndex],
    );
  }
}
