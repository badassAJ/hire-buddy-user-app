import '../core/constants/api_constants.dart';
import 'api_service.dart';

class CouponService {
  final _api = ApiService();

  Future<Map<String, dynamic>> validate({
    required String code,
    required double orderAmount,
  }) async {
    try {
      final res = await _api.post(
        ApiConstants.validateCoupon,
        data: {'code': code.trim().toUpperCase(), 'orderAmount': orderAmount},
      );
      final data = res.data as Map<String, dynamic>;

      if (data['success'] == true) {
        return {
          'success': true,
          'coupon': Map<String, dynamic>.from(data['coupon'] ?? const {}),
          'discountAmount': (data['discountAmount'] as num?)?.toDouble() ?? 0,
          'finalAmount':
              (data['finalAmount'] as num?)?.toDouble() ?? orderAmount,
        };
      }

      return {
        'success': false,
        'message': data['error'] ?? data['message'] ?? 'Invalid coupon code',
      };
    } catch (e) {
      return {'success': false, 'message': _extractMessage(e)};
    }
  }

  String _extractMessage(dynamic e) {
    try {
      final resp = (e as dynamic).response?.data;
      if (resp is Map) {
        return (resp['error'] ?? resp['message'] ?? 'Invalid coupon code')
            .toString();
      }
    } catch (_) {}
    return 'Invalid coupon code';
  }
}
