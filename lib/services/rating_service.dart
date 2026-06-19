import 'package:dio/dio.dart';
import 'api_service.dart';
import '../core/constants/api_constants.dart';

class RatingService {
  final ApiService _api = ApiService();

  // Submit Rating & Review
  Future<Map<String, dynamic>> submitRating({
    required String bookingId,
    required String providerId,
    required int rating,
    String? review,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.submitRating,
        data: {
          'bookingId': bookingId,
          'providerId': providerId,
          'rating': rating,
          if (review != null) 'review': review,
        },
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to submit rating',
      };
    }
  }
}
