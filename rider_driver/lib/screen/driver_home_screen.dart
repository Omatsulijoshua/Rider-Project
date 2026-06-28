import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_driver/provider/current_location_provider.dart';
import 'package:rider_driver/provider/delivery_provider.dart';
import 'package:rider_driver/utils/app_colors.dart';
import 'package:rider_driver/services/api_client.dart';
import 'package:rider_driver/services/socket_service.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  bool _isOnline = false;
  String _driverStatus = 'OFFLINE';
  Timer? _locationTimer;
  bool _locationWarningSent = false;

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    context.read<CurrentLocationProvider>().startLiveLocation();
    _sendLocationUpdate();

    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!_isOnline) {
        timer.cancel();
        return;
      }
      await _sendLocationUpdate();
    });
  }

  Future<void> _sendLocationUpdate() async {
    final locationProvider = context.read<CurrentLocationProvider>();

    if (locationProvider.hasError) {
      await _reportLocationDisabled();
      return;
    }

    try {
      final current = locationProvider.currentLatLng;
      final response = await ApiClient().patch('/drivers/location', body: {
        'lat': current.latitude,
        'lng': current.longitude,
      });

      if (response is Map && response['status'] != null && mounted) {
        setState(() => _driverStatus = response['status']);
      }
    } catch (e) {
      print("Error updating live location: $e");
    }
  }

  Future<void> _reportLocationDisabled() async {
    if (_locationWarningSent) return;
    _locationWarningSent = true;

    try {
      await ApiClient().post('/drivers/location-disabled', body: {});
    } catch (e) {
      print("Error reporting disabled location: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrentLocationProvider>().getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<CurrentLocationProvider>();
    final LatLng driverLatLng = locationProvider.currentLatLng ?? const LatLng(6.3382, 5.6251);

    return Scaffold(
      body: Stack(
        children: [
          // GOOGLE MAP
          GoogleMap(
            initialCameraPosition: CameraPosition(target: driverLatLng, zoom: 15),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) _mapController.complete(controller);
            },
          ),

          // TOP BAR / STATUS
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: _statusToggle(),
          ),

          // CURRENT ORDER QUICK VIEW (if any)
          Consumer<DeliveryProvider>(
            builder: (context, delivery, _) {
              if (delivery.currentOrder != null && delivery.status != DeliveryStatus.waitingForAcceptance) {
                return Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _activeOrderCard(delivery),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          if (locationProvider.isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),

          if (locationProvider.hasError)
            Positioned(
              top: 130,
              left: 20,
              right: 20,
              child: _errorBox(locationProvider.errorMessage),
            ),
        ],
      ),
    );
  }

  Widget _statusToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isOnline ? Colors.green : Colors.red,
                  boxShadow: [BoxShadow(color: (_isOnline ? Colors.green : Colors.red).withOpacity(0.4), blurRadius: 4, spreadRadius: 2)],
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _isOnline ? _driverStatus : 'OFFLINE',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          CupertinoSwitch(
            value: _isOnline,
            activeTrackColor: AppColors.primary,
            onChanged: (value) async {
              setState(() {
                _isOnline = value;
                _driverStatus = value ? 'AVAILABLE' : 'OFFLINE';
              });
              try {
                final response = await ApiClient().post('/drivers/status', body: {'isOnline': value});
                if (response is Map && response['status'] != null && mounted) {
                  setState(() => _driverStatus = response['status']);
                }
                if (value) {
                  SocketService().init(context);
                  _startLocationUpdates();
                  _locationWarningSent = false;
                } else {
                  SocketService().disconnect();
                  _locationTimer?.cancel();
                  context.read<CurrentLocationProvider>().cancelLocationRequest();
                }
              } catch (e) {
                print("Error syncing status: $e");
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _activeOrderCard(DeliveryProvider delivery) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.local_shipping, color: AppColors.primary),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Active Delivery", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("ID: ${delivery.currentAssignedOrderId?.substring(0, 8)}...", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  delivery.status.name.toUpperCase(),
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to active order screen or map
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text("View Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(15)),
      child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }
}
