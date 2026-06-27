class LocationService {
  Future<Map<String, double>> getCurrentLocation() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'lat': 6.5244,
      'lng': 3.3792,
    };
  }
}
