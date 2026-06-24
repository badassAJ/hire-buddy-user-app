import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  // Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Token Management (Secure Storage)
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: 'access_token', value: token);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: 'refresh_token', value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  // User Data (SharedPreferences)
  Future<void> saveUser(Map<String, dynamic> user) async {
    await init();
    await _prefs?.setString('user', json.encode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    await init();
    final userStr = _prefs?.getString('user');
    if (userStr != null) {
      return json.decode(userStr) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> clearUser() async {
    await init();
    await _prefs?.remove('user');
  }

  // Onboarding Status
  Future<void> setOnboardingComplete(bool value) async {
    await init();
    await _prefs?.setBool('onboarding_complete', value);
  }

  Future<bool> isOnboardingComplete() async {
    await init();
    return _prefs?.getBool('onboarding_complete') ?? false;
  }

  // FCM Token
  Future<void> saveFcmToken(String token) async {
    await init();
    await _prefs?.setString('fcmToken', token);
  }

  String? getFcmToken() {
    return _prefs?.getString('fcmToken');
  }

  // Clear All Data
  Future<void> clearAll() async {
    await clearTokens();
    await clearUser();
    await init();
    await _prefs?.clear();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // // Cart Persistence
  // Future<void> saveCart(String cartJson) async {
  //   await init();
  //   await _prefs?.setString('cart', cartJson);
  // }

  // Future<String?> getCart() async {
  //   await init();
  //   return _prefs?.getString('cart');
  // }

  // Future<void> clearCart() async {
  //   await init();
  //   await _prefs?.remove('cart');
  // }
}
