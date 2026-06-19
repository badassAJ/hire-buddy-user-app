class ApiConstants {
  // Base URL - backend runs on port 5001
  static const String baseUrl = 'http://192.168.29.196:5001';

  // For Android Emulator use: http://10.0.2.2:5001
  // For iOS Simulator use: http://localhost:5001
  // For Real Device use: http://192.168.29.196:5001

  // Auth Endpoints
  // static const String userSignupSendOtp = '/auth/user/signup/send-otp';
  static const String userLoginPassword = '/auth/user/login-password';
  // static const String userSignupVerifyOtp = '/auth/user/signup/verify-otp';
  static const String userLoginSendOtp = '/auth/user/login/send-otp';
  static const String userLoginVerifyOtp = '/auth/user/login/verify-otp';
  static const String userEmailSignup = '/auth/user/email/signup';
  static const String userEmailLogin = '/auth/user/email/login';
  static const String userEmailVerifyOtp = '/auth/user/email/verify-otp';
  static const String userEmailResendVerification =
      '/auth/user/email/resend-verification';
  static const String userEmailForgotPassword =
      '/auth/user/email/forgot-password';
  static const String userEmailResetPassword =
      '/auth/user/email/reset-password';
  static const String refreshToken = '/auth/user/refresh-token';

  // User Endpoints
  static const String userProfile = '/api/v1/user/profile';
  static const String updateProfile = '/api/v1/user/profile';
  static const String deleteAccount = '/api/v1/user/account';
  static const String updateAddress = '/api/v1/user/address';

  // Service Endpoints
  static const String categories = '/api/v1/user/services/categories';
  static const String services = '/api/v1/user/services';
  static const String popularServices = '/api/v1/user/services/popular';
  static const String serviceDetails = '/api/v1/user/services'; // /:serviceId
  static const String activeBanners = '/api/v1/banners/active';

  // Booking Endpoints
  static const String createBooking = '/api/v1/user/bookings';
  static const String myBookings = '/api/v1/user/bookings';
  static const String bookingDetails = '/api/v1/user/bookings'; // /:bookingId
  static const String cancelBooking =
      '/api/v1/user/bookings'; // /:bookingId/cancel

  // Offers Endpoints
  static const String activeOffers = '/api/v1/offers/active';

  // Product Endpoints
  static const String products = '/api/v1/user/products';

  // Product Order Endpoints
  static const String productOrders = '/api/v1/user/orders';
  static const String productOrderEstimateDelivery =
      '/api/v1/user/orders/estimate-delivery';

  // Product Review Endpoints
  static const String productReviews = '/api/v1/user/product-reviews';

  // Address Endpoints (collection with _id, separate from profile currentAddress)
  static const String addresses = '/api/v1/user/addresses';

  // Dispute Endpoints
  static const String disputes = '/api/v1/user/disputes';

  // Promo Endpoints
  static const String validatePromo = '/api/v1/promo/validate';

  // Coupon Endpoints
  static const String validateCoupon = '/api/v1/user/coupons/validate';

  // Vendor Coupon Endpoints
  static const String vendorCouponsForUser = '/api/v1/user/coupons/vendor';
  static const String validateVendorCoupon =
      '/api/v1/user/coupons/vendor/validate';

  // Rating Endpoints
  static const String submitRating = '/api/v1/user/ratings';
  static const String serviceReviews = '/api/v1/user/ratings/service';
  static const String topReviews = '/api/v1/user/ratings/top';

  // Public Config Endpoints
  static const String publicServiceArea = '/api/v1/public/config/service-area';

  // Notification Preferences
  static const String notificationPreferences =
      '/api/v1/user/notification-preferences';

  // Upload Endpoints
  static const String uploadImage = '/api/v1/upload/image';
  static const String uploadImages = '/api/v1/upload/images';
  static const String uploadProfile = '/api/v1/upload/profile';
  static const String uploadDocument = '/api/v1/upload/document';
  static const String deleteFile = '/api/v1/upload/file';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);


  // ================= FORGOT PASSWORD (NEW FLOW) =================

/// STEP 1: Send OTP for Forgot Password
/// Phone → OTP via 2Factor.in
static const String userForgotPasswordSendOtp =
    "/auth/forgot-password/send-otp";

/// STEP 2: Verify OTP for Forgot Password
/// OTP validation before reset password
static const String userForgotPasswordVerifyOtp =
    "/auth/forgot-password/verify-otp";

/// STEP 3: Reset Password after OTP verification
/// Sets new password for user
static const String userResetPassword =
    '/auth/reset-password';



static const String userSignupSendOtp =
    '/auth/signup/send-otp';

static const String userSignupVerifyOtp =
    '/auth/signup/verify-otp';

static const String userCreateAccount =
    '/auth/signup/create-account';



}