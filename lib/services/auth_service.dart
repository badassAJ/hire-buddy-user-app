import 'package:dio/dio.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import '../core/constants/api_constants.dart';

class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();


  // ================= FORGOT PASSWORD FLOW =================

/// STEP 1: Send OTP for Forgot Password
Future<Map<String, dynamic>> userForgotPasswordSendOtp({
  required String countryCode,
  required String mobileNumber,
}) async {
  try {
    final response = await _api.post(
      ApiConstants.userForgotPasswordSendOtp,
      data: {
        'countryCode': countryCode,
        'mobileNumber': mobileNumber,
      },
    );

    return {
      'success': true,
      'data': response.data,
    };
  } on DioException catch (e) {
    return {
      'success': false,
      'error': e.response?.data['error'] ?? 'Failed to send OTP',
    };
  }
}


/// STEP 2: Verify OTP for Forgot Password
Future<Map<String, dynamic>> userForgotPasswordVerifyOtp({
  required String countryCode,
  required String mobileNumber,
  required String otp,
}) async {
  try {
    final response = await _api.post(
      ApiConstants.userForgotPasswordVerifyOtp,
      data: {
        'countryCode': countryCode,
        'mobileNumber': mobileNumber,
        'otp': otp,
      },
    );

    return {
      'success': true,
      'data': response.data,
    };
  } on DioException catch (e) {
    return {
      'success': false,
      'error': e.response?.data['error'] ?? 'OTP verification failed',
    };
  }
}


/// STEP 3: Reset Password after OTP verification
Future<Map<String, dynamic>> userResetPassword({
  required String countryCode,
  required String mobileNumber,
  required String otp,
  required String newPassword,
}) async {
  try {
    final response = await _api.post(
      ApiConstants.userResetPassword,
      data: {
        'countryCode': countryCode,
        'mobileNumber': mobileNumber,
        'otp': otp,
        'newPassword': newPassword,
      },
    );

    // If backend returns tokens after reset (optional but recommended)
    if (response.data['success'] == true &&
        response.data['tokens'] != null) {
      await _storage.saveAccessToken(
        response.data['tokens']['accessToken'],
      );
      await _storage.saveRefreshToken(
        response.data['tokens']['refreshToken'],
      );

      if (response.data['user'] != null) {
        await _storage.saveUser(response.data['user']);
      }
    }

    return {
      'success': true,
      'data': response.data,
    };
  } on DioException catch (e) {
    return {
      'success': false,
      'error': e.response?.data['error'] ?? 'Password reset failed',
    };
  }
}


Future<Map<String, dynamic>> sendResetOtp({
  required String countryCode,
  required String phone,
}) async {
  try {
    final response = await _api.post(
      ApiConstants.userForgotPasswordSendOtp,
      data: {
        'countryCode': countryCode,
        'phone': phone,
      },
    );

    return {
      'success': true,
      'data': response.data,
    };
  } on DioException catch (e) {
    return {
      'success': false,
      'error':
          e.response?.data['error'] ??
          'Failed to send OTP',
    };
  }
}




Future<Map<String, dynamic>> verifyResetOtp({
  required String countryCode,
  required String phone,
  required String otp,
}) async {
  try {
    final response = await _api.post(
      ApiConstants.userForgotPasswordVerifyOtp,
      data: {
        'countryCode': countryCode,
        'phone': phone,
        'otp': otp,
      },
    );

    return {
      'success': true,
      'data': response.data,
    };
  } on DioException catch (e) {
    return {
      'success': false,
      'error':
          e.response?.data['error'] ??
          'OTP verification failed',
    };
  }
}




Future<Map<String, dynamic>> resetPassword({
  required String countryCode,
  required String phone,
  required String newPassword,
}) async {
  try {
    final response = await _api.post(
      ApiConstants.userResetPassword,
      data: {
        'countryCode': countryCode,
        'phone': phone,
        'newPassword': newPassword,
      },
    );

    return {
      'success': true,
      'data': response.data,
    };
  } on DioException catch (e) {
    return {
      'success': false,
      'error':
          e.response?.data['error'] ??
          'Password reset failed',
    };
  }
}



// Future<Map<String, dynamic>> verifyResetOtp({
//   required String countryCode,
//   required String mobileNumber,
//   required String otp,
// }) async {
//   try {
//     final response = await _api.post(
//       ApiConstants.userForgotPasswordVerifyOtp,
//       data: {
//         'countryCode': countryCode,
//         'mobileNumber': mobileNumber,
//         'otp': otp,
//       },
//     );

