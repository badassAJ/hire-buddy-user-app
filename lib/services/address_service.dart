import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/saved_address.dart';
import 'api_service.dart';

class AddressService {
  final _api = ApiService();

  Future<List<SavedAddress>> listAddresses() async {
    try {
      final res = await _api.get(ApiConstants.addresses);
      final data = res.data['data'] as List? ?? [];
      return data.map((e) => SavedAddress.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException {
      return [];
    }
  }

  Future<SavedAddress> createAddress({
    required String addressType,
    String? nickname,
    required String city,
    String? society,
    required String flatNumber,
    String? landmark,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    final res = await _api.post(ApiConstants.addresses, data: {
      'addressType': addressType,
      if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
      'city': city,
      if (society != null && society.isNotEmpty) 'society': society,
      'flatNumber': flatNumber,
      if (landmark != null && landmark.isNotEmpty) 'landmark': landmark,
      if (latitude != null && longitude != null)
        'location': {'latitude': latitude, 'longitude': longitude},
      'isDefault': isDefault,
    });
    return SavedAddress.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<SavedAddress> updateAddress(
    String id, {
    required String addressType,
    String? nickname,
    required String city,
    String? society,
    required String flatNumber,
    String? landmark,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    final res = await _api.put('${ApiConstants.addresses}/$id', data: {
      'addressType': addressType,
      'nickname': nickname ?? '',
      'city': city,
      'society': society ?? '',
      'flatNumber': flatNumber,
      'landmark': landmark ?? '',
      if (latitude != null && longitude != null)
        'location': {'latitude': latitude, 'longitude': longitude},
      if (isDefault != null) 'isDefault': isDefault,
    });
    return SavedAddress.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String id) async {
    await _api.delete('${ApiConstants.addresses}/$id');
  }

  Future<void> setDefault(String id) async {
    await _api.patch('${ApiConstants.addresses}/$id/set-default');
  }
}
