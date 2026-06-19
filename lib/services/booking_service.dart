import 'package:dio/dio.dart';
import 'api_service.dart';
import '../core/constants/api_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Booking modes — passed as [bookingMode] so the backend knows the intent.
// ─────────────────────────────────────────────────────────────────────────────
enum BookingMode { instant, scheduled, monthlyPackage }

extension BookingModeX on BookingMode {
  String get value {
    switch (this) {
      case BookingMode.instant:
        return 'instant';
      case BookingMode.scheduled:
        return 'scheduled';
      case BookingMode.monthlyPackage:
        return 'monthly_package';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Combo item payload — used for instant / combo bookings.
// Each item maps to one category + duration chosen by the user.
// ─────────────────────────────────────────────────────────────────────────────
class ComboItemPayload {
  final String categoryId;
  final int hours;
  final double subtotal;

  const ComboItemPayload({
    required this.categoryId,
    required this.hours,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'hours': hours,
    'subtotal': subtotal,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Monthly package payload — used for monthly package bookings.
// Extend fields here as your backend spec evolves.
// ─────────────────────────────────────────────────────────────────────────────
class MonthlyPackagePayload {
  final String categoryId;
  final int sessionsPerWeek;
  final int hoursPerSession;
  final int durationMonths;

  const MonthlyPackagePayload({
    required this.categoryId,
    required this.sessionsPerWeek,
    required this.hoursPerSession,
    required this.durationMonths,
  });

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'sessionsPerWeek': sessionsPerWeek,
    'hoursPerSession': hoursPerSession,
    'durationMonths': durationMonths,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// BookingService
// ─────────────────────────────────────────────────────────────────────────────
class BookingService {
  final ApiService _api = ApiService();

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATE BOOKING
  //
  // Supports all 3 booking modes in one method.
  // Only fields relevant to the active mode need to be passed;
  // everything else is null and omitted from the request body.
  //
  // ── Instant (BookNow) ─────────────────────────────────────────────────────
  //   createBooking(
  //     mode:          BookingMode.instant,
  //     paymentMethod: 'online',
  //     addressId:     '...',
  //     buddyId:       '...',
  //     comboItems:    [...],
  //   )
  //
  // ── Scheduled ────────────────────────────────────────────────────────────
  //   createBooking(
  //     mode:          BookingMode.scheduled,
  //     serviceId:     '...',
  //     scheduledDate: '2025-07-01',
  //     timeSlot:      '09:00 AM - 11:00 AM',
  //     paymentMethod: 'online',
  //     addressId:     '...',
  //   )
  //
  // ── Monthly Package ───────────────────────────────────────────────────────
  //   createBooking(
  //     mode:           BookingMode.monthlyPackage,
  //     paymentMethod:  'online',
  //     addressId:      '...',
  //     monthlyPackage: MonthlyPackagePayload(...),
  //   )
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> createBooking({
    // ── Mode (required) ──────────────────────────────────────────────────────
    required BookingMode mode,

    // ── Payment (required) ───────────────────────────────────────────────────
    required String paymentMethod,

    // ── Address (required for all modes) ─────────────────────────────────────
    String? addressId,

    // ── Scheduled mode fields ─────────────────────────────────────────────────
    String? serviceId, // single-service ID for scheduled bookings
    String? scheduledDate, // ISO date string e.g. '2025-07-01'
    String? timeSlot, // e.g. '09:00 AM - 11:00 AM'
    // ── Instant / combo fields ────────────────────────────────────────────────
    List<ComboItemPayload>? comboItems, // one entry per selected category
    String? buddyId, // pre-selected buddy from BookNow step 3
    // ── Monthly package fields ────────────────────────────────────────────────
    MonthlyPackagePayload? monthlyPackage,

    // ── Shared optional fields ────────────────────────────────────────────────
    String? promoCode,
    String? couponCode,
    double? discountAmount,
  }) async {
    try {
      // Build request body — only include keys the backend needs for this mode
      final Map<String, dynamic> body = {
        'bookingMode': mode.value,
        'paymentMethod': paymentMethod,
        'immediate': mode == BookingMode.instant,

        // Address
        if (addressId != null && addressId.isNotEmpty) 'addressId': addressId,

        // ── Scheduled ──────────────────────────────────────────────────────
        if (serviceId != null && serviceId.isNotEmpty) 'serviceId': serviceId,
        if (scheduledDate != null && scheduledDate.isNotEmpty)
          'scheduledDate': scheduledDate,
        if (timeSlot != null && timeSlot.isNotEmpty) 'timeSlot': timeSlot,

        // ── Instant / combo ────────────────────────────────────────────────
        if (comboItems != null && comboItems.isNotEmpty)
          'comboItems': comboItems.map((e) => e.toJson()).toList(),
        if (buddyId != null && buddyId.isNotEmpty) 'buddyId': buddyId,

        // ── Monthly package ────────────────────────────────────────────────
        if (monthlyPackage != null) 'monthlyPackage': monthlyPackage.toJson(),

        // ── Discounts ──────────────────────────────────────────────────────
        if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
        if (couponCode != null && couponCode.isNotEmpty)
          'couponCode': couponCode,
        if (discountAmount != null) 'discountAmount': discountAmount,
      };

      final response = await _api.post(ApiConstants.createBooking, data: body);
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Failed to create booking',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET BOOKING STATUS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getBookingStatus(String bookingId) async {
    try {
      final response = await _api.get(
        '${ApiConstants.bookingDetails}/$bookingId/status',
      );
      return {'success': true, 'data': response.data['data']};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Failed to get status',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CANCEL SEARCH
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> cancelSearch(String bookingId) async {
    try {
      final response = await _api.post(
        '${ApiConstants.bookingDetails}/$bookingId/cancel-search',
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Failed to cancel search',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET MY BOOKINGS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getMyBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null) queryParams['status'] = status;

      final response = await _api.get(
        ApiConstants.myBookings,
        queryParameters: queryParams,
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Failed to fetch bookings',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET BOOKING DETAILS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    try {
      final response = await _api.get(
        '${ApiConstants.bookingDetails}/$bookingId',
      );
      return {'success': true, 'data': response.data['data']};
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data['message'] ?? 'Failed to fetch booking details',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET BOOKING REVIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getBookingReview(String bookingId) async {
    try {
      final response = await _api.get(
        '${ApiConstants.submitRating}/booking/$bookingId',
      );
      final data = response.data as Map<String, dynamic>;
      return {'success': true, 'data': data['data']};
    } on DioException {
      return {'success': false, 'data': null};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBMIT RATING
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> submitRating({
    required String bookingId,
    required int rating,
    int? serviceRating,
    String reviewText = '',
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.submitRating,
        data: {
          'bookingId': bookingId,
          'ratings': {
            'overall': rating,
            if (serviceRating != null) 'quality': serviceRating,
          },
          'reviewText': reviewText,
        },
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Failed to submit rating',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESCHEDULE BOOKING
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> rescheduleBooking({
    required String bookingId,
    required String scheduledDate,
    required String timeSlot,
  }) async {
    try {
      final response = await _api.post(
        '${ApiConstants.myBookings}/$bookingId/reschedule',
        data: {'scheduledDate': scheduledDate, 'timeSlot': timeSlot},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Failed to reschedule booking',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CANCEL BOOKING
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    String? reason,
    String? reasonCategory,
  }) async {
    try {
      final response = await _api.post(
        '${ApiConstants.cancelBooking}/$bookingId/cancel',
        data: {
          if (reason != null) 'reason': reason,
          if (reasonCategory != null) 'reasonCategory': reasonCategory,
        },
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Failed to cancel booking',
      };
    }
  }
}
