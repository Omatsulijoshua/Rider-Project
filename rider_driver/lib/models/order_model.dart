class OrderModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String item;
  final int quantity;
  final String pickupLocation;
  final String deliveryLocation;
  final String pickupAddress;
  final String deliveryAddress;
  final double price;
  final String
  status; // 'pending', 'accepted', 'picked_up', 'on_delivery', 'delivered', 'rejected'
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final String? assignedDriverId;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.item,
    required this.quantity,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.price,
    this.status = 'pending',
    required this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.assignedDriverId,
  });

  // Empty constructor for default instance
  factory OrderModel.empty() {
    return OrderModel(
      id: '',
      customerName: '',
      customerPhone: '',
      item: '',
      quantity: 0,
      pickupLocation: '',
      deliveryLocation: '',
      pickupAddress: '',
      deliveryAddress: '',
      price: 0.0,
      status: 'pending',
      createdAt: DateTime.now(),
      acceptedAt: null,
      pickedUpAt: null,
      deliveredAt: null,
      assignedDriverId: null,
    );
  }

  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'item': item,
      'quantity': quantity,
      'pickupLocation': pickupLocation,
      'deliveryLocation': deliveryLocation,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'price': price,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'assignedDriverId': assignedDriverId,
    };
  }

  // Create from JSON
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] ?? {};
    
    return OrderModel(
      id: json['id'] ?? '',
      customerName: customer['name'] ?? json['customerName'] ?? 'Unknown',
      customerPhone: customer['phone'] ?? json['customerPhone'] ?? 'No Phone',
      item: json['itemType'] ?? json['item'] ?? 'Package',
      quantity: json['quantity'] ?? 1,
      pickupLocation: json['pickupCompanyName'] ?? json['pickupLocation'] ?? 'Pickup',
      deliveryLocation: json['dropoffCompanyName'] ?? json['deliveryLocation'] ?? 'Delivery',
      pickupAddress: json['pickupAddress'] ?? 'No Address',
      deliveryAddress: json['dropoffAddress'] ?? json['deliveryAddress'] ?? 'No Address',
      price: (json['price'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.parse(json['pickedUpAt'])
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
      assignedDriverId: json['driverId'] ?? json['assignedDriverId'],
    );
  }

  // Copy with method
  OrderModel copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? item,
    int? quantity,
    String? pickupLocation,
    String? deliveryLocation,
    String? pickupAddress,
    String? deliveryAddress,
    double? price,
    String? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? assignedDriverId,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
    );
  }
}
