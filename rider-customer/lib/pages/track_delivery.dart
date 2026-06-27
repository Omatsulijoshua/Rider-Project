import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
// Assuming backendUrl is here

class TrackDeliveryPage extends StatefulWidget {
  final Map<String, dynamic> order;
  const TrackDeliveryPage({super.key, required this.order});

  @override
  State<TrackDeliveryPage> createState() => _TrackDeliveryPageState();
}

class _TrackDeliveryPageState extends State<TrackDeliveryPage> {
  late IO.Socket socket;
  late String _status;
  Map<String, double>? _driverLocation;
  String? _podUrl;

  @override
  void initState() {
    super.initState();
    _status = widget.order['status'];
    _initSocket();
  }

  void _initSocket() {
    // In a real app, use the actual backend URL from constants
    // For now, using a placeholder if backendUrl is not defined
    const String url = "http://localhost:3000"; // Update this to your server IP

    socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Connected to WebSocket');
      socket.emit('joinOrder', widget.order['id']);
    });

    socket.on('orderUpdate', (data) {
      if (mounted) {
        setState(() {
          _status = data['status'];
          if (data['proofOfDelivery'] != null) {
            _podUrl = data['proofOfDelivery'];
          }
        });
      }
    });

    socket.on('driverLocation', (data) {
      if (mounted) {
        setState(() {
          _driverLocation = {
            'lat': data['lat'],
            'lng': data['lng'],
          };
        });
      }
    });

    socket.onDisconnect((_) => debugPrint('Disconnected from WebSocket'));
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Track Your Package")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 30),
            _buildTrackingTimeline(),
            const SizedBox(height: 30),
            if (_podUrl != null || _status == 'COMPLETED') _buildPODCard(),
            const SizedBox(height: 30),
            if (_driverLocation != null) _buildDriverLocationCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff6053f8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, color: Colors.white, size: 40),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Status",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  _status.replaceAll('_', ' '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    // Simple vertical timeline representation
    final statuses = [
      'REQUESTED',
      'ACCEPTED',
      'PICKING_UP',
      'EN_ROUTE',
      'COMPLETED'
    ];
    final currentIndex = statuses.indexOf(_status);

    return Column(
      children: List.generate(statuses.length, (index) {
        final bool isPast = index <= currentIndex;
        final bool isLast = index == statuses.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isPast ? const Color(0xff6053f8) : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: isPast
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 50,
                    color: isPast ? const Color(0xff6053f8) : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statuses[index].replaceAll('_', ' '),
                    style: TextStyle(
                      fontWeight: isPast ? FontWeight.bold : FontWeight.normal,
                      color: isPast ? Colors.black : Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPODCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 10),
                Text("Proof of Delivery",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            if (_podUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  "http://localhost:3000/api/files/$_podUrl", // Adjust to your API base
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text("Error loading image"),
                  ),
                ),
              )
            else
              const Center(child: Text("Waiting for photo upload...")),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverLocationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.person_pin_circle, color: Color(0xff6053f8)),
                SizedBox(width: 10),
                Text("Driver is currently at:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
                "Lat: ${_driverLocation!['lat']!.toStringAsFixed(4)}, Lng: ${_driverLocation!['lng']!.toStringAsFixed(4)}"),
            const SizedBox(height: 10),
            const Text(
              "(In a production app, this would be a Google Map view)",
              style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
