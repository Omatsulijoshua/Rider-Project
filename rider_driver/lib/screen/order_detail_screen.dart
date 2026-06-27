import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../provider/delivery_provider.dart';
import '../models/order_model.dart';
import 'delivery_map_screen.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});


  // ================= ACTIONS =================
  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _chat(String phone) async {
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryProvider>(
      builder: (context, deliveryProvider, _) {
        final order = deliveryProvider.currentOrder;

        if (order == null || order.id.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Details')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    "No active order selected",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Accepted orders will appear here",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Order Details')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _card(
                  title: 'Customer Information',
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundImage: AssetImage("images/boy.jpg"), // Fallback avatar
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              order.customerPhone,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: () => _call(order.customerPhone),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat, color: Colors.teal),
                        onPressed: () => _chat(order.customerPhone),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _card(
                  title: 'Order Summary',
                  child: Row(
                    children: [
                      Image.asset("images/parcel.png", width: 50, height: 50), // Fallback image
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${order.item} x${order.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₦ ${order.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _locationCard(
                  title: 'Pickup Location',
                  address: order.pickupAddress,
                  name: order.pickupLocation,
                  phone: order.customerPhone,
                  color: Colors.green,
                ),

                const SizedBox(height: 16),

                _locationCard(
                  title: 'Delivery Location',
                  address: order.deliveryAddress,
                  name: order.deliveryLocation,
                  phone: order.customerPhone,
                  color: Colors.red,
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomActions(context, deliveryProvider, order),
        );
      },
    );
  }

  Widget _buildBottomActions(BuildContext context, DeliveryProvider provider, OrderModel order) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (order.status == 'accepted')
            _bottomButton("Start Pickup", Colors.green, () {
              provider.updateMultipleOrderStatus(order.id, 'picking');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeliveryMapScreen()),
              );
            }),
          
          if (order.status == 'picking')
            _bottomButton("Mark as Picked Up", Colors.orange, () {
              provider.updateMultipleOrderStatus(order.id, 'on_delivery');
            }),

          if (order.status == 'on_delivery')
             _bottomButton("Mark as Delivered", Colors.green, () {
              provider.updateMultipleOrderStatus(order.id, 'delivered');
            }),
          
          if (order.status == 'delivered')
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.green.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: const Text(
                 "Order Successfully Delivered ✅",
                 textAlign: TextAlign.center,
                 style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
               ),
             ),
        ],
      ),
    );
  }

  // ================= UI HELPERS =================
  Widget _card({required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _locationCard({
    required String title,
    required String address,
    required String name,
    required String phone,
    required Color color,
  }) {
    return _card(
      title: title,
      child: Row(
        children: [
          Icon(Icons.location_on, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(name, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.green),
            onPressed: () => _call(phone),
          ),
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.teal),
            onPressed: () => _chat(phone),
          ),
        ],
      ),
    );
  }

  Widget _bottomButton(String text, Color color, VoidCallback? onPressed) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

