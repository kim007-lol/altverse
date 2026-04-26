import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const Duration _timeout = Duration(seconds: 30);
  String? _token;

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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

  /// Constructs a full image URL from a path.
  /// Uses the backend proxy route /api/v1/public/images/{path} which
  /// streams images directly from R2/S3 storage.
  /// If the path is already a full URL, returns it as-is.
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    // Strip leading slash if present
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiConstants.baseUrl}/public/images/$cleanPath';
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
      final uri = Uri.parse('${ApiConstants.baseUrl}/$endpoint');
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
      return _instance._handleResponse(response);
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

  Future<ApiResponse> _get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      var uri = Uri.parse('${ApiConstants.baseUrl}/$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));
      }

      final response = await http.get(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse> _post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/$endpoint');
      final response = await http.post(uri, headers: _headers, body: body != null ? jsonEncode(body) : null);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse> _put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/$endpoint');
      final response = await http
          .put(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
          .timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout. Please try again.');
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse> _patch(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/$endpoint');
      final response = await http
          .patch(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
          .timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout. Please try again.');
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse> _delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/$endpoint');
      final response = await http.delete(uri, headers: _headers).timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      return ApiResponse(success: false, message: 'Request timeout. Please try again.');
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error: ${e.toString()}');
    }
  }

  ApiResponse _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    try {
      final data = jsonDecode(response.body);

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
