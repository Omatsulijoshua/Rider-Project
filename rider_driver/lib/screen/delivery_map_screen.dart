import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../provider/delivery_provider.dart';
import 'driver_home_screen.dart';

class DeliveryMapScreen extends StatefulWidget {
  const DeliveryMapScreen({super.key});

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  GoogleMapController? _mapController;

  final CameraPosition _initialCamera = const CameraPosition(
    target: LatLng(6.3382, 5.6251),
    zoom: 15,
  );

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _moveCamera(LatLng position) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 16, tilt: 45),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeliveryProvider>(
      builder: (context, delivery, _) {
        // ================= DELIVERY COMPLETE =================
        if (delivery.status == DeliveryStatus.delivered) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    "https://media.tenor.com/bm8Q6yAlsPsAAAAj/verified.gif",
                    width: 160,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Delivery Complete",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DriverHomeScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Go Home",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ================= MARKERS =================
        final markers = <Marker>{};

        if (delivery.driverLocation != null) {
          markers.add(
            Marker(
              markerId: const MarkerId("driver"),
              position: delivery.driverLocation!,
              rotation: delivery.bearing,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
            ),
          );

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _moveCamera(delivery.driverLocation!);
          });
        }

        if (delivery.route.isNotEmpty) {
          markers.add(
            Marker(
              markerId: const MarkerId("pickup"),
              position: delivery.route.first,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          );

          markers.add(
            Marker(
              markerId: const MarkerId("delivery"),
              position: delivery.route.last,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
        }

        // ================= POLYLINES =================
        final polylines = <Polyline>{};
        if (delivery.route.isNotEmpty) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              points: delivery.route,
              width: 5,
              color: Colors.blue,
            ),
          );
        }

        // ================= SINGLE ACTION BUTTON =================
        String buttonText = "";
        VoidCallback? buttonAction;

        // Auto-trigger "Mark Destination Reached" if driver reached destination
        if (delivery.status == DeliveryStatus.enRoute &&
            delivery.driverLocation != null &&
            delivery.route.isNotEmpty) {
          double distance = _calculateDistance(
            delivery.driverLocation!,
            delivery.route.last,
          );
          if (distance < 20) {
            // 20 meters threshold
            // Delay to prevent build cycle errors
            Future.microtask(() => delivery.markDestinationReached());
          }
        }

        // --- CORRECTED SWITCH LOGIC ---
        switch (delivery.status) {
          case DeliveryStatus.waitingForAcceptance:
            buttonText = "Accept Order";
            buttonAction = delivery.acceptOrder;
            break;

          case DeliveryStatus.orderAccepted:
            buttonText = "Start Pickup";
            buttonAction = delivery.startPickup;
            break;

          case DeliveryStatus.picking:
            buttonText = "Mark Picked Up";
            buttonAction = delivery.markPickedUp;
            break;

          case DeliveryStatus.enRoute:
            buttonText = "Mark Destination Reached";
            buttonAction = delivery.markDestinationReached;
            break;

          case DeliveryStatus.destinationReached:
            buttonText = "Mark as Delivered"; // <-- Fix: Text updated
            buttonAction = delivery.markDelivered; // <-- Fix: Action updated
            break;

          default:
            buttonText = "";
            buttonAction = null;
        }

        // ================= MAIN UI =================
        return Scaffold(
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: _initialCamera,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                markers: markers,
                polylines: polylines,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),

              // ================= BOTTOM PANEL =================
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (delivery.pickupLocation != null)
                        _locationCard(
                          title: "Pickup Location",
                          location: delivery.pickupLocation!,
                          color: Colors.green,
                        ),
                      const SizedBox(height: 12),
                      if (delivery.deliveryLocation != null)
                        _locationCard(
                          title: "Delivery Location",
                          location: delivery.deliveryLocation!,
                          color: Colors.red,
                        ),
                      const SizedBox(height: 16),
                      if (buttonAction != null && buttonText.isNotEmpty)
                        _actionButton(buttonText, Colors.blue, buttonAction),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= LOCATION CARD =================
  Widget _locationCard({
    required String title,
    required LocationInfo location,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.location_on, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(location.address, style: const TextStyle(fontSize: 14)),
                  Text(
                    location.name,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.green),
              onPressed: () {
                launchUrl(Uri.parse("tel:${location.phone}"));
              },
            ),
            IconButton(
              icon: const Icon(Icons.chat, color: Colors.teal),
              onPressed: () {
                launchUrl(Uri.parse("https://wa.me/${location.phone}"));
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= ACTION BUTTON =================
  Widget _actionButton(String text, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

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

  double _degToRad(double deg) => deg * 3.141592653589793 / 180;
}
