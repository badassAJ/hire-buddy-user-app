import 'package:dio/dio.dart';
import 'api_service.dart';
import '../core/constants/api_constants.dart';

class ServiceService {
  final ApiService _api = ApiService();

  // Get All Categories
  Future<Map<String, dynamic>> getCategories({
    bool includeSubcategories = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (includeSubcategories) {
        queryParams['includeSubcategories'] = 'true';
      }

      final response = await _api.get(
        ApiConstants.categories,
        queryParameters: queryParams,
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to fetch categories',
      };
    }
  }

  // Get Services (with optional filters)
  Future<Map<String, dynamic>> getServices({
    String? categoryId,
    String? search,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (search != null) queryParams['search'] = search;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;

      final response = await _api.get(
        ApiConstants.services,
        queryParameters: queryParams,
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to fetch services',
      };
    }
  }

  // Get Service Details
  Future<Map<String, dynamic>> getServiceDetails(String serviceId) async {
    try {
      final response = await _api.get(
        '${ApiConstants.serviceDetails}/$serviceId',
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to fetch service details',
      };
    }
  }

  // Get Active Banners
  Future<Map<String, dynamic>> getBanners() async {
    try {
      final response = await _api.get(ApiConstants.activeBanners);
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to fetch banners',
      };
    }
  }
}
