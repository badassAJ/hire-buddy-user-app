import '../core/constants/api_constants.dart';
import '../models/product_model.dart';
import 'api_service.dart';

class ProductService {
  final _api = ApiService();

  Future<List<Map<String, dynamic>>> getProductCategories() async {
    final res = await _api.get('${ApiConstants.products}/categories');
    final data = res.data;
    if (data['success'] == true) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<ProductModel>> listProducts({String? search, int page = 1, String? categoryId}) async {
    final params = <String, dynamic>{'page': page, 'limit': 10};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (categoryId != null) params['categoryId'] = categoryId;

    final res = await _api.get(ApiConstants.products, queryParameters: params);
    final data = res.data;
    if (data['success'] == true) {
      return (data['data'] as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ProductModel> getProduct(String id) async {
    final res = await _api.get('${ApiConstants.products}/$id');
    final data = res.data;
    if (data['success'] == true) {
      return ProductModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['error'] ?? 'Failed to fetch product');
  }

  Future<AddressModel> createAddress({
    required String city,
    String? state,
    required String flatNumber,
    String? society,
    String? block,
    String? tower,
    String? landmark,
    bool isDefault = true,
  }) async {
    final res = await _api.post(ApiConstants.addresses, data: {
      'city': city,
      if (state != null && state.isNotEmpty) 'state': state,
      'flatNumber': flatNumber,
      if (society != null && society.isNotEmpty) 'society': society,
      if (block != null && block.isNotEmpty) 'block': block,
      if (tower != null && tower.isNotEmpty) 'tower': tower,
      if (landmark != null && landmark.isNotEmpty) 'landmark': landmark,
      'isDefault': isDefault,
    });
    final data = res.data;
    if (data['success'] == true) {
      return AddressModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? 'Failed to save address');
  }

  Future<List<AddressModel>> getAddresses() async {
    final res = await _api.get(ApiConstants.addresses);
    final data = res.data;
    final raw = data['data'];
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (raw is Map<String, dynamic>) {
      final addr = AddressModel.fromJson(raw);
      if (addr.id.isNotEmpty || addr.city.isNotEmpty) return [addr];
    }
    return [];
  }

  Future<void> deleteAddress(String id) async {
    final res = await _api.delete('${ApiConstants.addresses}/$id');
    if (res.data['success'] != true) {
      throw Exception(res.data['message'] ?? 'Failed to delete address');
    }
  }

  Future<void> setDefaultAddress(String id) async {
    final res = await _api.patch('${ApiConstants.addresses}/$id/set-default', data: {});
    if (res.data['success'] != true) {
      throw Exception(res.data['message'] ?? 'Failed to set default');
    }
  }

  Future<ProductOrder> placeOrder({
    required List<Map<String, dynamic>> items,
    required String addressId,
    String paymentMethod = 'cod',
    String? vendorCouponCode,
  }) async {
    final res = await _api.post(ApiConstants.productOrders, data: {
      'items': items,
      'addressId': addressId,
      'paymentMethod': paymentMethod,
      if (vendorCouponCode != null) 'vendorCouponCode': vendorCouponCode,
    });
    final data = res.data;
    if (data['success'] == true) {
      return ProductOrder.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['error'] ?? 'Failed to place order');
  }

  Future<List<ProductOrder>> getMyOrders({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;

    final res = await _api.get(ApiConstants.productOrders, queryParameters: params);
    final data = res.data;
    if (data['success'] == true) {
      return (data['data'] as List)
          .map((e) => ProductOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ProductOrder> getOrderDetail(String id) async {
    final res = await _api.get('${ApiConstants.productOrders}/$id');
    final data = res.data;
    if (data['success'] == true) {
      return ProductOrder.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['error'] ?? 'Failed to fetch order');
  }

  Future<void> cancelOrder(String id, String reason) async {
    final res = await _api.patch('${ApiConstants.productOrders}/$id/cancel',
        data: {'reason': reason});
    final data = res.data;
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to cancel order');
    }
  }

  Future<void> submitProductReviews(String orderId, List<Map<String, dynamic>> reviews) async {
    final res = await _api.post(ApiConstants.productReviews, data: {
      'orderId': orderId,
      'reviews': reviews,
    });
    final data = res.data;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to submit reviews');
    }
  }

  Future<List<String>> getReviewedProductIds(String orderId) async {
    try {
      final res = await _api.get('${ApiConstants.productReviews}/order/$orderId');
      final data = res.data;
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((r) => r['productId'].toString())
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> getProductReviews(String productId, {int page = 1}) async {
    final res = await _api.get(
      '${ApiConstants.productReviews}/product/$productId',
      queryParameters: {'page': page, 'limit': 10},
    );
    final data = res.data;
    if (data['success'] == true) {
      return {
        'reviews': data['data'] as List,
        'meta': data['meta'] as Map<String, dynamic>,
      };
    }
    return {'reviews': [], 'meta': {}};
  }
}
