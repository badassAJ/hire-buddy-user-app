import 'package:flutter/material.dart';
import '../services/booking_service.dart';

enum BookingStatus {
  initial,
  findingProvider,
  selectingProvider,
  providerAssigned,
  failed,
}

class BookingProvider with ChangeNotifier {
  final BookingService _bookingService = BookingService();

  String? _bookingId;
  String? _serviceName;
  BookingStatus _status = BookingStatus.initial;
  int _timeRemaining = 60;
  int _interestedProviders = 0;
  Map<String, dynamic>? _assignedProvider;
  String? _error;
  bool _isLoading = false;

  String? get bookingId => _bookingId;
  String? get serviceName => _serviceName;
  BookingStatus get status => _status;
  int get timeRemaining => _timeRemaining;
  int get interestedProviders => _interestedProviders;
  Map<String, dynamic>? get assignedProvider => _assignedProvider;
  String? get error => _error;
  bool get isLoading => _isLoading;

  void initBooking({
    required String bookingId,
    required String serviceName,
    required int timeRemaining,
  }) {
    _bookingId = bookingId;
    _serviceName = serviceName;
    _timeRemaining = timeRemaining;
    _status = BookingStatus.findingProvider;
    _interestedProviders = 0;
    _assignedProvider = null;
    _error = null;
    notifyListeners();
  }

  void updateTimeRemaining(int time) {
    _timeRemaining = time;
    notifyListeners();
  }

  void updateInterestedProviders(int count) {
    _interestedProviders = count;
    notifyListeners();
  }

  void setSelectingProvider() {
    _status = BookingStatus.selectingProvider;
    notifyListeners();
  }

  void setProviderAssigned(Map<String, dynamic> provider) {
    _assignedProvider = provider;
    _status = BookingStatus.providerAssigned;
    notifyListeners();
  }

  void setFailed(String error) {
    _status = BookingStatus.failed;
    _error = error;
    notifyListeners();
  }

  void reset() {
    _bookingId = null;
    _serviceName = null;
    _status = BookingStatus.initial;
    _timeRemaining = 60;
    _interestedProviders = 0;
    _assignedProvider = null;
    _error = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getBookingStatus() async {
    if (_bookingId == null) {
      return {'success': false, 'error': 'No booking ID'};
    }
    return await _bookingService.getBookingStatus(_bookingId!);
  }

  Future<Map<String, dynamic>> getBookingDetails() async {
    if (_bookingId == null) {
      return {'success': false, 'error': 'No booking ID'};
    }
    return await _bookingService.getBookingDetails(_bookingId!);
  }

  Future<bool> cancelSearch() async {
    if (_bookingId == null) return false;
    final result = await _bookingService.cancelSearch(_bookingId!);
    if (result['success']) {
      reset();
    }
    return result['success'];
  }
}
