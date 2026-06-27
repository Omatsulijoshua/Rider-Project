import 'package:flutter/material.dart';
import 'package:rider_driver/screen/driver_home_screen.dart';
import 'screen/order_detail_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const DriverHomeScreen(),
  '/order-details': (context) => OrderDetailsScreen(),
  //'/map': (context) => const DeliveryMapScreen(),
};
