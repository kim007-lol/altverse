import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti IP Development ini ke IPv4 Host PC Anda jika ingin akses dari HP asli via WiFi.
  static String get apiBaseUrl => kReleaseMode
      ? 'https://api.aureader.com/api/v1/'
      : 'http://192.168.1.9:8000/api/v1/';

  // R2 Public URL untuk menampilkan gambar di frontend
  static const String r2PublicUrl =
      'https://pub-f5ef4dcb047c458ba79723646fa83618.r2.dev';

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Local storage paths (avatars, etc.) → resolve directly via Laravel server
    if (path.startsWith('/storage/')) {
      final serverBase = kReleaseMode
          ? 'https://api.aureader.com'
          : 'http://192.168.1.9:8000';
      return '$serverBase$path';
    }

    // Bersihkan leading slash untuk mencegah double slash
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // Gunakan proxy backend untuk menghindari blokir Internet Positif pada r2.dev
    return '${apiBaseUrl}public/images/$cleanPath';
  }

  /// GET request with optional auth token
  static Future<http.Response> get(String endpoint) async {
    final token = await _getToken();
    return http.get(
      Uri.parse('$apiBaseUrl$endpoint'),
      headers: _headers(token),
    );
  }

  /// POST request with optional auth token
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await _getToken();
    return http.post(
      Uri.parse('$apiBaseUrl$endpoint'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
  }

  /// PUT request with optional auth token
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await _getToken();
    return http.put(
      Uri.parse('$apiBaseUrl$endpoint'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
  }

  /// PATCH request with optional auth token
  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await _getToken();
    return http.patch(
      Uri.parse('$apiBaseUrl$endpoint'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
  }

  /// DELETE request with optional auth token
  static Future<http.Response> delete(String endpoint) async {
    final token = await _getToken();
    return http.delete(
      Uri.parse('$apiBaseUrl$endpoint'),
      headers: _headers(token),
    );
  }

  /// Multipart upload (untuk cover series, dll.)
  static Future<http.Response> multipart(
    String endpoint, {
    String method = 'POST',
    Map<String, String> fields = const {},
    Map<String, File> files = const {},
    Map<String, List<File>> fileArrays = const {},
  }) async {
    final token = await _getToken();
    final uri = Uri.parse('$apiBaseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);

    if (method == 'PUT') {
      request.fields['_method'] = 'PUT';
    }

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    request.fields.addAll(fields);

    for (final entry in files.entries) {
      request.files.add(
        await http.MultipartFile.fromPath(entry.key, entry.value.path),
      );
    }

    for (final entry in fileArrays.entries) {
      for (final file in entry.value) {
        request.files.add(
          await http.MultipartFile.fromPath('${entry.key}[]', file.path),
        );
      }
    }

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  /// Upload file langsung ke R2 via presigned URL (PUT)
  static Future<bool> uploadToR2(
    String signedUrl,
    File file,
    String contentType,
  ) async {
    try {
      final bytes = await file.readAsBytes();
      final response = await http.put(
        Uri.parse(signedUrl),
        headers: {'Content-Type': contentType},
        body: bytes,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('R2 upload error: $e');
      return false;
    }
  }

  /// Build standard headers
  static Map<String, String> _headers(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Read saved token from shared_preferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
