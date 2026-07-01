import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider/service/api_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TrackDeliveryPage extends StatefulWidget {
  final Map<String, dynamic> order;
  const TrackDeliveryPage({super.key, required this.order});

  @override
  State<TrackDeliveryPage> createState() => _TrackDeliveryPageState();
}

class _TrackDeliveryPageState extends State<TrackDeliveryPage> {
  late IO.Socket socket;
  late String _status;
  GoogleMapController? _mapController;
  Map<String, double>? _driverLocation;
  Map<String, dynamic>? _driverProfile;
  int? _etaMinutes;
  String? _trackingPhase;
  String? _podUrl;

  @override
  void initState() {
    super.initState();
    _status = widget.order['status'];
    _initSocket();
  }

  void _initSocket() {
    final String url = ApiClient.baseUrl.replaceAll('/api', '');

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
          if (data['driver'] != null) {
            _driverProfile = Map<String, dynamic>.from(data['driver']);
          }
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
            'lat': (data['lat'] as num).toDouble(),
            'lng': (data['lng'] as num).toDouble(),
          };
          if (data['driver'] != null) {
            _driverProfile = Map<String, dynamic>.from(data['driver']);
          }
          _etaMinutes = data['etaMinutes'] is num ? (data['etaMinutes'] as num).round() : null;
          _trackingPhase = data['phase']?.toString();
        });
        _moveMapToDriver();
      }
    });

    socket.onDisconnect((_) => debugPrint('Disconnected from WebSocket'));
  }

  @override
  void dispose() {
    socket.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _moveMapToDriver() {
    final location = _driverLocation;
    final controller = _mapController;
    if (location == null || controller == null) return;

    controller.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(location['lat']!, location['lng']!),
      ),
    );
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
            _buildDriverProfileCard(),
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

  Widget _buildDriverProfileCard() {
    final profile = _driverProfile ?? widget.order['driver'];
    final onlineStatus = profile is Map ? profile['status'] ?? 'ASSIGNED' : 'ASSIGNED';
    final vehicleType = profile is Map ? profile['vehicleType'] ?? 'vehicle' : 'vehicle';
    final rating = profile is Map ? profile['rating'] ?? profile['averageRating'] ?? 0 : 0;
    final completedJobs = profile is Map ? profile['completedJobs'] ?? profile['totalRatings'] ?? 0 : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xff6053f8),
                  child: Icon(Icons.delivery_dining, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Assigned driver",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        "$vehicleType / $onlineStatus",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (_etaMinutes != null)
                  Chip(
                    label: Text("ETA $_etaMinutes min"),
                    backgroundColor: const Color(0xff6053f8).withOpacity(0.12),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _driverMetric("Rating", double.tryParse("$rating")?.toStringAsFixed(1) ?? "0.0"),
                _driverMetric("Completed", "$completedJobs jobs"),
                _driverMetric("Tracking", _driverLocation == null ? "Waiting" : "Live"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _driverMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
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
                  "${ApiClient.baseUrl}/files/$_podUrl",
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
    final driverPosition = LatLng(
      _driverLocation!['lat']!,
      _driverLocation!['lng']!,
    );
    final phaseLabel = (_trackingPhase ?? 'LIVE_TRACKING').replaceAll('_', ' ');

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
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: driverPosition,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('assigned-driver'),
                      position: driverPosition,
                      infoWindow: InfoWindow(
                        title: 'Assigned driver',
                        snippet: _etaMinutes == null ? phaseLabel : '$phaseLabel / ETA $_etaMinutes min',
                      ),
                    ),
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _moveMapToDriver();
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.navigation, size: 16),
                  label: Text(phaseLabel),
                ),
                const SizedBox(width: 8),
                if (_etaMinutes != null)
                  Chip(
                    avatar: const Icon(Icons.schedule, size: 16),
                    label: Text("ETA $_etaMinutes min"),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Lat: ${_driverLocation!['lat']!.toStringAsFixed(4)}, Lng: ${_driverLocation!['lng']!.toStringAsFixed(4)}",
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
