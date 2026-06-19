import '../core/constants/api_constants.dart';
import 'api_service.dart';

class PromoService {
  final _api = ApiService();

  /// Returns { success, data: { code, discountAmount, finalAmount, description, ... } }
  /// or { success: false, message }
  Future<Map<String, dynamic>> validatePromo({
    required String code,
    required double amount,
  }) async {
    try {
      final res = await _api.post(ApiConstants.validatePromo, data: {
        'code': code.trim().toUpperCase(),
        'amount': amount,
      });
      final data = res.data;
      if (data['success'] == true) {
        return {'success': true, 'data': data['data'] as Map<String, dynamic>};
      }
      return {'success': false, 'message': data['message'] ?? 'Invalid promo code'};
    } catch (e) {
      final msg = _extractMessage(e);
      return {'success': false, 'message': msg};
    }
  }

  String _extractMessage(dynamic e) {
    try {
      final resp = (e as dynamic).response?.data;
      if (resp is Map && resp['message'] != null) return resp['message'] as String;
    } catch (_) {}
    return 'Invalid promo code';
  }
}
