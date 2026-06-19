import 'package:dio/dio.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../core/constants/api_constants.dart';

class UserService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  // Get User Profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _api.get(ApiConstants.userProfile);

      // Update stored user data
      if (response.data['success'] == true && response.data['data'] != null) {
        await _storage.saveUser(response.data['data']);
      }

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to fetch profile',
      };
    }
  }

  // Update User Profile
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? email,
    String? profileImage,
    Map<String, dynamic>? address,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['fullName'] = fullName;
      if (email != null) data['email'] = email;
      if (profileImage != null) data['profileImage'] = profileImage;
      if (address != null) data['address'] = address;

      final response = await _api.put(ApiConstants.updateProfile, data: data);

      // After successful update, fetch and save the complete user profile
      if (response.data['success'] == true) {
        final profileResponse = await getProfile();
        if (profileResponse['success'] == true) {
          return {'success': true, 'data': profileResponse['data']['data']};
        }
      }

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to update profile',
      };
    }
  }

  // Get Notification Preferences
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final response = await _api.get(ApiConstants.notificationPreferences);
      return {'success': true, 'data': response.data['data']};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to get preferences',
      };
    }
  }

  // Update Notification Preferences
  Future<Map<String, dynamic>> updateNotificationPreferences(Map<String, bool> prefs) async {
    try {
      final response = await _api.put(ApiConstants.notificationPreferences, data: prefs);
      return {'success': true, 'data': response.data['data']};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to update preferences',
      };
    }
  }

  // Update User Address with Location
  Future<Map<String, dynamic>> updateAddress({
    String? city,
    String? society,
    String? block,
    String? tower,
    String? flatNumber,
    String? flatType,
    String? landmark,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (city != null) data['city'] = city;
      if (society != null) data['society'] = society;
      if (block != null) data['block'] = block;
      if (tower != null) data['tower'] = tower;
      if (flatNumber != null) data['flatNumber'] = flatNumber;
      if (flatType != null) data['flatType'] = flatType;
      if (landmark != null) data['landmark'] = landmark;

      // Send location in format backend expects
      if (latitude != null && longitude != null) {
        data['location'] = {
          'latitude': latitude,
          'longitude': longitude,
          'coordinates': [longitude, latitude], // GeoJSON: [lng, lat]
        };
      }

      final response = await _api.put(ApiConstants.updateAddress, data: data);

      // After successful update, fetch and save the complete user profile
      if (response.data['success'] == true) {
        final profileResponse = await getProfile();
        if (profileResponse['success'] == true) {
          return {'success': true, 'data': profileResponse['data']['data']};
        }
      }

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to update address',
      };
    }
  }
}
