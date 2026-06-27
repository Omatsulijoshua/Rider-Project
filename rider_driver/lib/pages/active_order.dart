import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rider_driver/services/api_client.dart';

class ActiveOrderPage extends StatefulWidget {
  final Map<String, dynamic> order;
  const ActiveOrderPage({super.key, required this.order});

  @override
  State<ActiveOrderPage> createState() => _ActiveOrderPageState();
}

class _ActiveOrderPageState extends State<ActiveOrderPage> {
  Timer? _locationTimer;
  late String _status;
  bool _isUpdating = false;
  XFile? _podImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _status = widget.order['status'];
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    // Update location every 15 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _sendLocationUpdate();
    });
    // Send first update immediately
    _sendLocationUpdate();
  }

  Future<void> _sendLocationUpdate() async {
    try {
      // Mock location for demo purposes.
      // In a real app, use geolocator package.
      await ApiClient().patch(
        '/drivers/location',
        body: {
          'lat': 6.5244, // Mock Lagos Lat
          'lng': 3.3792, // Mock Lagos Lng
          'orderId': widget.order['id'],
        },
      );
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _podImage = image);
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);
    try {
      final verificationCode = await _verificationCodeForStatus(status);
      if (!mounted) return;
      if ((status == 'EN_ROUTE' || status == 'COMPLETED') &&
          verificationCode == null) {
        setState(() => _isUpdating = false);
        return;
      }

      String? podUrl;
      if (status == 'COMPLETED' && _podImage != null) {
        final uploadRes = await ApiClient().upload(
          '/files/upload',
          filePath: _podImage!.path,
        );
        podUrl = uploadRes['key'];
      }

      await ApiClient().patch(
        '/orders/${widget.order['id']}/status',
        body: {
          'status': status,
          'proofOfDelivery': podUrl,
          if (verificationCode != null) 'verificationCode': verificationCode,
        },
      );
      setState(() {
        _status = status;
        _isUpdating = false;
      });
      if (status == 'COMPLETED' || status == 'CANCELLED') {
        _locationTimer?.cancel();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  Future<String?> _verificationCodeForStatus(String status) async {
    if (status != 'EN_ROUTE' && status != 'COMPLETED') return null;

    final controller = TextEditingController();
    final label = status == 'EN_ROUTE' ? 'pickup' : 'drop-off';

    final code = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter $label code'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(
              labelText:
                  '${label[0].toUpperCase()}${label.substring(1)} verification code',
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (code == null || code.length != 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A 4-digit verification code is required'),
          ),
        );
      }
      return null;
    }

    return code;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Delivery")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            Text(
              "Package Information",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _buildInfoRow(
              Icons.category,
              "Type:",
              widget.order['itemType'] ?? 'N/A',
            ),
            _buildInfoRow(
              Icons.business,
              "Pickup:",
              widget.order['pickupCompanyName'] ?? 'N/A',
            ),
            _buildInfoRow(
              Icons.flag,
              "Drop-off:",
              widget.order['dropoffCompanyName'] ?? 'N/A',
            ),
            _buildInfoRow(
              Icons.person,
              "Recipient:",
              widget.order['recipientName'] ?? 'N/A',
            ),
            _buildInfoRow(
              Icons.phone,
              "Phone:",
              widget.order['recipientPhone'] ?? 'N/A',
            ),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff6053f8).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff6053f8), width: 1),
      ),
      child: Column(
        children: [
          const Text("Current Status", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            _status,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xff6053f8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isUpdating) return const Center(child: CircularProgressIndicator());

    switch (_status) {
      case 'ACCEPTED':
        return _buildButton(
          "ARRIVED AT PICKUP",
          () => _updateStatus('PICKING_UP'),
        );
      case 'PICKING_UP':
        return _buildButton(
          "START DELIVERY (IN TRANSIT)",
          () => _updateStatus('EN_ROUTE'),
        );
      case 'EN_ROUTE':
        return _buildButton(
          "ARRIVED AT DESTINATION",
          () => _updateStatus('DESTINATION_REACHED'),
        );
      case 'DESTINATION_REACHED':
        return Column(
          children: [
            if (_podImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_podImage!.path),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
            ],
            _buildButton(
              _podImage == null ? "CAPTURE PROOF OF DELIVERY" : "RE-TAKE PHOTO",
              _pickImage,
              color: Colors.orange,
              isOutlined: _podImage != null,
            ),
            const SizedBox(height: 12),
            if (_podImage != null)
              _buildButton(
                "MARK AS DELIVERED",
                () => _updateStatus('COMPLETED'),
                color: Colors.green,
              ),
            const SizedBox(height: 12),
            _buildButton(
              "CANCEL DELIVERY",
              () => _updateStatus('CANCELLED'),
              color: Colors.red,
              isOutlined: true,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildButton(
    String text,
    VoidCallback onPressed, {
    Color color = const Color(0xff6053f8),
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}
