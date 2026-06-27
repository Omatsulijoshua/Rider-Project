import 'package:flutter/material.dart';
import 'package:rider_driver/models/order_model.dart';
import 'package:rider_driver/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rider_driver/screen/chat_screen.dart';

class ShipmentTrackingScreen extends StatefulWidget {
  final List<OrderModel> activeOrders;
  final Function(String orderId, String newStatus) onStatusUpdate;

  const ShipmentTrackingScreen({
    super.key,
    required this.activeOrders,
    required this.onStatusUpdate,
  });

  @override
  State<ShipmentTrackingScreen> createState() => _ShipmentTrackingScreenState();
}

class _ShipmentTrackingScreenState extends State<ShipmentTrackingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Active Deliveries', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: widget.activeOrders.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Page Indicator
                if (widget.activeOrders.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.activeOrders.length,
                        (index) => _buildPageIndicator(index),
                      ),
                    ),
                  ),
                // Order Cards
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemCount: widget.activeOrders.length,
                        itemBuilder: (context, index) {
                          final order = widget.activeOrders[index];
                          return GestureDetector(
                            onTap: () => _showStatusUpdateDialog(context, order),
                            child: _buildOrderCard(order),
                          );
                        },
                      ),
                    ),
              ],
            ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Order Status"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Picking Up"),
              onTap: () {
                widget.onStatusUpdate(order.id, "PICKING_UP");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("En Route"),
              onTap: () {
                widget.onStatusUpdate(order.id, "EN_ROUTE");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Completed"),
              onTap: () {
                widget.onStatusUpdate(order.id, "COMPLETED");
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
            child: const Icon(Icons.local_shipping_outlined, size: 80, color: AppColors.primary),
          ),
          const SizedBox(height: 30),
          const Text(
            'No Active Deliveries',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'New orders will appear here',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _currentPage == index ? 30 : 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: _currentPage == index ? AppColors.primary : Colors.grey[300],
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        order.customerName,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                  _statusBadge(order.status),
                ],
              ),
              const SizedBox(height: 30),
              
              // Progress Timeline
              _buildProgressTimeline(order),
              
              const SizedBox(height: 30),
              
              // Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Item", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text(order.item, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Earnings", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text("₦${order.price}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Locations
              _locationItem(Icons.radio_button_checked, Colors.green, 'Pickup', order.pickupAddress),
              const Padding(
                padding: EdgeInsets.only(left: 11),
                child: SizedBox(height: 20, child: VerticalDivider(thickness: 1, color: Colors.black12)),
              ),
              _locationItem(Icons.location_on, Colors.red, 'Delivery', order.deliveryAddress),
              
              const SizedBox(height: 40),
              
              // Action Buttons
              _buildActionButtons(order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 10),
      ),
    );
  }

  Widget _buildProgressTimeline(OrderModel order) {
    final stages = [
      {'label': 'Accepted', 'icon': Icons.check, 'key': 'accepted'},
      {'label': 'Picked Up', 'icon': Icons.shopping_bag, 'key': 'picked_up'},
      {'label': 'On Delivery', 'icon': Icons.local_shipping, 'key': 'on_delivery'},
      {'label': 'Delivered', 'icon': Icons.done_all, 'key': 'delivered'},
    ];

    return Column(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isCompleted = _isStageCompleted(order, stage['key'] as String);
        final isActive = _isStageActive(order, stage['key'] as String);

        return Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppColors.primary : Colors.grey[200],
                  ),
                  child: Icon(
                    stage['icon'] as IconData,
                    size: 16,
                    color: isCompleted ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    stage['label'] as String,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? AppColors.textPrimary : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isActive && !isCompleted)
                  TextButton(
                    onPressed: () => widget.onStatusUpdate(order.id, stage['key'] as String),
                    child: const Text("MARK DONE", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),
            if (index < stages.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Container(
                  width: 2,
                  height: 20,
                  color: isCompleted ? AppColors.primary.withOpacity(0.3) : Colors.grey[200],
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _locationItem(IconData icon, Color color, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(address, style: const TextStyle(fontSize: 14, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    if (order.status == 'delivered') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
        child: const Center(child: Text('COMPLETED ✓', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _actionBtn(Icons.call, "Call", Colors.blue, () => _contactCustomer(order)),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _actionBtn(Icons.navigation, "Map", AppColors.primary, () => _viewMap(order)),
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  bool _isStageCompleted(OrderModel order, String stage) {
    const stageOrder = ['accepted', 'picked_up', 'on_delivery', 'delivered'];
    final currentIndex = stageOrder.indexOf(order.status);
    final stageIndex = stageOrder.indexOf(stage);
    return currentIndex >= stageIndex;
  }

  bool _isStageActive(OrderModel order, String stage) {
    const stageOrder = ['accepted', 'picked_up', 'on_delivery', 'delivered'];
    final currentIndex = stageOrder.indexOf(order.status);
    final stageIndex = stageOrder.indexOf(stage);
    return currentIndex == stageIndex - 1;
  }

  void _contactCustomer(OrderModel order) {
    _showContactOptions(order);
  }

  void _showContactOptions(OrderModel order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text("Call Customer"),
              onTap: () async {
                Navigator.pop(context);
                final Uri url = Uri.parse("tel:${order.customerPhone}");
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: const Text("Message Customer"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      orderId: order.id,
                      senderId: "DRIVER_ID", // TODO: Get actual driver ID from auth
                      receiverName: order.customerName,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _viewMap(OrderModel order) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening map...')));
  }
}
