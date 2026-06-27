import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_driver/models/order_model.dart';
import 'package:rider_driver/services/api_client.dart';

enum DeliveryStatus {
  waitingForAcceptance,
  orderAccepted,
  picking,
  enRoute,
  destinationReached,
  delivered,
  rejected,
}

// ================= MODEL FOR LOCATION =================
class LocationInfo {
  final String address;
  final String name;
  final String phone;

  const LocationInfo({
    required this.address,
    required this.name,
    required this.phone,
  });
}

// ================= DELIVERY PROVIDER =================
class DeliveryProvider extends ChangeNotifier {
  // Single order tracking (legacy support)
  DeliveryStatus _status = DeliveryStatus.waitingForAcceptance;
  List<LatLng> _route = [];
  LatLng? _driverLocation;
  double _bearing = 0.0;
  Timer? _movementTimer;
  int _routeIndex = 0;

  LocationInfo? pickupLocation;
  LocationInfo? deliveryLocation;

  // Multiple orders tracking (new feature)
  List<OrderModel> _activeOrders = [];
  final List<OrderModel> _completedOrders = [];
  String? _currentAssignedOrderId;

  // ================= GETTERS =================
  DeliveryStatus get status => _status;
  List<LatLng> get route => List.unmodifiable(_route);
  LatLng? get driverLocation => _driverLocation;
  double get bearing => _bearing;

  bool get showAcceptRejectButtons =>
      _status == DeliveryStatus.waitingForAcceptance;
  bool get showStartPickupButton => _status == DeliveryStatus.orderAccepted;
  bool get showMarkPickedUpButton => _status == DeliveryStatus.picking;
  bool get showMarkDestinationReachedButton =>
      _status == DeliveryStatus.enRoute;
  bool get showMarkDeliveredButton =>
      _status == DeliveryStatus.destinationReached;

  // Multiple orders getters
  List<OrderModel> get activeOrders => _activeOrders;
  List<OrderModel> get completedOrders => _completedOrders;
  String? get currentAssignedOrderId => _currentAssignedOrderId;

  OrderModel? get currentOrder => _currentAssignedOrderId != null
      ? _activeOrders.firstWhere(
          (order) => order.id == _currentAssignedOrderId,
          orElse: () => OrderModel.empty(),
        )
      : null;

  // ================= INIT =================
  void initializeOrder() {
    _driverLocation = const LatLng(6.3382, 5.6251);
    _status = DeliveryStatus.waitingForAcceptance;
    _route.clear();
    _routeIndex = 0;
    _bearing = 0;

    pickupLocation = null;
    deliveryLocation = null;

    notifyListeners();
  }

  // ================= ACCEPT/REJECT =================
  void acceptOrder() {
    _status = DeliveryStatus.orderAccepted;
    _route = _generateRoutePoints();
    _routeIndex = 0;
    _driverLocation = _route.first;

    Fluttertoast.showToast(
      msg: "Order Accepted",
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );

    notifyListeners();
  }

  void rejectOrder() {
    _status = DeliveryStatus.rejected;
    _stopMovement();
    _clearDeliveryData();

    Fluttertoast.showToast(
      msg: "Order Rejected",
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );

    notifyListeners();
  }

  // ================= START PICKUP =================
  void startPickup() {
    if (_status != DeliveryStatus.orderAccepted) return;

    _status = DeliveryStatus.picking;
    notifyListeners();

    // 🌐 Sync with backend
    if (_currentAssignedOrderId != null) {
      ApiClient().patch('/orders/$_currentAssignedOrderId/status', body: {
        'status': 'PICKING_UP'
      }).catchError((e) => print("Error syncing status: $e"));
    }

    Fluttertoast.showToast(
      msg: "Pickup Started",
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );

    // Move driver halfway along route (simulate pickup to midway)
    _startMovementAnimation(startIndex: 0, endIndex: _route.length ~/ 2);
  }

  // ================= MARK PICKED UP =================
  void markPickedUp() {
    if (_status != DeliveryStatus.picking) return;

    _status = DeliveryStatus.enRoute;
    notifyListeners();

    // 🌐 Sync with backend
    if (_currentAssignedOrderId != null) {
      ApiClient().patch('/orders/$_currentAssignedOrderId/status', body: {
        'status': 'EN_ROUTE'
      }).catchError((e) => print("Error syncing status: $e"));
    }

    Fluttertoast.showToast(
      msg: "Order picked up. Delivering...",
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );

    // Move driver from midpoint to destination
    _startMovementAnimation(
      startIndex: _route.length ~/ 2,
      endIndex: _route.length - 1,
      autoMarkDestinationReached: true, // <-- auto detect
    );
  }

