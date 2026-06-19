import '../core/constants/api_constants.dart';
import 'api_service.dart';

class DisputeService {
  final _api = ApiService();

  Future<Map<String, dynamic>> raiseDispute({
    required String bookingId,
    required String category,
    required String subject,
    required String description,
  }) async {
    try {
      final res = await _api.post(ApiConstants.disputes, data: {
        'bookingId': bookingId,
        'category': category,
        'subject': subject,
        'description': description,
      });
      return {'success': true, 'data': res.data['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to raise dispute'};
    }
  }

  Future<List<Map<String, dynamic>>> listMyDisputes() async {
    try {
      final res = await _api.get(ApiConstants.disputes);
      final data = res.data;
      if (data['success'] == true) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> getDispute(String disputeId) async {
    try {
      final res = await _api.get('${ApiConstants.disputes}/$disputeId');
      if (res.data['success'] == true) return res.data['data'] as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> replyToDispute(String disputeId, String message) async {
    try {
      final res = await _api.post('${ApiConstants.disputes}/$disputeId/reply', data: {'message': message});
      return {'success': true, 'data': res.data['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send reply'};
    }
  }
}
