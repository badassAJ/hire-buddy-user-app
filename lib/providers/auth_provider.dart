import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // ===============================
  // RESET PASSWORD OTP SEND
  // ===============================
  // ===============================
  // SEND RESET OTP
  // ===============================
  Future<bool> sendResetOtp({
    required String countryCode,
    required String phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.sendResetOtp(
      countryCode: countryCode,
      phone: phone,
    );

    _isLoading = false;

    if (result['success']) {
      notifyListeners();
      return true;
    }

    _error = result['error'];
    notifyListeners();
    return false;
  }

  // ===============================
  // VERIFY RESET OTP
  // ===============================

  Future<bool> verifyResetOtp({
    required String countryCode,
    required String phone,
    required String otp,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.verifyResetOtp(
      countryCode: countryCode,
      phone: phone,
      otp: otp,
    );

    _isLoading = false;

    if (result['success'] == true) {
      notifyListeners();
      return true;
    }

    _error = result['data']?['error'] ?? result['error'] ?? 'Invalid OTP';
    notifyListeners();
    return false;
  }

  // ===============================
  // RESET PASSWORD FINAL STEP
  // ===============================
  Future<bool> resetPassword({
    required String phone,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.resetPassword(
      countryCode: '+91',
      phone: phone,
      newPassword: newPassword,
    );

    _isLoading = false;

    if (result['success'] == true) {
      notifyListeners();
      return true;
    } else {
      // 🌟 FIXED: Safely maps backend error payloads to prevent UI layout silence
      _error =
          result['data']?['error'] ??
          result['error'] ??
          'Password reset failed';
      notifyListeners();
      return false;
    }
  }

  // 🔵 NEW: Phone + Password Login (JWT based)
  Future<bool> loginWithPassword({
    required String countryCode,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.loginWithPassword(
      countryCode: countryCode,
      phone: phone,
      password: password,
    );

    _isLoading = false;

    // Verify internal data map integrity
    if (result['success'] == true &&
        result['data'] != null &&
        result['data']['user'] != null) {
      _currentUser = UserModel.fromJson(result['data']['user']);
      notifyListeners();
      return true;
    } else {
      //  FIXED: Extract the real server message safely out of the data payload layer
      _error = result['data']?['error'] ?? result['error'] ?? 'Login failed';
      notifyListeners();
      return false;
    }
  }

  // Send OTP for Login
  // Future<bool> sendLoginOtp(String countryCode, String mobileNumber) async {
  //   _isLoading = true;
  //   _error = null;
  //   notifyListeners();

  //   final result = await _authService.sendLoginOtp(
  //     countryCode: countryCode,
  //     mobileNumber: mobileNumber,
  //   );

  //   _isLoading = false;
  //   if (result['success']) {
  //     notifyListeners();
  //     return true;
  //   } else {
  //     _error = result['error'];
  //     notifyListeners();
  //     return false;
  //   }
  // }

  // Verify OTP for Login
  Future<bool> verifyLoginOtp(
    String countryCode,
    String mobileNumber,
    String otp,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.verifyLoginOtp(
      countryCode: countryCode,
      mobileNumber: mobileNumber,
      otp: otp,
    );

    _isLoading = false;
    if (result['success'] && result['data']['user'] != null) {
      _currentUser = UserModel.fromJson(result['data']['user']);
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }

  // Send OTP for Signup
  // Future<bool> sendSignupOtp(String countryCode, String mobileNumber) async {
  //   _isLoading = true;
  //   _error = null;
  //   notifyListeners();

  //   final result = await _authService.sendSignupOtp(
  //     countryCode: countryCode,
  //     mobileNumber: mobileNumber,
  //   );

  //   _isLoading = false;
  //   if (result['success']) {
  //     notifyListeners();
  //     return true;
  //   } else {
  //     _error = result['error'];
  //     notifyListeners();
  //     return false;
  //   }
  // }

  Future<bool> sendSignupOtp({
    required String countryCode,
    required String phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.sendSignupOtp(
      countryCode: countryCode,
      phone: phone,
    );

    _isLoading = false;

    if (result['success']) {
      return true;
    }

    _error = result['error'];
    notifyListeners();
    return false;
  }

  // Verify OTP for Signup
  // Future<bool> verifySignupOtp({
  //   required String countryCode,
  //   required String mobileNumber,
  //   required String otp,
  //   required String fullName,
  //   String? email,
  // }) async {
  //   _isLoading = true;
  //   _error = null;
  //   notifyListeners();

  //   final result = await _authService.verifySignupOtp(
  //     countryCode: countryCode,
  //     mobileNumber: mobileNumber,
  //     otp: otp,
  //     fullName: fullName,
  //     email: email,
  //   );

  //   _isLoading = false;
  //   if (result['success'] && result['data']['user'] != null) {
  //     _currentUser = UserModel.fromJson(result['data']['user']);
  //     notifyListeners();
  //     return true;
  //   } else {
  //     _error = result['error'];
  //     notifyListeners();
  //     return false;
  //   }
  // }

  Future<bool> verifySignupOtp({
    required String countryCode,
    required String phone,
    required String otp,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.verifySignupOtp(
      countryCode: countryCode,
      phone: phone,
      otp: otp,
    );

    _isLoading = false;

    if (result['success']) {
      notifyListeners();
      return true;
    }

    _error = result['error'];
    notifyListeners();
    return false;
  }

  Future<bool> createAccount({
    required String fullName,
    required String phone,
    required String countryCode,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.createAccount(
      fullName: fullName,
      phone: phone,
      countryCode: countryCode,
      password: password,
    );

    _isLoading = false;

    if (result['success']) {
      _currentUser = UserModel.fromJson(result['data']['user']);

      notifyListeners();
      return true;
    }

    _error = result['error'];
    notifyListeners();
    return false;
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  // Called by the API interceptor on force-logout (session expiry)
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  // Load current user from storage
  Future<void> loadCurrentUser() async {
    final userData = await _authService.getCurrentUser();
    if (userData != null) {
      _currentUser = UserModel.fromJson(userData);
      notifyListeners();
    }
  }

  // Email/Password Signup
  // Future<bool> emailSignup({
  //   required String email,
  //   required String password,
  //   required String fullName,
  //   String? mobileNumber,
  //   String? countryCode,
  // }) async {
  //   _isLoading = true;
  //   _error = null;
  //   notifyListeners();

  //   final result = await _authService.emailSignup(
  //     email: email,
  //     password: password,
  //     fullName: fullName,
  //     mobileNumber: mobileNumber,
  //     countryCode: countryCode,
  //   );

  //   _isLoading = false;
  //   if (result['success'] && result['data']['user'] != null) {
  //     _currentUser = UserModel.fromJson(result['data']['user']);
  //     notifyListeners();
  //     return true;
  //   } else {
  //     _error = result['error'];
  //     notifyListeners();
  //     return false;
  //   }
  // }

  // Email/Password Login
  Future<bool> emailLogin({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.emailLogin(
      email: email,
      password: password,
    );

    _isLoading = false;
    if (result['success'] && result['data']['user'] != null) {
      _currentUser = UserModel.fromJson(result['data']['user']);
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }

  // Verify Email OTP
  Future<bool> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.verifyEmailOtp(email: email, otp: otp);

    _isLoading = false;
    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }

  // Resend Email Verification OTP
  Future<bool> resendEmailVerification({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.resendEmailVerification(email: email);

    _isLoading = false;
    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }

  // Forgot Password
  Future<bool> forgotPassword({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.forgotPassword(email: email);

    _isLoading = false;
    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }

  // // Reset Password
  // Future<bool> resetPassword({
  //   required String email,
  //   required String otp,
  //   required String newPassword,
  // }) async {
  //   _isLoading = true;
  //   _error = null;
  //   notifyListeners();

  //   final result = await _authService.resetPassword(
  //     email: email,
  //     otp: otp,
  //     newPassword: newPassword,
  //   );

  //   _isLoading = false;
  //   if (result['success']) {
  //     notifyListeners();
  //     return true;
  //   } else {
  //     _error = result['error'];
  //     notifyListeners();
  //     return false;
  //   }
  // }

  // Check if logged in
  Future<bool> checkAuthStatus() async {
    return await _authService.isLoggedIn();
  }

  // Delete Account
  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.deleteAccount();

    _isLoading = false;
    if (result['success']) {
      _currentUser = null;
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }
}
