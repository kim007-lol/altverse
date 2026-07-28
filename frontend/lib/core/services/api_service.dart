import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const Duration _timeout = Duration(seconds: 30);
  String? _token;
  String? _refreshToken;

  /// Guards against a thundering herd of refreshes: concurrent 401s all await
  /// the same in-flight refresh instead of each firing their own.
  Future<bool>? _refreshInFlight;

  /// Callback invoked when the session cannot be recovered (refresh failed or
  /// no refresh token). AuthProvider sets this to trigger a logout.
  static void Function()? onForceLogout;

  /// In-memory cache for pre-signed image URLs (path → {url, expiry}).
  static final Map<String, _CachedUrl> _imageUrlCache = {};

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> clearToken() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }

  Future<void> setRefreshToken(String token) async {
    _refreshToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', token);
  }

  Future<void> loadRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    _refreshToken = prefs.getString('refresh_token');
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ─── Static HTTP Methods (delegate to singleton) ───

  static Future<ApiResponse> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    return _instance._get(endpoint, queryParams: queryParams);
  }

  static Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body}) async {
    return _instance._post(endpoint, body: body);
  }

  static Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    return _instance._put(endpoint, body: body);
  }

  static Future<ApiResponse> patch(String endpoint, {Map<String, dynamic>? body}) async {
    return _instance._patch(endpoint, body: body);
  }

  static Future<ApiResponse> delete(String endpoint) async {
    return _instance._delete(endpoint);
  }

  // ─── Image URL Helper ───

  /// Returns a full image URL served via the Go Image Proxy.
  ///
  /// The Go proxy fetches from R2 on first access, then serves from
  /// an in-memory LRU cache on subsequent requests — much faster than
  /// streaming through PHP/Laravel.
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    // Strip leading slash if present
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiConstants.imageBaseUrl}/images/$cleanPath';
  }

  /// Fetches a pre-signed GET URL from the backend.
  /// Cached in-memory for 50 minutes (URLs are valid for 60 min).
  static Future<String> getPresignedImageUrl(String? path) async {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // Check cache
    final cached = _imageUrlCache[cleanPath];
    if (cached != null && cached.expiry.isAfter(DateTime.now())) {
      return cached.url;
    }

    // Fetch from backend
    try {
      final res = await get('public/image-url', queryParams: {'path': cleanPath});
      if (res.success && res.data != null && res.data['url'] != null) {
        final url = res.data['url'] as String;
        _imageUrlCache[cleanPath] = _CachedUrl(
          url: url,
          expiry: DateTime.now().add(const Duration(minutes: 50)),
        );
        return url;
      }
    } catch (_) {}

    // Fallback to Go image proxy
    return '${ApiConstants.imageBaseUrl}/images/$cleanPath';
  }

  // ─── Multipart Upload ───

  /// Send a multipart/form-data request (for file uploads like avatar, cover).
  static Future<ApiResponse> multipart(
    String endpoint, {
    Map<String, String>? fields,
    Map<String, File>? files,
    String method = 'POST',
  }) async {
    try {
      final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
      final uri = Uri.parse('${ApiConstants.baseUrl}/$cleanEndpoint');
      final request = http.MultipartRequest(method, uri);

      // Add auth header
      if (_instance._token != null) {
        request.headers['Authorization'] = 'Bearer ${_instance._token}';
      }
      request.headers['Accept'] = 'application/json';

      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add files
      if (files != null) {
        for (final entry in files.entries) {
          request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value.path));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return await _instance._handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: ${e.toString()}');
    }
  }

  // ─── R2 Direct Upload ───

  /// Upload a file directly to R2 using a pre-signed URL.
  static Future<ApiResponse> uploadToR2(String signedUrl, File file, {String contentType = 'image/jpeg'}) async {
    try {
      final bytes = await file.readAsBytes();
      final response = await http.put(Uri.parse(signedUrl), headers: {'Content-Type': contentType}, body: bytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(success: true, message: 'Upload successful', statusCode: response.statusCode);
      } else {
        return ApiResponse(
          success: false,
          message: 'Upload failed: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Upload error: ${e.toString()}');
    }
  }

  // ─── Internal Instance Methods ───
  
  Uri _buildUri(String endpoint) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return Uri.parse('${ApiConstants.baseUrl}/$cleanEndpoint');
  }

  Future<ApiResponse> _get(String endpoint, {Map<String, dynamic>? queryParams}) {
    var uri = _buildUri(endpoint);
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));
    }
    // _headers is re-read on each call so a post-refresh retry uses the new token.
    return _send(() => http.get(uri, headers: _headers).timeout(_timeout));
  }

  Future<ApiResponse> _post(String endpoint, {Map<String, dynamic>? body}) {
    final uri = _buildUri(endpoint);
    final encoded = body != null ? jsonEncode(body) : null;
    return _send(() => http.post(uri, headers: _headers, body: encoded).timeout(_timeout));
  }

  Future<ApiResponse> _put(String endpoint, {Map<String, dynamic>? body}) {
    final uri = _buildUri(endpoint);
    final encoded = body != null ? jsonEncode(body) : null;
    return _send(() => http.put(uri, headers: _headers, body: encoded).timeout(_timeout));
  }

  Future<ApiResponse> _patch(String endpoint, {Map<String, dynamic>? body}) {
    final uri = _buildUri(endpoint);
    final encoded = body != null ? jsonEncode(body) : null;
    return _send(() => http.patch(uri, headers: _headers, body: encoded).timeout(_timeout));
  }

  Future<ApiResponse> _delete(String endpoint) {
    final uri = _buildUri(endpoint);
    return _send(() => http.delete(uri, headers: _headers).timeout(_timeout));
  }

  /// Runs an HTTP request and, on a 401 with a stored refresh token, transparently
  /// refreshes the access token (single-flight) and retries the request once.
  /// If refresh fails, the session is unrecoverable and onForceLogout fires.
  Future<ApiResponse> _send(Future<http.Response> Function() doRequest) async {
    http.Response response;
    try {
      response = await doRequest();
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout. Please try again.');
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: ${e.toString()}');
    }

    if (response.statusCode == 401 && _refreshToken != null && _refreshToken!.isNotEmpty) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        try {
          response = await doRequest();
        } on TimeoutException {
          return ApiResponse(success: false, message: 'Request timeout. Please try again.');
        } catch (e) {
          return ApiResponse(success: false, message: 'Network error: ${e.toString()}');
        }
      } else {
        onForceLogout?.call();
      }
    }
    return _handleResponse(response);
  }

  /// Single-flight refresh: concurrent callers share one in-flight refresh.
  Future<bool> _refreshAccessToken() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _doRefresh() async {
    try {
      final resp = await http
          .post(
            _buildUri('auth/refresh'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'refresh_token': _refreshToken}),
          )
          .timeout(_timeout);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final data = body is Map ? body['data'] : null;
        if (data is Map && data['access_token'] != null) {
          await setToken(data['access_token'] as String);
          if (data['refresh_token'] != null) {
            await setRefreshToken(data['refresh_token'] as String);
          }
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<ApiResponse> _handleResponse(http.Response response) async {
    final statusCode = response.statusCode;

    // Note: 401 handling (refresh → retry → force-logout) lives in _send so we
    // don't force-logout before a refresh attempt. Multipart uploads call this
    // directly; an expired token there surfaces as a normal 401 ApiResponse.

    try {
      final data = await compute(jsonDecode, response.body);

      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse(
          success: true,
          data: data,
          message: data is Map ? (data['message'] ?? 'Success') : 'Success',
          statusCode: statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          data: data,
          message: data is Map ? (data['message'] ?? 'Request failed') : 'Request failed',
          statusCode: statusCode,
          errors: data is Map ? data['errors'] : null,
        );
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Failed to parse response', statusCode: statusCode);
    }
  }
}

/// Internal cache entry for pre-signed image URLs.
class _CachedUrl {
  final String url;
  final DateTime expiry;
  _CachedUrl({required this.url, required this.expiry});
}

class ApiResponse {
  final bool success;
  final dynamic data;
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiResponse({required this.success, this.data, required this.message, this.statusCode, this.errors});

  bool get isUnauthorized => statusCode == 401;
  bool get isValidationError => statusCode == 422;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;
}
