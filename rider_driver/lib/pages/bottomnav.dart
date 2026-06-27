import 'package:flutter/material.dart';
import 'package:rider_driver/screen/driver_home_screen.dart';
import 'package:rider_driver/screen/order_list_screen.dart';
import 'package:rider_driver/screen/order_detail_screen.dart';
import 'package:rider_driver/screen/shipment_tracking_screen.dart';
import 'package:rider_driver/pages/profile.dart';
import 'package:rider_driver/services/socket_service.dart';
import 'package:rider_driver/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:rider_driver/provider/delivery_provider.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    SocketService().init(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().syncOrdersFromBackend();
    });
  }

  @override
  void dispose() {
    SocketService().disconnect();
    super.dispose();
  }

  // Pages for Bottom Navigation
  final List<Widget> _pages = [
    const DriverHomeScreen(),
    const OrderDetailsScreen(),
    const OrdersScreen(),
    Consumer<DeliveryProvider>(
      builder: (context, provider, _) => ShipmentTrackingScreen(
        activeOrders: provider.activeOrders,
        onStatusUpdate: (id, status) => provider.updateMultipleOrderStatus(id, status),
      ),
    ),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: Colors.white,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: "Details"),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: "Orders"),
            BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), activeIcon: Icon(Icons.local_shipping), label: "Shipments"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
