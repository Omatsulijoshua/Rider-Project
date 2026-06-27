import 'package:flutter/material.dart';

/// ===============================
/// NEW ORDER CARD (Driver popup)
/// ===============================
class NewOrderCard extends StatelessWidget {
  final String amount;
  final List<OrderItem> items;
  final LocationInfo pickup;
  final LocationInfo delivery;
  final String goodsImage;

  const NewOrderCard({
    super.key,
    required this.amount,
    required this.items,
    required this.pickup,
    required this.delivery,
    required this.goodsImage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Available Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),

            /// ITEMS + IMAGE
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ITEMS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Items',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.name),
                              Text('x${item.quantity}'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                /// GOODS IMAGE
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    goodsImage,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),

            /// PICKUP → DELIVERY (LINE + ICONS)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(Icons.store, color: Colors.orange),
                    Container(
                      height: 40,
                      width: 2,
                      color: Colors.grey.shade400,
                    ),
                    const Icon(Icons.location_on, color: Colors.red),
                  ],
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(pickup.address),
                      Text(
                        pickup.name,
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Delivery',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(delivery.address),
                      Text(
                        delivery.name,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(
                        amount: amount,
                        items: items,
                        pickup: pickup,
                        delivery: delivery,
                        goodsImage: goodsImage,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View Order Details',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =================================
/// ORDER DETAILS SCREEN (Same file)
/// =================================
class OrderDetailsScreen extends StatelessWidget {
  final String amount;
  final List<OrderItem> items;
  final LocationInfo pickup;
  final LocationInfo delivery;
  final String goodsImage;

  const OrderDetailsScreen({
    super.key,
    required this.amount,
    required this.items,
    required this.pickup,
    required this.delivery,
    required this.goodsImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                goodsImage,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 16),

            /// AMOUNT
            Text(
              amount,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 20),

            /// ITEMS
            const Text(
              'Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(item.name), Text('x${item.quantity}')],
                ),
              ),
            ),

            const Divider(height: 32),

            /// ROUTE
            Row(
              children: [
                Column(
                  children: [
                    const Icon(Icons.store, color: Colors.orange),
                    Container(height: 40, width: 2, color: Colors.grey),
                    const Icon(Icons.location_on, color: Colors.red),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pickup.address),
                      const SizedBox(height: 16),
                      Text(delivery.address),
                    ],
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

/// ===============================
/// MODELS
/// ===============================
class OrderItem {
  final String name;
  final int quantity;

  OrderItem({required this.name, required this.quantity});
}

class LocationInfo {
  final String address;
  final String name;

  LocationInfo({required this.address, required this.name});
}
