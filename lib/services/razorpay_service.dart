import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';

enum PaymentStatus { success, failed, cancelled, externalWallet }

class PaymentResult {
  final PaymentStatus status;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final int? errorCode;
  final String? message;

  bool get isSuccess => status == PaymentStatus.success;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isFailed => status == PaymentStatus.failed;

  const PaymentResult._({
    required this.status,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorCode,
    this.message,
  });

  factory PaymentResult.success({
    required String paymentId,
    required String orderId,
    required String signature,
  }) =>
      PaymentResult._(
        status: PaymentStatus.success,
        paymentId: paymentId,
        orderId: orderId,
        signature: signature,
      );

  factory PaymentResult.failure({int? code, String? message}) {
    // Razorpay fires error with code 0 and "Payment Cancelled" message on dismiss
    final cancelled = message?.toLowerCase().contains('cancel') == true ||
        message?.toLowerCase().contains('dismiss') == true;
    return PaymentResult._(
      status: cancelled ? PaymentStatus.cancelled : PaymentStatus.failed,
      errorCode: code,
      message: message,
    );
  }

  factory PaymentResult.externalWallet({required String walletName}) =>
      PaymentResult._(
        status: PaymentStatus.externalWallet,
        message: walletName,
      );
}

class RazorpayService {
  Razorpay? _razorpay;
  Completer<PaymentResult>? _completer;

  Future<PaymentResult> openCheckout({
    required String keyId,
    required String orderId,
    required int amountPaise,
    required String description,
    String contact = '',
    String email = '',
    String appName = 'HireBuddy',
  }) async {
    _cleanup();

    _completer = Completer<PaymentResult>();
    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    final options = <String, dynamic>{
      'key': keyId,
      'order_id': orderId,
      'amount': amountPaise,
      'name': appName,
      'description': description,
      'prefill': {
        if (contact.isNotEmpty) 'contact': contact,
        if (email.isNotEmpty) 'email': email,
      },
      'theme': {'color': '#111827'},
      'retry': {'enabled': false},
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      _complete(PaymentResult.failure(message: e.toString()));
    }

    return _completer!.future;
  }

  void _onSuccess(PaymentSuccessResponse response) {
    _complete(PaymentResult.success(
      paymentId: response.paymentId ?? '',
      orderId: response.orderId ?? '',
      signature: response.signature ?? '',
    ));
  }

  void _onError(PaymentFailureResponse response) {
    _complete(PaymentResult.failure(
      code: response.code,
      message: response.message,
    ));
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _complete(PaymentResult.externalWallet(walletName: response.walletName ?? ''));
  }

  void _complete(PaymentResult result) {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(result);
    }
    _cleanup();
  }

  void _cleanup() {
    _razorpay?.clear();
    _razorpay = null;
  }

  void dispose() {
    _cleanup();
    _completer = null;
  }
}
