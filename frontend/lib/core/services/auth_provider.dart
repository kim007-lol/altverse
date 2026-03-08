import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _token;
  Map<String, dynamic>? _user;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;
  String get role => _user?['role'] ?? 'reader';
  String get userName => _user?['name'] ?? 'User';
  String get userEmail => _user?['email'] ?? '';

  /// Register a new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    String? penName,
    String? bio,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
      };
      if (role == 'author') {
        body['pen_name'] = penName ?? '';
        if (bio != null && bio.isNotEmpty) body['bio'] = bio;
      }

      final response = await ApiService.post('auth/register', body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _token = data['token'];
        _user = data['user'];
        _isLoggedIn = true;
        await _saveSession();
        notifyListeners();
        return true;
      } else {
        _errorMessage = _extractError(data);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage =
          'Tidak dapat terhubung ke server. Pastikan backend berjalan.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login with email & password
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('auth/login', {
        'email': email,
        'password': password,
      });
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _user = data['user'];
        _isLoggedIn = true;
        await _saveSession();
        notifyListeners();
        return true;
      } else {
        _errorMessage = _extractError(data);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage =
          'Tidak dapat terhubung ke server. Pastikan backend berjalan.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if user has a saved token (auto-login on app start)
  Future<bool> checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    final savedUser = prefs.getString('auth_user');

    if (savedToken == null || savedUser == null) return false;

    _token = savedToken;
    _user = jsonDecode(savedUser);

    // Verify token is still valid by calling /auth/me
    try {
      final response = await ApiService.get('auth/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = data['user'];
        _isLoggedIn = true;
        await _saveSession(); // refresh user data
        notifyListeners();
        return true;
      } else {
        // Token expired or invalid
        await _clearSession();
        return false;
      }
    } catch (e) {
      // Server unreachable — still allow offline session
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await ApiService.post('auth/logout', {});
    } catch (_) {
      // Ignore network errors on logout
    }
    _token = null;
    _user = null;
    _isLoggedIn = false;
    _errorMessage = null;
    await _clearSession();
    notifyListeners();
  }

  // Profile existence helpers
  bool get hasReaderProfile =>
      (_user?['has_reader_profile'] == true) ||
      (_user?['name'] != null && (_user!['name'] as String).isNotEmpty);
  bool get hasAuthorProfile =>
      (_user?['has_author_profile'] == true) ||
      (_user?['pen_name'] != null && (_user!['pen_name'] as String).isNotEmpty);

  /// Switch role (Reader <-> Author)
  Future<bool> switchRole({
    required String role,
    String? penName,
    String? authorBio,
    String? authorAvatarUrl,
    String? name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{'role': role};
      if (role == 'author' && penName != null) {
        body['pen_name'] = penName;
      }
      if (role == 'author' && authorBio != null) {
        body['author_bio'] = authorBio;
      }
      if (role == 'author' && authorAvatarUrl != null) {
        body['author_avatar_url'] = authorAvatarUrl;
      }
      if (role == 'reader' && name != null && name.isNotEmpty) {
        body['name'] = name;
      }

      final response = await ApiService.post('auth/switch-role', body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update local user data with the fresh user data returned from API
        if (data['user'] != null) {
          _user = {..._user!, ...data['user']};
          await _saveSession();
        }
        return true;
      } else {
        _errorMessage = _extractError(data);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Tidak dapat memproses permintaan ubah role.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save token + user to SharedPreferences
  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString('auth_token', _token!);
    if (_user != null) await prefs.setString('auth_user', jsonEncode(_user));
  }

  /// Clear saved session
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }

  /// Extract error message from Laravel JSON response
  String _extractError(Map<String, dynamic> data) {
    // Check for validation errors (422)
    if (data['errors'] != null) {
      final errors = data['errors'] as Map<String, dynamic>;
      final firstField = errors.values.first;
      if (firstField is List && firstField.isNotEmpty) {
        return firstField.first.toString();
      }
      return firstField.toString();
    }
    // Check for simple message (401, 403, etc)
    return data['message']?.toString() ?? 'Terjadi kesalahan.';
  }
}
