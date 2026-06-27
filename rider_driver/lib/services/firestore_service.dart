/*import 'package:rider_driver/models/order_model.dart';

class FirestoreService {
  // Fetch pending orders (mocked for now)
  Future<List<OrderModel>> fetchPendingOrders() async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      OrderModel(
        id: "1",
        customerName: "John Doe",
        customerPhone: "08012345678",
        item: "Gas Cylinder",
        quantity: 1,
        pickupLocation: "Ring Road",
        deliveryLocation: "Airport",
        pickupAddress: "Green Valley Store, Ring Road",
        deliveryAddress: "John Doe Residence, Airport",
        price: 1500.0,
      ),
      OrderModel(
        id: "2",
        customerName: "Jane Smith",
        customerPhone: "08087654321",
        item: "Food Package",
        quantity: 2,
        pickupLocation: "Ring Road",
        deliveryLocation: "Airport",
        pickupAddress: "Sunshine Market, Ring Road",
        deliveryAddress: "Jane Smith House, Airport",
        price: 2000.0,
      ),
    ];
  }

  // Accept an order
  Future<void> acceptOrder(String orderId, String driverId) async {
    // Here you would update Firestore to assign the order to the driver
    await Future.delayed(const Duration(milliseconds: 500));
    print("Order $orderId accepted by driver $driverId");
  }
}
*/
