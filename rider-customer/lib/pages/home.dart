import 'package:flutter/material.dart';
import 'package:rider/service/widget_support.dart';
import 'package:rider/pages/post.dart';
import 'package:rider/pages/track_delivery.dart';
import 'package:rider/service/api_client.dart';
import 'package:rider/pages/order_history_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _trackingController = TextEditingController();
  bool _isTracking = false;

  Future<void> _searchTracking() async {
    String tid = _trackingController.text.trim();
    if (tid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a tracking ID")),
      );
      return;
    }

    setState(() => _isTracking = true);

    try {
      // 🕵️ Public tracking endpoint
      final response = await ApiClient().get('/orders/track/$tid', requireAuth: false);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackDeliveryPage(order: response),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString().contains('404') ? 'Tracking ID not found' : e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isTracking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 25),
            _buildSchedulingSection(),
            const SizedBox(height: 25),
            _buildMainActions(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xff6053f8),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Track Parcel", style: AppWidget.whiteTextFieldStyle(28.0).copyWith(fontWeight: FontWeight.bold)),
                  Text("Enter your unique tracking ID below", style: AppWidget.differentShadeWhiteTextFieldStyle()),
                ],
              ),
              const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white24,
                child: Icon(Icons.notifications_none, color: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: TextField(
              controller: _trackingController,
              decoration: InputDecoration(
                hintText: "RID-XXXX-XXXX",
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.qr_code_scanner, color: Color(0xff6053f8)),
                suffixIcon: IconButton(
                  onPressed: _isTracking ? null : _searchTracking,
                  icon: _isTracking 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search, color: Color(0xff6053f8), size: 30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Quick Services", style: AppWidget.headlineTextFieldStyle()),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildServiceCard(
                "Schedule Pick-up", 
                Icons.calendar_today_outlined, 
                Colors.orange,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PostPage())),
              )),
              const SizedBox(width: 15),
              Expanded(child: _buildServiceCard(
                "Quick Drop-off", 
                Icons.location_on_outlined, 
                Colors.green,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PostPage())),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildActionRow(
            "New Order", 
            "Send a package anywhere", 
            "images/fast-delivery.png",
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PostPage())),
          ),
          const SizedBox(height: 15),
          _buildActionRow(
            "Delivery History", 
            "View your past activities", 
            "images/delivery-bike.png",
            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(String title, String sub, String img, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(img, height: 70, width: 70, fit: BoxFit.cover),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppWidget.headlineTextFieldStyle().copyWith(fontSize: 18)),
                  Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
