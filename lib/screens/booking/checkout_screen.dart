import 'package:flutter/material.dart';
import 'package:hirebuddy/core/theme/app_colors.dart';
import 'package:hirebuddy/services/address_service.dart';
import 'package:hirebuddy/services/booking_service.dart';
import 'package:hirebuddy/services/coupon_service.dart';
import 'package:hirebuddy/services/user_service.dart';
import 'package:hirebuddy/services/api_service.dart';
import 'package:hirebuddy/services/razorpay_service.dart';
import 'package:hirebuddy/models/user_model.dart' hide AddressModel;
import 'package:intl/intl.dart';
import 'package:hirebuddy/models/product_model.dart' show AddressModel;
import 'finding_provider_screen.dart';
import 'booking_summary_screen.dart';
import 'saved_address_picker_sheet.dart';

class CheckoutScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final double price;

  const CheckoutScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.price,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _userService = UserService();
  final _addressService = AddressService();
  final _bookingService = BookingService();
  final _couponService = CouponService();
  final _api = ApiService();
  final _razorpay = RazorpayService();

  UserModel? _user;
  AddressModel? _selectedAddress;
  bool _isLoading = true;
  bool _isBooking = false;

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String _paymentMethod = 'online';

  final _couponController = TextEditingController();
  Map<String, dynamic>? _appliedCoupon;
  double _discountAmount = 0;
  bool _couponLoading = false;
  String? _couponError;

  final List<String> _timeSlots = [
    '09:00 AM - 11:00 AM',
    '11:00 AM - 01:00 PM',
    '01:00 PM - 03:00 PM',
    '03:00 PM - 05:00 PM',
    '05:00 PM - 07:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _razorpay.dispose();
    _couponController.dispose();
    super.dispose();
  }

  double get _finalTotal =>
      (_total - _discountAmount).clamp(0.0, double.infinity);

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _couponLoading = true;
      _couponError = null;
    });
    final result = await _couponService.validate(
      code: code,
      orderAmount: _total,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      final coupon = result['coupon'] as Map<String, dynamic>? ?? {};
      setState(() {
        _appliedCoupon = coupon;
        _discountAmount = (result['discountAmount'] as num?)?.toDouble() ?? 0;
        _couponLoading = false;
        _couponError = null;
      });
    } else {
      setState(() {
        _appliedCoupon = null;
        _discountAmount = 0;
        _couponLoading = false;
        _couponError = result['message'] as String?;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _discountAmount = 0;
      _couponError = null;
      _couponController.clear();
    });
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _userService.getProfile(),
        _addressService.listAddresses(),
      ]);
      if (!mounted) return;
      final profileResult = results[0] as Map<String, dynamic>;
      final addresses = results[1] as List;
      setState(() {
        if (profileResult['success'] == true) {
          _user = UserModel.fromJson(profileResult['data']['data']);
        }
        // Auto-select default address
        final defaultSaved = addresses.cast<dynamic>().firstWhere(
          (a) => a.isDefault == true,
          orElse: () => addresses.isNotEmpty ? addresses.first : null,
        );
        if (defaultSaved != null) {
          _selectedAddress = AddressModel(
            id: defaultSaved.id,
            fullAddress: [
              if (defaultSaved.flatNumber?.isNotEmpty == true)
                defaultSaved.flatNumber!,
              if (defaultSaved.society?.isNotEmpty == true)
                defaultSaved.society!,
            ].join(', '),
            city: defaultSaved.city,
            state: '',
            flatNumber: defaultSaved.flatNumber,
            society: defaultSaved.society,
            landmark: defaultSaved.landmark,
            addressType: defaultSaved.addressType,
            nickname: defaultSaved.nickname,
            isDefault: defaultSaved.isDefault,
            latitude: defaultSaved.latitude,
            longitude: defaultSaved.longitude,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openAddressPicker() async {
    final picked = await showSavedAddressPicker(context);
    if (picked != null && mounted) {
      setState(() => _selectedAddress = picked);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  double get _total => widget.price;

  Future<void> _confirmBooking() async {
    if (_selectedDate == null) {
      _showError('Please select a date');
      return;
    }
    if (_selectedTimeSlot == null) {
      _showError('Please select a time slot');
      return;
    }
    if (_selectedAddress == null) {
      _showError('Please select a delivery address');
      return;
    }

    setState(() => _isBooking = true);
    try {
      final result = await _bookingService.createBooking(
        serviceId: widget.serviceId,
        scheduledDate: _selectedDate!.toIso8601String(),
        timeSlot: _selectedTimeSlot!,
        paymentMethod: 'online',
        mode: BookingMode.instant,
        couponCode: _appliedCoupon != null
            ? _appliedCoupon!['code'] as String?
            : null,
        discountAmount: _appliedCoupon != null ? _discountAmount : null,
        addressId: _selectedAddress!.id,
      );

      if (!result['success'] || !mounted) {
        _showError(result['error'] ?? 'Failed to create booking');
        return;
      }

      final bookingData = result['data']['data'] ?? result['data'];
      final bookingId = bookingData['_id'] as String? ?? '';

      if (bookingData['bookingStatus'] == 'failed') {
        _showError(
          bookingData['cancellation']?['reason'] ?? 'No providers available',
        );
        return;
      }

      await _handleOnlinePayment(bookingId);
    } catch (e) {
      _showError('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  Future<void> _handleOnlinePayment(String bookingId) async {
    // Step 1: Create Razorpay order on backend
    late Map<String, dynamic> payData;
    try {
      final res = await _api.post(
        '/api/v1/user/payment/create-order',
        data: {'bookingId': bookingId, 'paymentMethod': 'online'},
      );
      if (res.data['success'] != true) {
        throw Exception(res.data['message'] ?? 'Failed to initiate payment');
      }
      payData = Map<String, dynamic>.from(res.data['data']);
    } catch (e) {
      await _cancelBookingQuietly(bookingId);
      _showError('Could not initiate payment. Please try again.');
      return;
    }

    if (!mounted) return;

    // Step 2: Open Razorpay checkout
    final contact = _buildContact();
    final result = await _razorpay.openCheckout(
      keyId: payData['keyId'] as String,
      orderId: payData['orderId'] as String,
      amountPaise: payData['amount'] as int,
      description: widget.serviceName,
      contact: contact,
      email: _user?.email ?? '',
    );

    if (!mounted) return;

    if (result.isSuccess) {
      // Step 3: Verify payment with backend
      setState(() => _isBooking = true);
      try {
        final verifyRes = await _api.post(
          '/api/v1/user/payment/verify',
          data: {
            'bookingId': bookingId,
            'razorpayOrderId': result.orderId,
            'razorpayPaymentId': result.paymentId,
            'razorpaySignature': result.signature,
          },
        );

        if (verifyRes.data['success'] == true) {
          if (!mounted) return;
          final updatedBooking =
              verifyRes.data['data'] as Map<String, dynamic>? ?? {};
          final bookingStatus =
              updatedBooking['bookingStatus'] as String? ?? '';
          if (bookingStatus == 'searching_provider') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => FindingProviderScreen(
                  bookingId: bookingId,
                  serviceName: widget.serviceName,
                ),
              ),
            );
          } else {
            final addrStr = _selectedAddress != null
                ? [
                    if (_selectedAddress!.fullAddress.isNotEmpty)
                      _selectedAddress!.fullAddress,
                    if (_selectedAddress!.city.isNotEmpty)
                      _selectedAddress!.city,
                  ].join(', ')
                : null;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => BookingSummaryScreen(
                  bookingId: bookingId,
                  serviceName: widget.serviceName,
                  provider: null,
                  scheduledTime: _selectedTimeSlot,
                  address: addrStr,
                ),
              ),
            );
          }
        } else {
          // Payment succeeded but verification failed — don't cancel, webhook will fix it
          _showVerificationError(bookingId);
        }
      } catch (e) {
        // Network error during verify — payment may have gone through
        _showVerificationError(bookingId);
      } finally {
        if (mounted) setState(() => _isBooking = false);
      }
    } else if (result.isCancelled) {
      await _cancelBookingQuietly(bookingId);
      _showError('Payment cancelled');
    } else if (result.isFailed) {
      await _cancelBookingQuietly(bookingId);
      final msg = result.message ?? 'Payment failed';
      _showError(_cleanRazorpayError(msg));
    }
    // External wallet: keep booking as-is, show info
    else {
      _showInfo(
        'Payment via ${result.message ?? 'external wallet'}. We\'ll confirm once received.',
      );
    }
  }

  void _navigateAfterCashBooking(Map<String, dynamic> bookingData) {
    if (bookingData['isSearching'] == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FindingProviderScreen(
            bookingId: bookingData['_id'],
            serviceName: widget.serviceName,
          ),
        ),
      );
    } else if (bookingData['bookingStatus'] == 'pending') {
      final addrStr = _selectedAddress != null
          ? [
              if (_selectedAddress!.fullAddress.isNotEmpty)
                _selectedAddress!.fullAddress,
              if (_selectedAddress!.city.isNotEmpty) _selectedAddress!.city,
            ].join(', ')
          : null;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingSummaryScreen(
            bookingId: bookingData['_id'] ?? '',
            serviceName: widget.serviceName,
            provider: null,
            scheduledTime: _selectedTimeSlot,
            address: addrStr,
          ),
        ),
      );
    } else {
      Navigator.pop(context);
      _showSuccess('Booking confirmed!');
    }
  }

  // Build E.164-style contact for Razorpay prefill: +91XXXXXXXXXX
  String _buildContact() {
    final mobile = _user?.phone ?? '';
    if (mobile.isEmpty) return '';
    if (mobile.startsWith('+')) return mobile;
    final cc = ('+91').replaceAll('+', '');
    return '+$cc$mobile';
  }

  // Cancel booking silently — user already sees a relevant error message
  Future<void> _cancelBookingQuietly(String bookingId) async {
    try {
      await _api.post(
        '/api/v1/user/bookings/$bookingId/cancel',
        data: {'reason': 'Payment not completed', 'reasonCategory': 'other'},
      );
    } catch (_) {}
  }

  // Verify failed but payment may have gone through — do NOT cancel
  void _showVerificationError(String bookingId) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Payment Received',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Your payment was processed but we couldn\'t confirm it instantly. '
          'Booking ID: $bookingId\n\nPlease check My Bookings in a few minutes or contact support.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Go to Home',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _cleanRazorpayError(String msg) {
    // Remove technical prefixes Razorpay may include
    if (msg.contains('BAD_REQUEST_ERROR'))
      return 'Payment declined by bank. Please try another card.';
    if (msg.contains('GATEWAY_ERROR'))
      return 'Payment gateway error. Please try again.';
    if (msg.contains('SERVER_ERROR'))
      return 'Payment server error. Please try again.';
    return msg.length > 80 ? '${msg.substring(0, 80)}...' : msg;
  }

  void _showError(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  void _showSuccess(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  void _showInfo(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m),
      backgroundColor: AppColors.info,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Review Booking',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 22,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 24),
            _buildServicePreview(),
            const SizedBox(height: 40),
            _buildSectionLabel('SERVICE ADDRESS'),
            _buildAddressCard(),
            const SizedBox(height: 32),
            _buildSectionLabel('SCHEDULE SESSION'),
            _buildScheduleCard(),
            const SizedBox(height: 32),
            // _buildSectionLabel('PAYMENT METHOD'),
            // _buildPaymentOptions(),
            // _buildCouponSection(),
            _buildSectionLabel('BILLING SUMMARY'),
            _buildPriceBreakdown(),
            const SizedBox(height: 160),
          ],
        ),
        _buildBottomAction(),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.grey,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildServicePreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.home_repair_service_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.serviceName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Standard Plan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${widget.price.round()}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    final addr = _selectedAddress;
    if (addr == null) {
      return GestureDetector(
        onTap: _openAddressPicker,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_location_alt_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Select service address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: _openAddressPicker,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    addr.displayLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (addr.fullAddress.isNotEmpty) addr.fullAddress,
                      if (addr.city.isNotEmpty) addr.city,
                    ].join(', '),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Column(
      children: [
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 16),
                Text(
                  _selectedDate == null
                      ? 'Pin a date'
                      : DateFormat('EEEE, dd MMM').format(_selectedDate!),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.expand_more_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _timeSlots.map((slot) {
              final isS = _selectedTimeSlot == slot;
              return GestureDetector(
                onTap: () => setState(() => _selectedTimeSlot = slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isS ? AppColors.primary : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isS ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPayItem(
                'cash',
                'Cash',
                Icons.payments_rounded,
                'Pay after service',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPayItem(
                'online',
                'Online',
                Icons.account_balance_wallet_rounded,
                'Pay now securely',
              ),
            ),
          ],
        ),
        if (_paymentMethod == 'online') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: Color(0xFF16A34A),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Secured by Razorpay · UPI, Cards, Net Banking & more',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPayItem(String v, String l, IconData i, String subtitle) {
    final isS = _paymentMethod == v;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isS
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isS ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(i, color: isS ? AppColors.primary : Colors.grey, size: 24),
            const SizedBox(height: 6),
            Text(
              l,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isS ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isS ? AppColors.primary : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_offer_rounded,
                  size: 17, color: AppColors.textPrimary),
              SizedBox(width: 7),
              Text('Coupon',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          if (_appliedCoupon != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _appliedCoupon!['code'] as String? ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              fontSize: 13,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'You save ₹${_discountAmount.round()}',
                          style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _removeCoupon,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.close,
                          size: 15, color: Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      hintStyle: const TextStyle(
                          color: AppColors.grey400,
                          fontSize: 14,
                          fontWeight: FontWeight.w400),
                      filled: true,
                      fillColor: AppColors.grey50,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.grey200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: _couponError != null
                                ? AppColors.error
                                : AppColors.grey200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _applyCoupon(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _couponLoading ? null : _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _couponLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Apply',
                            style:
                                TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            if (_couponError != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 14, color: AppColors.error),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(_couponError!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _priceRow('Service Fee', _total),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 8),
            _priceRow('Coupon Discount', -_discountAmount, isDiscount: true),
          ],
          if (_paymentMethod == 'online') ...[
            const SizedBox(height: 8),
            _priceRow('Payment Mode', 0, label2: 'Online / UPI'),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          _priceRow('Total Payable', _finalTotal, isB: true),
          const SizedBox(height: 6),
          const Text(
            'Inclusive of all taxes & GST',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String l,
    double a, {
    bool isB = false,
    String? label2,
    bool isDiscount = false,
  }) {
    final valueText =
        label2 ?? (isDiscount ? '-₹${a.abs().round()}' : '₹${a.round()}');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l,
          style: TextStyle(
            fontSize: isB ? 16 : 13,
            fontWeight: isB ? FontWeight.w900 : FontWeight.w700,
            color: isB ? AppColors.textPrimary : Colors.grey,
          ),
        ),
        Text(
          valueText,
          style: TextStyle(
            fontSize: isB ? 20 : 13,
            fontWeight: isB ? FontWeight.w900 : FontWeight.w800,
            color: isDiscount
                ? Colors.green
                : (isB ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    final hasAddress = _selectedAddress != null;
    final label = 'Pay Securely · ₹${_finalTotal.round()}';

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        color: Colors.white,
        child: GestureDetector(
          onTap: _isBooking
              ? null
              : (hasAddress ? _confirmBooking : _openAddressPicker),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              color: hasAddress ? AppColors.primary : Colors.black,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: _isBooking
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : hasAddress
                  ? Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_location_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Add Address',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
