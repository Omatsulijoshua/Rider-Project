import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rider_driver/services/api_client.dart';
import 'package:rider_driver/services/shared_pref.dart';
import 'package:rider_driver/provider/delivery_provider.dart';
import 'package:rider_driver/models/order_model.dart';
import 'package:provider/provider.dart';
import 'package:rider_driver/screen/delivery_map_screen.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket socket;
  bool isConnected = false;

  void init(BuildContext context) async {
    if (isConnected) return;
    
    String? userId = await SharedpreferenceHelper().getUserID();
    if (userId == null) return;

    // Use baseUrl from ApiClient but remove /api
    String baseUrl = ApiClient.baseUrl.replaceAll('/api', '');

    // Prevent re-initialization if socket exists
    try {
      if (socket.connected) return;
    } catch (_) {
      // socket not yet initialized
    }

    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Driver Socket Connected: ${socket.id}');
      isConnected = true;
      socket.emit('joinDriverRoom', userId);
      
      Fluttertoast.showToast(
        msg: "Connected to Order Server ✅",
        backgroundColor: Colors.green,
        gravity: ToastGravity.TOP,
      );
    });

    socket.on('newOrderRequest', (data) {
      print('Received New Order Request: $data');
      Fluttertoast.showToast(
        msg: "NEW ORDER RECEIVED! 📦",
        backgroundColor: Colors.orange,
        gravity: ToastGravity.TOP,
        toastLength: Toast.LENGTH_LONG,
      );
      _showOrderRequestDialog(context, data);
    });

    socket.on('debugLog', (data) {
      print('🛠️ BACKEND DEBUG: ${data['message']}');
    });

    socket.onDisconnect((_) {
      print('Driver Socket Disconnected');
      isConnected = false;
      Fluttertoast.showToast(
        msg: "Disconnected from Server ❌",
        backgroundColor: Colors.red,
        gravity: ToastGravity.TOP,
      );
    });
  }

  void _showOrderRequestDialog(BuildContext context, dynamic data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("New Order Request! 📦"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Item: ${data['itemType'] ?? 'Package'}"),
            Text("Price: ₦${data['price']}"),
            const SizedBox(height: 10),
            const Text("Pickup is nearby your location."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _rejectOrder(data['orderId']);
            },
            child: const Text("REJECT", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              // Navigate to accept logic or call accept API
              _acceptOrder(context, data['orderId']);
            },
            child: const Text("ACCEPT", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectOrder(String orderId) async {
    try {
      await ApiClient().patch('/orders/$orderId/reject', body: {});
    } catch (e) {
      print("Error rejecting order: $e");
    }
  }

  Future<void> _acceptOrder(BuildContext context, String orderId) async {
    try {
      final response = await ApiClient().patch('/orders/$orderId/accept', body: {});
      
      if (response != null) {
        // Parse the order from response and add to provider
        final order = OrderModel.fromJson(response);
        final provider = Provider.of<DeliveryProvider>(context, listen: false);
        
        // Update provider and status
        provider.setCurrentOrder(order);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order Accepted! 🚀")),
        );

        // Navigate to the map screen to start delivery
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DeliveryMapScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void disconnect() {
    socket.disconnect();
  }
}
