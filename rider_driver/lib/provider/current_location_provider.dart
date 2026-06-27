import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CurrentLocationProvider extends ChangeNotifier {
  /// ========================
  /// PRIVATE STATE
  /// ========================

  LatLng _currentLatLng = const LatLng(6.5244, 3.3792); // DEFAULT: Lagos
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isCancelled = false;

  StreamSubscription<Position>? _positionStream;

  /// ========================
  /// PUBLIC GETTERS
  /// ========================

  LatLng get currentLatLng => _currentLatLng;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  /// ========================
  /// MAIN METHOD – GET LOCATION
  /// ========================

  Future<void> getCurrentLocation() async {
    _resetState();
    _isLoading = true;
    notifyListeners();

    try {
      /// 1️⃣ Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Location services are disabled');
        return;
      }

      /// 2️⃣ Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          _setError('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError(
          'Location permission permanently denied. Enable it from settings.',
        );
        return;
      }

      /// 3️⃣ Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_isCancelled) return;

      _currentLatLng = LatLng(position.latitude, position.longitude);

      _clearError();
    } catch (e) {
      _setError('Failed to get location: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ========================
  /// LIVE LOCATION (OPTIONAL)
  /// ========================

  void startLiveLocation() {
    _positionStream?.cancel();

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (_isCancelled) return;

          _currentLatLng = LatLng(position.latitude, position.longitude);

          notifyListeners();
        });
  }

  /// ========================
  /// CANCEL LOCATION REQUEST (UI CAN CALL THIS)
  /// ========================

  void cancelLocationRequest() {
    _isCancelled = true;
    _isLoading = false;
    _positionStream?.cancel();
    notifyListeners();
  }

  /// ========================
  /// MANUAL REFRESH
  /// ========================

  Future<void> refreshLocation() async {
    cancelLocationRequest();
    _isCancelled = false;
    await getCurrentLocation();
  }

  /// ========================
  /// HELPERS
  /// ========================

  void _resetState() {
    _errorMessage = '';
    _isCancelled = false;
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }

  /// ========================
  /// CLEANUP
  /// ========================

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
