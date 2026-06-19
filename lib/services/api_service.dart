import 'dart:async';
import 'dart:convert'; // 🌟 ADDED: Required for safe JSON handling
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final StorageService _storage = StorageService();

  // Set this from main.dart to navigate to onboarding when session expires
  static void Function()? onForceLogout;

  bool _isRefreshing = false;
  // `true`  → refresh succeeded
  // `false` → refresh token rejected (real expiry → must logout)
  // `null`  → transient network error (do NOT logout, just propagate)
  final List<Completer<bool?>> _refreshQueue = [];

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Never retry the refresh endpoint itself to avoid infinite loops
            if (error.requestOptions.path.contains('refresh-token')) {
              await _forceLogout();
              return handler.next(error);
            }

            // Guest user — no token stored, just pass the error through
            final existingToken = await _storage.getAccessToken();
            if (existingToken == null) {
              return handler.next(error);
            }

            final refreshed = await _acquireRefresh();
            if (refreshed == true) {
              // Retry original request with new token
              final opts = error.requestOptions;
              final token = await _storage.getAccessToken();
              opts.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {
                return handler.next(error);
              }
            } else if (refreshed == false) {
              // Real expiry — refresh token was rejected by the server
              await _forceLogout();
            }
            // refreshed == null → transient network error during refresh.
            // Keep the session; just propagate the original 401 so caller can decide.
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Ensures only one refresh call happens at a time.
  // Concurrent callers wait for the first refresh to complete.
  // Returns: true=refreshed, false=token rejected (logout), null=transient network error.
  Future<bool?> _acquireRefresh() async {
    if (_isRefreshing) {
      final completer = Completer<bool?>();
      _refreshQueue.add(completer);
      return completer.future;
    }

    _isRefreshing = true;
    bool? result;
    try {
      result = await _doRefresh();
    } finally {
      _isRefreshing = false;
      for (final c in _refreshQueue) {
        c.complete(result);
      }
      _refreshQueue.clear();
    }
    return result;
  }

  // Uses a plain Dio with NO interceptors to avoid triggering the 401 handler again.
  // Returns: true=success, false=token rejected, null=transient (network/timeout/server).
  Future<bool?> _doRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false; // No token to refresh → genuine expiry.

    final plainDio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
    ));

    try {
      final response = await plainDio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['tokens'] != null) {
        final tokens = response.data['tokens'];
        await _storage.saveAccessToken(tokens['accessToken']);
        await _storage.saveRefreshToken(tokens['refreshToken']);
        return true;
      }
      return false;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 401 / 403 from server = refresh token genuinely invalid/expired → force logout.
      if (status == 401 || status == 403) return false;
      // Any other error (no response, 5xx, timeout, network down) → transient, don't logout.
      return null;
    } catch (_) {
      // Unknown error → treat as transient; safer than nuking the session.
      return null;
    }
  }

  Future<void> _forceLogout() async {
    await _storage.clearAll();
    onForceLogout?.call();
  }

  // 🌟 MODIFIED HELPER EXECUTION METHODS WITH INLINE EXCEPTION INTERCEPTORS 🌟

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      _safelyNormalizeErrorBody(e);
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      _safelyNormalizeErrorBody(e);
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      _safelyNormalizeErrorBody(e);
      rethrow;
    }
  }

  Future<Response> delete(String path, {dynamic data}) async {
    try {
      return await _dio.delete(path, data: data);
    } on DioException catch (e) {
      _safelyNormalizeErrorBody(e);
      rethrow;
    }
  }

  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      _safelyNormalizeErrorBody(e);
      rethrow;
    }
  }

  /// 🌟 SAFE PARSER: Guarantees error responses are structured without altering successful code flows.
  void _safelyNormalizeErrorBody(DioException e) {
    if (e.response?.data != null && e.response?.data is String) {
      try {
        // If the server error response is a valid JSON string, parse it cleanly into a Map
        final decodedMap = jsonDecode(e.response!.data as String);
        e.response!.data = decodedMap;
      } catch (_) {
        // If it's plain text, an unhandled crash string, or HTML, wrap it inside an error object map.
        // This keeps other parts of your app from throwing subtype runtime errors when using ['error']!
        e.response!.data = {'error': e.response!.data.toString()};
      }
    }
  }
}