import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:rider/pages/order.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:rider/pages/track_delivery.dart';
import 'package:rider/service/api_client.dart';

class SearchingRiderPage extends StatefulWidget {
  final Map<String, dynamic> order;
  const SearchingRiderPage({super.key, required this.order});

  @override
  State<SearchingRiderPage> createState() => _SearchingRiderPageState();
}

class _SearchingRiderPageState extends State<SearchingRiderPage> {
  late IO.Socket socket;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isFound = false;

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _playSearchingSound();
  }

  Future<void> _playSearchingSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // Ensure you have this sound in assets/searching_sound.mp3
      // and added to pubspec.yaml assets section.
      await _audioPlayer.play(AssetSource('assets/searching_sound.mp3'));
    } catch (e) {
      print("Audio Error: $e");
    }
  }

  void _stopSound() {
    _audioPlayer.stop();
  }

  void _connectSocket() {
    // Guard against multiple connections
    try {
      if (socket.connected) return;
    } catch (_) {
      // socket not initialized
    }

    String baseUrl = ApiClient.baseUrl.replaceAll('/api', '');
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Customer Socket Connected: ${socket.id}');
      socket.emit('joinOrder', widget.order['id']);
    });

    socket.on('orderUpdate', (data) {
      print('Order Update Received: $data');
      if (data['status'] == 'ACCEPTED') {
        setState(() => _isFound = true);
        _stopSound();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Order(activeOrder: {...widget.order, ...data}),
              ),
            );
          }
        });
      }
    });

    socket.on('debugLog', (data) {
      print('🛠️ BACKEND DEBUG: ${data['message']}');
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff6053f8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isFound
                  ? const Icon(Icons.check_circle, color: Colors.white, size: 100)
                  : const SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 8,
                      ),
                    ),
              const SizedBox(height: 40),
              Text(
                _isFound ? "Rider Found! 🎉" : "Searching for nearby Riders...",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isFound
                    ? "Your rider is on their way."
                    : "Connecting you with the best delivery partner for your package.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 50),
              if (!_isFound)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              "Order #${widget.order['id'].toString().substring(0, 8)}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            "₦${widget.order['price']}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Tracking ID:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          SelectableText(
                            widget.order['trackingId'] ?? "N/A",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
