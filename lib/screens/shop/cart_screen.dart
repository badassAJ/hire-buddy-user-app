import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart' as user_models;
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/address_service.dart';
import '../../core/constants/api_constants.dart';
import '../../services/product_service.dart';
import '../../services/api_service.dart';
import '../../services/razorpay_service.dart';
import '../auth/login_screen.dart';
import '../booking/saved_address_picker_sheet.dart';
import 'my_orders_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _productService = ProductService();
  final _addressService = AddressService();
  final _api = ApiService();
  final _razorpay = RazorpayService();

  AddressModel? _selectedAddress;
  bool _isLoadingAddresses = true;
  bool _isPlacingOrder = false;
  String _paymentMethod = 'online';

  int _deliveryCharge = 0;
  bool _isFetchingDelivery = false;

  // Vendor coupon state
  Map<String, dynamic>? _appliedVendorCoupon;
  double _vendorDiscountAmount = 0.0;
  bool _vendorCouponLoading = false;
  String? _vendorCouponError;
  List<Map<String, dynamic>> _availableVendorCoupons = [];
  final TextEditingController _vendorCouponController = TextEditingController();

  CartProvider? _cartProvider;
  double _lastCouponLoadTotal = -1;
  String? _lastDeliveryVendorId;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cartProvider = context.read<CartProvider>();
      if (_cartProvider!.vendorId != null && _cartProvider!.vendorId!.isNotEmpty) {
        _lastCouponLoadTotal = _cartProvider!.totalAmount;
        _loadVendorCoupons(_cartProvider!.vendorId!, _cartProvider!.totalAmount);
      }
      _cartProvider?.addListener(_onCartChanged);
    });
  }

  void _onCartChanged() {
    final cart = _cartProvider;
    if (cart == null || cart.vendorId == null || cart.vendorId!.isEmpty) return;
    final newTotal = cart.totalAmount;

    // Fetch delivery charge when vendor becomes available for first time
    // (handles case where cart loads from storage after address HTTP call completes)
    if (_selectedAddress != null && cart.vendorId != _lastDeliveryVendorId) {
      _lastDeliveryVendorId = cart.vendorId;
      _fetchDeliveryCharge(_selectedAddress!.id, cart.vendorId!);
    }

    if ((newTotal - _lastCouponLoadTotal).abs() > 0.01) {
      _lastCouponLoadTotal = newTotal;
      _loadVendorCoupons(cart.vendorId!, newTotal);
    }
    if (_appliedVendorCoupon != null) {
      final minVal = (_appliedVendorCoupon!['minOrderValue'] as num?)?.toDouble() ?? 0;
      if (newTotal < minVal) _removeVendorCoupon();
    }
  }

  @override
  void dispose() {
    _cartProvider?.removeListener(_onCartChanged);
    _razorpay.dispose();
    _vendorCouponController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    try {
      final saved = await _addressService.listAddresses();
      if (!mounted) return;
      final defaultSaved = saved.isNotEmpty
          ? saved.firstWhere((a) => a.isDefault, orElse: () => saved.first)
          : null;
      setState(() {
        if (defaultSaved != null) {
          _selectedAddress = AddressModel(
            id: defaultSaved.id,
            fullAddress: [
              if (defaultSaved.flatNumber?.isNotEmpty == true) defaultSaved.flatNumber!,
              if (defaultSaved.society?.isNotEmpty == true) defaultSaved.society!,
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
        _isLoadingAddresses = false;
      });
      if (!mounted) return;
      if (_selectedAddress != null) {
        final cart = context.read<CartProvider>();
        if (cart.vendorId != null && cart.vendorId!.isNotEmpty) {
          _lastDeliveryVendorId = cart.vendorId;
          _fetchDeliveryCharge(_selectedAddress!.id, cart.vendorId!);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingAddresses = false);
    }
  }

  Future<void> _fetchDeliveryCharge(String addressId, String vendorId) async {
    if (addressId.isEmpty || vendorId.isEmpty) return;
    setState(() => _isFetchingDelivery = true);
    try {
      final res = await _api.get(
        ApiConstants.productOrderEstimateDelivery,
        queryParameters: {'addressId': addressId, 'vendorId': vendorId},
      );
      if (res.data['success'] == true && mounted) {
        final charge = (res.data['data']['deliveryCharge'] as num?)?.toInt() ?? 0;
        setState(() => _deliveryCharge = charge);
      }
    } catch (e) {
      debugPrint('fetchDeliveryCharge error: $e');
    } finally {
      if (mounted) setState(() => _isFetchingDelivery = false);
    }
  }

  Future<void> _loadVendorCoupons(String providerId, double subtotal) async {
    try {
      final res = await _api.get(
        '${ApiConstants.vendorCouponsForUser}/$providerId?orderAmount=${subtotal.round()}',
      );
      if (res.data['success'] == true && mounted) {
        setState(() {
          _availableVendorCoupons =
              List<Map<String, dynamic>>.from(res.data['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('loadVendorCoupons error: $e');
    }
  }

  Future<void> _applyVendorCoupon(String code, String providerId, double subtotal) async {
    if (code.trim().isEmpty) return;
    if (!mounted) return;
    setState(() {
      _vendorCouponLoading = true;
      _vendorCouponError = null;
    });
    try {
      final res = await _api.post(
        ApiConstants.validateVendorCoupon,
        data: {
          'code': code.trim().toUpperCase(),
          'providerId': providerId,
          'orderAmount': subtotal.round(),
        },
      );
      if (res.data['success'] == true && mounted) {
        final coupon = Map<String, dynamic>.from(res.data['coupon'] ?? {});
        coupon['code'] = code.trim().toUpperCase();
        setState(() {
          _appliedVendorCoupon = coupon;
          _vendorDiscountAmount =
              (res.data['discountAmount'] as num?)?.toDouble() ?? 0.0;
          _vendorCouponLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to apply coupon';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map) {
            errorMsg = (data['error'] ?? data['message'] ?? errorMsg).toString();
          }
        }
        setState(() {
          _vendorCouponError = errorMsg;
          _vendorCouponLoading = false;
        });
      }
    }
  }

  void _removeVendorCoupon() {
    setState(() {
      _appliedVendorCoupon = null;
      _vendorDiscountAmount = 0.0;
      _vendorCouponError = null;
      _vendorCouponController.clear();
    });
  }

  Future<void> _placeOrder(CartProvider cart) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final effectiveAddressId = _selectedAddress?.id;
    if (effectiveAddressId == null || effectiveAddressId.isEmpty) {
      _showError('Please select a delivery address');
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      await _placeOnlineOrder(cart, effectiveAddressId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      _showError('Something went wrong. Please try again.');
    }
  }

  Future<void> _placeCodOrder(CartProvider cart, String addressId) async {
    try {
      final order = await _productService.placeOrder(
        items: cart.toOrderItems(),
        addressId: addressId,
        paymentMethod: 'cod',
        vendorCouponCode: _appliedVendorCoupon?['code'] as String?,
      );
      if (!mounted) return;
      setState(() => _deliveryCharge = (order.pricing?.deliveryCharge as num?)?.toInt() ?? 0);
      cart.clearCart();
      setState(() => _isPlacingOrder = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
      );
      _showSuccess('Order placed successfully!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      _showError('Failed to place order: $e');
    }
  }

  Future<void> _placeOnlineOrder(CartProvider cart, String addressId) async {
    // Step 1: Create the order in pending state
    late String productOrderId;
    try {
      final order = await _productService.placeOrder(
        items: cart.toOrderItems(),
        addressId: addressId,
        paymentMethod: 'online',
        vendorCouponCode: _appliedVendorCoupon?['code'] as String?,
      );
      productOrderId = order.id;
      setState(() => _deliveryCharge = (order.pricing?.deliveryCharge as num?)?.toInt() ?? 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      _showError('Failed to create order. Please try again.');
      return;
    }

    // Step 2: Create Razorpay order
    late Map<String, dynamic> payData;
    try {
      final res = await _api.post(
        '/api/v1/user/orders/$productOrderId/payment/create-order',
      );
      if (res.data['success'] != true) {
        throw Exception(res.data['message'] ?? 'Failed to initiate payment');
      }
      payData = Map<String, dynamic>.from(res.data['data']);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      await _cancelOrderQuietly(productOrderId);
      _showError('Could not initiate payment. Please try again.');
      return;
    }

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    // Step 3: Open Razorpay
    final user = context.read<AuthProvider>().currentUser;
    final contact = _buildContact(user);
    final result = await _razorpay.openCheckout(
      keyId: payData['keyId'] as String,
      orderId: payData['orderId'] as String,
      amountPaise: payData['amount'] as int,
      description: 'Product Order',
      contact: contact,
      email: user?.email ?? '',
    );

    if (!mounted) return;

    if (result.isSuccess) {
      // Step 4: Verify payment
      setState(() => _isPlacingOrder = true);
      try {
        final verifyRes = await _api.post(
          '/api/v1/user/orders/$productOrderId/payment/verify',
          data: {
            'razorpayOrderId': result.orderId,
            'razorpayPaymentId': result.paymentId,
            'razorpaySignature': result.signature,
          },
        );

        if (verifyRes.data['success'] == true) {
          if (!mounted) return;
          cart.clearCart();
          setState(() => _isPlacingOrder = false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
          );
          _showSuccess('Order placed & payment confirmed!');
        } else {
          setState(() => _isPlacingOrder = false);
          _showVerificationError(productOrderId);
        }
      } catch (e) {
        setState(() => _isPlacingOrder = false);
        _showVerificationError(productOrderId);
      }
    } else if (result.isCancelled) {
      await _cancelOrderQuietly(productOrderId);
      _showError('Payment cancelled');
    } else if (result.isFailed) {
      await _cancelOrderQuietly(productOrderId);
      _showError(_cleanRazorpayError(result.message ?? 'Payment failed'));
    } else {
      // External wallet
      _showInfo('Payment via ${result.message ?? 'external wallet'}. We\'ll confirm once received.');
    }
  }

  // Build E.164-style contact for Razorpay prefill: +91XXXXXXXXXX
  String _buildContact(user_models.UserModel? user) {
    final mobile = user?.name ?? '';
    if (mobile.isEmpty) return '';
    if (mobile.startsWith('+')) return mobile;
    final cc = ('+91').replaceAll('+', '');
    return '+$cc$mobile';
  }

  Future<void> _cancelOrderQuietly(String orderId) async {
    try {
      await _productService.cancelOrder(orderId, 'Payment not completed');
    } catch (_) {}
  }

  void _showVerificationError(String orderId) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Payment Received',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Your payment was processed but we couldn\'t confirm it instantly. '
          'Order ID: $orderId\n\nPlease check My Orders in a few minutes or contact support.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('My Orders', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _cleanRazorpayError(String msg) {
    if (msg.contains('BAD_REQUEST_ERROR')) return 'Payment declined by bank. Please try another card.';
    if (msg.contains('GATEWAY_ERROR')) return 'Payment gateway error. Please try again.';
    if (msg.contains('SERVER_ERROR')) return 'Payment server error. Please try again.';
    return msg.length > 80 ? '${msg.substring(0, 80)}...' : msg;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showInfo(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.info,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Cart',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.grey100),
        ),
      ),
      body: cart.isEmpty
          ? _buildEmpty(context)
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...cart.items.map((item) => _CartItemTile(item: item)),
                        const SizedBox(height: 16),
                        _buildVendorCouponSection(cart),
                        const SizedBox(height: 16),
                        const Text('Delivery Address',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        _isLoadingAddresses
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                            : _buildAddressCard(),
                        const SizedBox(height: 16),
                        _PriceSummary(
                            cart: cart,
                            vendorDiscountAmount: _vendorDiscountAmount,
                            deliveryCharge: _deliveryCharge,
                            isLoadingDelivery: _isFetchingDelivery),
                        // _buildPaymentMethodSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _buildPlaceOrderBar(cart),
              ],
            ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PayMethodTile(
                label: 'Cash on Delivery',
                icon: Icons.payments_outlined,
                selected: _paymentMethod == 'cod',
                onTap: () => setState(() => _paymentMethod = 'cod'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PayMethodTile(
                label: 'Online Payment',
                icon: Icons.account_balance_wallet_outlined,
                selected: _paymentMethod == 'online',
                onTap: () => setState(() => _paymentMethod = 'online'),
              ),
            ),
          ],
        ),
        if (_paymentMethod == 'online') ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, size: 14, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Secured by Razorpay · UPI, Cards, Net Banking & Wallets',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF15803D)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showAvailableCouponsSheet(String providerId, double subtotal) {
    final eligible = _availableVendorCoupons
        .where((c) => c['isPersonallyEligible'] == true)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.local_offer_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Available Coupons',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.grey100),
            Expanded(
              child: eligible.isEmpty
                  ? const Center(
                      child: Text('No coupons available',
                          style: TextStyle(
                              color: AppColors.grey400, fontSize: 14)),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: eligible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final c = eligible[i];
                        final code = c['code'] as String? ?? '';
                        final discountType = c['discountType'] as String? ?? '';
                        final discountValue = c['discountValue'];
                        final minOrderValue =
                            (c['minOrderValue'] as num?)?.toDouble() ?? 0;
                        final maxDiscount =
                            (c['maxDiscountAmount'] as num?)?.toDouble() ?? 0;
                        final discountText = discountType == 'percentage'
                            ? '$discountValue% off'
                            : '₹$discountValue off';

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.grey200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(code,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            letterSpacing: 0.8,
                                            color: AppColors.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text(discountText,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.success)),
                                    const SizedBox(height: 4),
                                    if (minOrderValue > 0)
                                      Text(
                                          'Min order ₹${minOrderValue.round()}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.grey500)),
                                    if (maxDiscount > 0)
                                      Text(
                                          'Max discount ₹${maxDiscount.round()}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.grey500)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _vendorCouponController.text = code;
                                    _applyVendorCoupon(
                                        code, providerId, subtotal);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Apply',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorCouponSection(CartProvider cart) {
    final providerId = cart.vendorId;
    if (providerId == null || providerId.isEmpty) return const SizedBox.shrink();

    final hasEligibleCoupons =
        _availableVendorCoupons.any((c) => c['isPersonallyEligible'] == true);

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
          Row(
            children: [
              const Icon(Icons.local_offer_rounded,
                  size: 17, color: AppColors.textPrimary),
              const SizedBox(width: 7),
              const Text('Vendor Coupon',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              if (hasEligibleCoupons && _appliedVendorCoupon == null)
                GestureDetector(
                  onTap: () => _showAvailableCouponsSheet(
                      providerId, cart.totalAmount),
                  child: const Text('Available Coupons',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_appliedVendorCoupon != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        Text(_appliedVendorCoupon!['code'] as String? ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                fontSize: 13,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('You save ₹${_vendorDiscountAmount.round()}',
                            style: const TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _removeVendorCoupon,
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
                    controller: _vendorCouponController,
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
                        borderSide: const BorderSide(color: AppColors.grey200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.grey200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _vendorCouponLoading
                        ? null
                        : () => _applyVendorCoupon(
                              _vendorCouponController.text,
                              providerId,
                              cart.totalAmount,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _vendorCouponLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Apply',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            if (_vendorCouponError != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 14, color: AppColors.error),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(_vendorCouponError!,
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

  Widget _buildPlaceOrderBar(CartProvider cart) {
    final discountedTotal =
        (cart.totalAmount - _vendorDiscountAmount + _deliveryCharge).clamp(0.0, double.infinity);
    const btnLabel = 'Pay Securely Online';

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewPadding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.grey100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(color: AppColors.grey500, fontSize: 14)),
              Text(
                '₹${discountedTotal.round()}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: (_isPlacingOrder || _isFetchingDelivery) ? null : () => _placeOrder(cart),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color:
                    _isPlacingOrder ? AppColors.grey300 : AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _isPlacingOrder
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(btnLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag_outlined,
              size: 72, color: AppColors.grey300),
          const SizedBox(height: 16),
          const Text('Your cart is empty',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey500)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Browse Products',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.grey100, shape: BoxShape.circle),
                child: const Icon(Icons.add_location_alt_rounded, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Select delivery address',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey)),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(addr.displayLabel,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (addr.fullAddress.isNotEmpty) addr.fullAddress,
                      if (addr.landmark?.isNotEmpty == true) addr.landmark!,
                      if (addr.city.isNotEmpty) addr.city,
                    ].join(', '),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddressPicker() async {
    final picked = await showSavedAddressPicker(context);
    if (picked != null && mounted) {
      setState(() => _selectedAddress = picked);
      final cart = context.read<CartProvider>();
      if (cart.vendorId != null && cart.vendorId!.isNotEmpty) {
        _fetchDeliveryCharge(picked.id, cart.vendorId!);
      }
    }
  }
}

// ── Payment method tile ───────────────────────────────────────────────────────
class _PayMethodTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PayMethodTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.grey200,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.grey400),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary)),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ── Cart item tile ────────────────────────────────────────────────────────────
class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: item.product.primaryImage.isNotEmpty
                  ? Image.network(item.product.primaryImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Container(
                          color: AppColors.grey100,
                          child: const Icon(Icons.inventory_2_outlined,
                              color: AppColors.grey300)))
                  : Container(
                      color: AppColors.grey100,
                      child: const Icon(Icons.inventory_2_outlined,
                          color: AppColors.grey300)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.productName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                    '₹${item.product.pricing.finalPrice.round()} / ${item.product.unit}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.grey500)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '₹${(item.product.pricing.finalPrice * item.quantity).round()}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    Row(
                      children: [
                        _QtyBtn(
                            icon: Icons.remove,
                            onTap: () =>
                                cart.decreaseQuantity(item.product.id)),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('${item.quantity}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                        _QtyBtn(
                            icon: Icons.add,
                            onTap: () => cart.addItem(item.product)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }
}

// ── Price summary ─────────────────────────────────────────────────────────────
class _PriceSummary extends StatelessWidget {
  final CartProvider cart;
  final double vendorDiscountAmount;
  final int deliveryCharge;
  final bool isLoadingDelivery;
  const _PriceSummary(
      {required this.cart,
      this.vendorDiscountAmount = 0.0,
      this.deliveryCharge = 0,
      this.isLoadingDelivery = false});

  @override
  Widget build(BuildContext context) {
    final finalTotal =
        (cart.totalAmount - vendorDiscountAmount + deliveryCharge).clamp(0.0, double.infinity);
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
          const Text('Price Details',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _PriceRow(
              label: 'Items (${cart.totalItems})',
              value: '₹${cart.totalAmount.round()}'),
          if (isLoadingDelivery)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delivery',
                      style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w400)),
                  const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                ],
              ),
            )
          else
            _PriceRow(
                label: 'Delivery',
                value: deliveryCharge == 0 ? 'Free' : '₹$deliveryCharge',
                isDiscount: deliveryCharge == 0),
          if (vendorDiscountAmount > 0)
            _PriceRow(
                label: 'Coupon Discount',
                value: '- ₹${vendorDiscountAmount.round()}',
                isDiscount: true),
          const _PriceRow(
              label: 'Payment Method',
              value: 'Online',
              isInfo: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppColors.grey100),
          ),
          _PriceRow(
              label: 'Total',
              value: '₹${finalTotal.round()}',
              bold: true),
          const SizedBox(height: 8),
          const Text(
            'Inclusive of all taxes & charges',
            style: TextStyle(
                fontSize: 11,
                color: AppColors.grey400,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool isDiscount;
  final bool isInfo;
  const _PriceRow(
      {required this.label,
      required this.value,
      this.bold = false,
      this.isDiscount = false,
      this.isInfo = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: bold ? AppColors.textPrimary : AppColors.grey500,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  fontSize: bold ? 15 : 13)),
          Text(value,
              style: TextStyle(
                  color: isDiscount
                      ? AppColors.success
                      : isInfo
                          ? AppColors.grey500
                          : AppColors.textPrimary,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  fontSize: bold ? 15 : 13)),
        ],
      ),
    );
  }
}