//     return {
//       'success': true,
//       'data': response.data,
//     };
//   } on DioException catch (e) {
//     return {
//       'success': false,
//       'error': e.response?.data['error'] ?? 'OTP verification failed',
//     };
//   }
// }


// Future<Map<String, dynamic>> resetPassword({
//   required String countryCode,
//   required String mobileNumber,
//   required String newPassword,
// }) async {
//   try {
//     final response = await _api.post(
//       ApiConstants.userResetPassword,
//       data: {
//         'countryCode': countryCode,
//         'mobileNumber': mobileNumber,
//         'newPassword': newPassword,
//       },
//     );

//     // Save tokens if backend returns them (recommended)
//     if (response.data['success'] == true &&
//         response.data['tokens'] != null) {
//       await _storage.saveAccessToken(
//         response.data['tokens']['accessToken'],
//       );
//       await _storage.saveRefreshToken(
//         response.data['tokens']['refreshToken'],
//       );

//       if (response.data['user'] != null) {
//         await _storage.saveUser(response.data['user']);
//       }
//     }

//     return {
//       'success': true,
//       'data': response.data,
//     };
//   } on DioException catch (e) {
//     return {
//       'success': false,
//       'error': e.response?.data['error'] ?? 'Password reset failed',
//     };
//   }
// }




    // 🔵 NEW: Phone + Password Login (JWT based)
  Future<Map<String, dynamic>> loginWithPassword({
    required String countryCode,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.userLoginPassword, // 🔴 ADD THIS IN API CONSTANTS
        data: {
          'countryCode': countryCode,
          'phone': phone,
          'password': password,
          'fcmToken': await NotificationService().getToken(),
        },
      );

      if (response.data['success'] == true &&
          response.data['tokens'] != null) {

        // Save tokens
        await _storage.saveAccessToken(
          response.data['tokens']['accessToken'],
        );

        await _storage.saveRefreshToken(
          response.data['tokens']['refreshToken'],
        );

        // Save user
        if (response.data['user'] != null) {
          await _storage.saveUser(response.data['user']);
        }
      }

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Login failed',
      };
    }
  }

  // Send OTP for Signup
  Future<Map<String, dynamic>> sendSignupOtp({
    required String countryCode,
    required String phone,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.userSignupSendOtp,
        data: {'countryCode': countryCode, 'phone': phone},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to send OTP',
      };
    }
  }

  // Verify OTP for Signup
  // Future<Map<String, dynamic>> verifySignupOtp({
  //   required String countryCode,
  //   required String mobileNumber,
  //   required String otp,
  //   required String fullName,
  //   String? email,
  // }) async {
  //   try {
  //     final response = await _api.post(
  //       ApiConstants.userSignupVerifyOtp,
  //       data: {
  //         'countryCode': countryCode,
  //         'mobileNumber': mobileNumber,
  //         'otp': otp,
  //         'fullName': fullName,
  //         if (email != null) 'email': email,
  //         'fcmToken': await NotificationService().getToken(),
  //       },
  //     );

  //     if (response.data['success'] == true && response.data['tokens'] != null) {
  //       // Save tokens
  //       await _storage.saveAccessToken(response.data['tokens']['accessToken']);
  //       await _storage.saveRefreshToken(
  //         response.data['tokens']['refreshToken'],
  //       );

  //       // Save user data
  //       if (response.data['user'] != null) {
  //         await _storage.saveUser(response.data['user']);
  //       }
  //     }

  //     return {'success': true, 'data': response.data};
  //   } on DioException catch (e) {
  //     return {
  //       'success': false,
  //       'error': e.response?.data['error'] ?? 'OTP verification failed',
  //     };
  //   }
  // }

  Future<Map<String, dynamic>> verifySignupOtp({
  required String countryCode,
  required String phone,
  required String otp,
}) async {
  try {
    final response = await _api.post(
      ApiConstants.userSignupVerifyOtp,
      data: {
        'countryCode': countryCode,
        'phone': phone,
        'otp': otp,
      },
    );

    return {
      'success': true,
      'data': response.data,
    };
  } on DioException catch (e) {
    return {
      'success': false,
      'error':
          e.response?.data['error'] ??
          'OTP verification failed',
    };
  }
}

  // Send OTP for Login
  // Future<Map<String, dynamic>> sendLoginOtp({
  //   required String countryCode,
  //   required String mobileNumber,
  // }) async {
  //   try {
  //     final response = await _api.post(
  //       ApiConstants.userLoginSendOtp,
  //       data: {'countryCode': countryCode, 'mobileNumber': mobileNumber},
  //     );
  //     return {'success': true, 'data': response.data};
  //   } on DioException catch (e) {
  //     return {
  //       'success': false,
  //       'error': e.response?.data['error'] ?? 'Failed to send OTP',
  //     };
  //   }
  // }


  Future<Map<String, dynamic>> createAccount({
  required String fullName,
  required String phone,
  required String countryCode,
  required String password,
}) async {
  try {
    final response = await _api.post(
      ApiConstants.userCreateAccount,
      data: {
        'fullName': fullName,
        'phone': phone,
        'countryCode': countryCode,
        'password': password,
        'fcmToken':
            await NotificationService().getToken(),
      },
    );

    if (response.data['tokens'] != null) {
      await _storage.saveAccessToken(
        response.data['tokens']['accessToken'],
      );

      await _storage.saveRefreshToken(
        response.data['tokens']['refreshToken'],
      );

      await _storage.saveUser(
        response.data['user'],
      );
    }

    return {
      'success': true,
      'data': response.data,
    };
  } on DioException catch (e) {
    return {
      'success': false,
      'error':
          e.response?.data['error'] ??
          'Account creation failed',
    };
  }
}

  // Verify OTP for Login
  Future<Map<String, dynamic>> verifyLoginOtp({
    required String countryCode,
    required String mobileNumber,
    required String otp,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.userLoginVerifyOtp,
        data: {
          'countryCode': countryCode,
          'mobileNumber': mobileNumber,
          'otp': otp,
          'fcmToken': await NotificationService().getToken(),
        },
      );

      if (response.data['success'] == true && response.data['tokens'] != null) {
        // Save tokens
        await _storage.saveAccessToken(response.data['tokens']['accessToken']);
        await _storage.saveRefreshToken(
          response.data['tokens']['refreshToken'],
        );

        // Save user data
        if (response.data['user'] != null) {
          await _storage.saveUser(response.data['user']);
        }
      }

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'OTP verification failed',
      };
    }
  }

  // Logout
  Future<void> logout() async {
    await _storage.clearAll();
  }

  // Email/Password Signup
  Future<Map<String, dynamic>> emailSignup({
    required String email,
    required String password,
    required String fullName,
    String? mobileNumber,
    String? countryCode,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.userEmailSignup,
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          if (mobileNumber != null) 'mobileNumber': mobileNumber,
          if (countryCode != null) 'countryCode': countryCode,
        },
      );

      if (response.data['success'] == true && response.data['tokens'] != null) {
        // Save tokens
        await _storage.saveAccessToken(response.data['tokens']['accessToken']);
        await _storage.saveRefreshToken(
          response.data['tokens']['refreshToken'],
        );

        // Save user data
        if (response.data['user'] != null) {
          await _storage.saveUser(response.data['user']);
        }
      }

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Signup failed',
      };
    }
  }

  // Email/Password Login
  Future<Map<String, dynamic>> emailLogin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.userEmailLogin,
        data: {'email': email, 'password': password},
      );

      if (response.data['success'] == true && response.data['tokens'] != null) {
        // Save tokens
        await _storage.saveAccessToken(response.data['tokens']['accessToken']);
        await _storage.saveRefreshToken(
          response.data['tokens']['refreshToken'],
        );

        // Save user data
        if (response.data['user'] != null) {
          await _storage.saveUser(response.data['user']);
        }
      }

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Login failed',
      };
    }
  }

  // Verify Email OTP
  Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.userEmailVerifyOtp,
        data: {'email': email, 'otp': otp},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Verification failed',
      };
    }
  }

  // Resend Email Verification OTP
  Future<Map<String, dynamic>> resendEmailVerification({
    required String email,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.userEmailResendVerification,
        data: {'email': email},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to resend OTP',
      };
    }
  }

  // Forgot Password
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await _api.post(
        ApiConstants.userEmailForgotPassword,
        data: {'email': email},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to send reset OTP',
      };
    }
  }

  // // Reset Password
  // Future<Map<String, dynamic>> resetPassword({
  //   required String email,
  //   required String otp,
  //   required String newPassword,
  // }) async {
  //   try {
  //     final response = await _api.post(
  //       ApiConstants.userEmailResetPassword,
  //       data: {'email': email, 'otp': otp, 'newPassword': newPassword},
  //     );
  //     return {'success': true, 'data': response.data};
  //   } on DioException catch (e) {
  //     return {
  //       'success': false,
  //       'error': e.response?.data['error'] ?? 'Password reset failed',
  //     };
  //   }
  // }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  // Delete Account
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await _api.delete(ApiConstants.deleteAccount);
      if (response.data['success'] == true) {
        await _storage.clearAll();
      }
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Delete account failed',
      };
    }
  }

  // Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await _storage.getUser();
  }
}