  // ================= MARK DESTINATION REACHED =================
  void markDestinationReached() {
    if (_status != DeliveryStatus.enRoute) return;

    _status = DeliveryStatus.destinationReached;
    notifyListeners();

    // 🌐 Sync with backend
    if (_currentAssignedOrderId != null) {
      ApiClient().patch('/orders/$_currentAssignedOrderId/status', body: {
        'status': 'DESTINATION_REACHED'
      }).catchError((e) => print("Error syncing status: $e"));
    }

    Fluttertoast.showToast(
      msg: "Destination Reached",
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }

  // ================= MARK DELIVERED =================
  void markDelivered() {
    if (_status != DeliveryStatus.destinationReached) return;

    _stopMovement();
    _driverLocation = _route.last;
    _status = DeliveryStatus.delivered;
    notifyListeners();

    // 🌐 Sync with backend
    if (_currentAssignedOrderId != null) {
      ApiClient().patch('/orders/$_currentAssignedOrderId/status', body: {
        'status': 'COMPLETED'
      }).catchError((e) => print("Error syncing status: $e"));
    }

    Fluttertoast.showToast(
      msg: "Order Delivered",
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );

    notifyListeners();
  }

  // ================= ROUTE =================
  List<LatLng> _generateRoutePoints() {
    return const [
      LatLng(6.3382, 5.6251),
      LatLng(6.3390, 5.6260),
      LatLng(6.3400, 5.6275),
      LatLng(6.3410, 5.6290),
      LatLng(6.3420, 5.6305),
      LatLng(6.3430, 5.6320),
      LatLng(6.3440, 5.6335),
      LatLng(6.3450, 5.6350),
    ];
  }

  // ================= MOVEMENT =================
  void _startMovementAnimation({
    required int startIndex,
    required int endIndex,
    bool autoMarkDestinationReached = false,
  }) {
    _movementTimer?.cancel();
    _routeIndex = startIndex;

    _movementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_routeIndex < endIndex) {
        final nextIndex = _routeIndex + 1;
        _bearing = _calculateBearing(_route[_routeIndex], _route[nextIndex]);

        _routeIndex++;
        _driverLocation = _route[_routeIndex];
        notifyListeners();

        // 🌐 Sync location with backend
        if (_driverLocation != null) {
          ApiClient().patch('/drivers/location', body: {
            'lat': _driverLocation!.latitude,
            'lng': _driverLocation!.longitude,
            'orderId': _currentAssignedOrderId,
          }).catchError((e) => print("Error syncing location: $e"));
        }

        // Check auto-destination reached
        if (autoMarkDestinationReached &&
            _driverLocation != null &&
            deliveryLocation != null) {
          double distance = _calculateDistance(
            _driverLocation!,
            _route.last,
          ); // last = delivery
          if (distance < 20) {
            // threshold 20 meters
            markDestinationReached(); // automatically update status
            timer.cancel();
            Fluttertoast.showToast(
              msg: "Destination reached automatically!",
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
          }
        }
      } else {
        timer.cancel();
      }
    });
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = _degToRad(start.latitude);
    final lon1 = _degToRad(start.longitude);
    final lat2 = _degToRad(end.latitude);
    final lon2 = _degToRad(end.longitude);

    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    return (_radToDeg(atan2(y, x)) + 360) % 360;
  }

  double _degToRad(double deg) => deg * pi / 180;
  double _radToDeg(double rad) => rad * 180 / pi;

  double _calculateDistance(LatLng a, LatLng b) {
    const double earthRadius = 6371000; // meters
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);
    final sindLat = sin(dLat / 2);
    final sindLng = sin(dLng / 2);
    final va =
        sindLat * sindLat +
        cos(_degToRad(a.latitude)) *
            cos(_degToRad(b.latitude)) *
            sindLng *
            sindLng;
    final vc = 2 * atan2(sqrt(va), sqrt(1 - va));
    return earthRadius * vc;
  }

  void _stopMovement() => _movementTimer?.cancel();

  void _clearDeliveryData() {
    _route.clear();
    _driverLocation = null;
    _bearing = 0.0;
    _routeIndex = 0;
    pickupLocation = null;
    deliveryLocation = null;
  }

  // ================= MULTIPLE ORDERS MANAGEMENT =================
  /// Accept an order and add it to active orders
  Future<void> acceptMultipleOrder(String orderId, String driverId) async {
    try {
      final orderIndex = _activeOrders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        final now = DateTime.now();
        final updatedOrder = _activeOrders[orderIndex].copyWith(
          status: 'accepted',
          assignedDriverId: driverId,
          acceptedAt: now,
        );
        _activeOrders[orderIndex] = updatedOrder;

        _currentAssignedOrderId ??= orderId;

        Fluttertoast.showToast(
          msg: "Order Accepted",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        notifyListeners();
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error accepting order: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  /// Reject an order
  Future<void> rejectMultipleOrder(String orderId) async {
    try {
      final orderIndex = _activeOrders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        _activeOrders.removeAt(orderIndex);

        if (_currentAssignedOrderId == orderId) {
          _currentAssignedOrderId = null;
        }

        Fluttertoast.showToast(
          msg: "Order Rejected",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );

        notifyListeners();
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error rejecting order: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  /// Update order status (PICKING_UP, EN_ROUTE, COMPLETED)
  Future<void> updateMultipleOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    try {
      // 🌐 Sync with backend
      await ApiClient().patch('/orders/$orderId/status', body: {
        'status': newStatus
      });

      final orderIndex = _activeOrders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        final now = DateTime.now();
        final updatedOrder = _activeOrders[orderIndex].copyWith(
          status: newStatus,
          pickedUpAt: newStatus == 'PICKING_UP'
              ? now
              : _activeOrders[orderIndex].pickedUpAt,
          deliveredAt: newStatus == 'COMPLETED'
              ? now
              : _activeOrders[orderIndex].deliveredAt,
        );
        _activeOrders[orderIndex] = updatedOrder;

        // If delivered, move to completed orders
        if (newStatus == 'COMPLETED') {
          _completedOrders.add(updatedOrder);
          _activeOrders.removeAt(orderIndex);

          if (_currentAssignedOrderId == orderId) {
            _currentAssignedOrderId = null;
          }

          Fluttertoast.showToast(
            msg: "Order Delivered",
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        } else if (newStatus == 'PICKING_UP') {
          Fluttertoast.showToast(
            msg: "Order Picked Up",
            backgroundColor: Colors.blue,
            textColor: Colors.white,
          );
        } else if (newStatus == 'EN_ROUTE') {
          Fluttertoast.showToast(
            msg: "Order On Delivery",
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }

        notifyListeners();
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating order: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  /// Add a new order (for real-time notifications)
  void addNewOrder(OrderModel order) {
    if (!_activeOrders.any((o) => o.id == order.id)) {
      _activeOrders.add(order);
      notifyListeners();
    }
  }

  /// Set the current active order and prepare for delivery
  void setCurrentOrder(OrderModel order) {
    if (!_activeOrders.any((o) => o.id == order.id)) {
      _activeOrders.add(order);
    }
    _currentAssignedOrderId = order.id;
    _status = DeliveryStatus.orderAccepted;
    
    // Set pickup and delivery locations for the map UI
    pickupLocation = LocationInfo(
      address: order.pickupAddress,
      name: order.pickupLocation,
      phone: order.customerPhone,
    );
    
    deliveryLocation = LocationInfo(
      address: order.deliveryAddress,
      name: order.customerName,
      phone: order.customerPhone,
    );

    _route = _generateRoutePoints(); // Simulation route
    _driverLocation = _route.first;
    
    notifyListeners();
  }

  /// Load active orders from backend
  Future<void> syncOrdersFromBackend() async {
    try {
      final List<dynamic> response = await ApiClient().get('/orders/my-deliveries');
      
      final List<OrderModel> orders = response.map((json) => OrderModel.fromJson(json)).toList();
      
      _activeOrders = orders.where((o) => o.status != 'delivered' && o.status != 'COMPLETED').toList();
      _completedOrders.clear();
      _completedOrders.addAll(orders.where((o) => o.status == 'delivered' || o.status == 'COMPLETED'));
      
      notifyListeners();
    } catch (e) {
      print("Error syncing orders: $e");
    }
  }

  /// Load active orders manually (deprecated)
  Future<void> loadActiveOrders(List<OrderModel> orders) async {
    _activeOrders = orders;
    notifyListeners();
  }

  /// Get orders by status
  List<OrderModel> getOrdersByStatus(String status) {
    if (status == 'completed') {
      return _completedOrders;
    }
    return _activeOrders.where((order) => order.status == status).toList();
  }

  /// Get order count by status
  int getOrderCountByStatus(String status) {
    if (status == 'completed') {
      return _completedOrders.length;
    }
    return _activeOrders.where((order) => order.status == status).length;
  }

  /// Clear all data
  void clearAllOrders() {
    _activeOrders.clear();
    _completedOrders.clear();
    _currentAssignedOrderId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopMovement();
    super.dispose();
  }
}
