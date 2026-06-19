import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'storage_service.dart';
import '../core/constants/api_constants.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final _storage = StorageService();
  bool _isUpdating = false;

  Future<bool> updateUserLocation() async {
    if (_isUpdating) return false;
    _isUpdating = true;

    try {
      print('[LOCATION] Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print(
        '[LOCATION] Got position: ${position.latitude}, ${position.longitude}',
      );

      await _saveLocationToBackend(position.latitude, position.longitude);
      return true;
    } catch (e) {
      print('[LOCATION] Location update error: $e');
      return false;
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _saveLocationToBackend(double lat, double lng) async {
    try {
      final token = await _storage.getAccessToken();
      print('[LOCATION] User token: ${token != null ? "exists" : "null"}');

      final data = {
        'latitude': lat,
        'longitude': lng,
        'location': {
          'latitude': lat,
          'longitude': lng,
          'coordinates': [lng, lat],
        },
      };
      print('[LOCATION] Saving to backend: $data');

      await Dio().put(
        '${ApiConstants.baseUrl}/api/v1/user/location',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      print('[LOCATION] Location saved successfully: $lat, $lng');
    } catch (e) {
      print('[LOCATION] Save location error: $e');
    }
  }

  Future<void> startBackgroundLocationUpdates() async {
    while (true) {
      await Future.delayed(const Duration(minutes: 5));
      await updateUserLocation();
    }
  }
}
