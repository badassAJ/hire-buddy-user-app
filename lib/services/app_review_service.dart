import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'api_service.dart';

class AppReviewStatus {
  final bool shouldPrompt;
  final bool alreadyReviewed;
  final int completedBookings;
  final int? currentRating;
  final String? currentComment;

  AppReviewStatus({
    required this.shouldPrompt,
    required this.alreadyReviewed,
    required this.completedBookings,
    this.currentRating,
    this.currentComment,
  });

  factory AppReviewStatus.fromJson(Map<String, dynamic> json) {
    final review = json['review'] as Map<String, dynamic>?;
    return AppReviewStatus(
      shouldPrompt: json['shouldPrompt'] == true,
      alreadyReviewed: json['alreadyReviewed'] == true,
      completedBookings: (json['completedBookings'] ?? 0) as int,
      currentRating: review?['rating'] as int?,
      currentComment: review?['comment'] as String?,
    );
  }
}

class AppReviewService {
  final ApiService _api = ApiService();

  Future<AppReviewStatus?> getStatus() async {
    try {
      final res = await _api.get('/api/v1/user/app-review/should-prompt');
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return AppReviewStatus.fromJson(data);
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> submit({
    required int rating,
    required String comment,
    String? appVersion,
  }) async {
    try {
      await _api.post(
        '/api/v1/user/app-review',
        data: {
          'rating': rating,
          'comment': comment,
          if (appVersion != null) 'appVersion': appVersion,
          'platform': _platform(),
        },
      );
      return true;
    } on DioException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  String _platform() {
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'other';
  }
}
