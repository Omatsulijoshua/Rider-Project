import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:rider/pages/order_history_screen.dart';
import 'package:rider/service/widget_support.dart';
import 'package:timeline_tile/timeline_tile.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:rider/service/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rider/pages/chat_page.dart';

class Order extends StatefulWidget {
  final Map<String, dynamic>? activeOrder;
  const Order({super.key, this.activeOrder});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  bool current = true, past = false;
  int _currentstep = 0;
  Map<String, dynamic>? activeOrder;
  late IO.Socket socket;

  final List<String> _statusList = [
    "Driver on the way to pickup location",
    "Rider has arrived at pickup point",
    "Parcel collected",
    "Driver on the way to delivery destination",
    "Parcel delivered",
  ];

  @override
  void initState() {
    super.initState();
    activeOrder = widget.activeOrder;
    if (activeOrder != null) {
      _updateStep(activeOrder!['status']);
      _connectSocket();
    }
  }

  void _updateStep(String status) {
    setState(() {
      switch (status) {
        case 'ACCEPTED': _currentstep = 0; break;
        case 'PICKING_UP': _currentstep = 1; break;
        case 'EN_ROUTE': _currentstep = 3; break; // Skipped "arrived" if not explicit
        case 'DESTINATION_REACHED': _currentstep = 3; break;
        case 'COMPLETED': _currentstep = 4; break;
        default: _currentstep = 0;
      }
    });
  }

  void _connectSocket() {
    String baseUrl = ApiClient.baseUrl.replaceAll('/api', '');
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      socket.emit('joinOrder', activeOrder!['id']);
    });

    socket.on('orderUpdate', (data) {
      if (mounted) {
        setState(() {
          activeOrder = {...activeOrder!, ...data};
        });
        _updateStep(data['status']);
      }
    });
  }

  @override
  void dispose() {
    if (activeOrder != null) socket.disconnect();
    super.dispose();
  }

  String _calculateETA() {
    if (activeOrder == null || activeOrder!['status'] == 'COMPLETED') return "Reached";
    
    // Default coordinates if not provided (mocking)
    double destLat = activeOrder!['dropLat'] ?? 6.5244;
    double destLng = activeOrder!['dropLng'] ?? 3.3792;
    
    // If we are picking up, destination is pickup location
    if (activeOrder!['status'] == 'ACCEPTED' || activeOrder!['status'] == 'PICKING_UP') {
      destLat = activeOrder!['pickupLat'] ?? 6.5244;
      destLng = activeOrder!['pickupLng'] ?? 3.3792;
    }

    // Driver current location
    double driverLat = activeOrder!['driver']?['latitude'] ?? 6.4589;
    double driverLng = activeOrder!['driver']?['longitude'] ?? 3.4256;

    double distance = _getDistance(driverLat, driverLng, destLat, destLng);
    
    // Assume average speed 30km/h (0.5 km/min)
    int minutes = (distance / 0.5).round();
    
    if (minutes < 1) return "Less than 1 min";
    return "$minutes mins";
  }

  double _getDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // math.pi / 180
    var a = 0.5 - math.cos((lat2 - lat1) * p)/2 + 
          math.cos(lat1 * p) * math.cos(lat2 * p) * 
          (1 - math.cos((lon2 - lon1) * p))/2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff6053f8),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text("Order Page", style: AppWidget.whiteTextFieldStyle(24)),
          const SizedBox(height: 20),

          /// WHITE CONTAINER
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  /// CARDS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      current
                          ? _activeCard(
                              "images/parcel.png",
                              "Current\nOrders",
                            )
                          : _inactiveCard(
                              "images/parcel.png",
                              "Current\nOrders",
                              () => setState(() {
                                current = true;
                                past = false;
                              }),
                            ),
                      past
                          ? _activeCard(
                              "images/delivery-man.png",
                              "Past\nOrders",
                            )
                          : _inactiveCard(
                              "images/delivery-man.png",
                              "Past\nOrders",
                              () {
                                setState(() {
                                  current = false;
                                  past = true;
                                });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                                );
                              },
                            ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// LOCATION
                  if (current)
                    Column(
                      children: [
                        if (activeOrder?['status'] != 'COMPLETED')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              "Estimated Arrival: ${_calculateETA()}",
                              style: const TextStyle(
                                color: Color(0xff6053f8),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, color: Color(0xff6053f8)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                activeOrder?['pickupAddress'] ?? "Main Market",
                                textAlign: TextAlign.center,
                                style: AppWidget.normalTextFieldStyle(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _communicationCircle(Icons.phone, Colors.green, () async {
                              final phone = activeOrder?['driver']?['user']?['phone'] ?? activeOrder?['customerPhone'] ?? "";
                              if (phone.isNotEmpty) {
                                final Uri url = Uri.parse("tel:$phone");
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              }
                            }),
                            const SizedBox(width: 20),
                            _communicationCircle(Icons.message, Colors.orange, () {
                               if (activeOrder != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      orderId: activeOrder!['id'],
                                      senderId: activeOrder!['customerId'],
                                      receiverName: activeOrder!['driver']?['user']?['name'] ?? "Driver",
                                    ),
                                  ),
                                );
                              }
                            }),
                          ],
                        ),
                      ],
                    ),

                  const Divider(),

                  Expanded(
                    child: current && activeOrder != null
                      ? Row(
                        children: [
                          /// PARCEL IMAGE
                          Image.asset(
                            "images/parcel.png",
                            height: 120,
                          ),
                          const SizedBox(width: 10),

                          /// TIMELINE
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                _statusList.length,
                                (index) {
                                  final completed = index <= _currentstep;

                                  return Expanded(
                                    child: TimelineTile(
                                      alignment: TimelineAlign.center,
                                      isFirst: index == 0,
                                      isLast: index == _statusList.length - 1,
                                      beforeLineStyle: LineStyle(
                                        thickness: 3,
                                        color: completed
                                            ? const Color(0xff6053f8)
                                            : Colors.grey,
                                      ),
                                      afterLineStyle: LineStyle(
                                        thickness: 3,
                                        color: index < _currentstep
                                            ? const Color(0xff6053f8)
                                            : Colors.grey,
                                      ),
                                      indicatorStyle: IndicatorStyle(
                                        width: 22,
                                        height: 22,
                                        indicator: completed
                                            ? Container(
                                                decoration: const BoxDecoration(
                                                  color: Color(0xff6053f8),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 13,
                                                ),
                                              )
                                            : Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.grey,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                      ),
                                      startChild: index.isOdd
                                          ? _statusText(_statusList[index])
                                          : null,
                                      endChild: index.isEven
                                          ? _statusText(_statusList[index])
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 10),
                              Text(current ? "No active orders" : "No past orders yet", 
                                style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// STATUS TEXT
  Widget _statusText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _activeCard(String image, String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black45, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Image.asset(image, height: 120),
          const SizedBox(height: 10),
          Text(text,
              textAlign: TextAlign.center,
              style: AppWidget.headlineTextFieldStyle()),
        ],
      ),
    );
  }

  Widget _inactiveCard(String image, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black45, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Image.asset(image, height: 100),
            const SizedBox(height: 10),
            Text(text,
                textAlign: TextAlign.center,
                style: AppWidget.headlineTextFieldStyle()),
          ],
        ),
      ),
    );
  }

  Widget _communicationCircle(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
