import 'package:flutter/material.dart';

class OrderOnTheWay extends StatelessWidget {
  final String orderId;
  final String driverName;
  final String status;
  final String location;

  const OrderOnTheWay({
    super.key,
    required this.orderId,
    required this.driverName,
    required this.status,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: $orderId',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Driver: $driverName'),
            const SizedBox(height: 6),
            Text(
              'Status: $status',
              style: TextStyle(
                color: status == 'On the Way' ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(height: 6),
            Text('Location: $location'),
          ],
        ),
      ),
    );
  }
}
