import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../theme/app_theme.dart';
import '../constants/api_endpoints.dart';

/// Singleton ApiService instance for token sync
final _api = ApiService();

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _token;
  Map<String, dynamic>? _user;
  String? _errorMessage;
  Color _primaryColor = const Color(0xFFC084FC);
  ThemeMode _themeMode = ThemeMode.dark;

  AuthProvider() {
    _loadLocalTheme();
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;
  String get role => _user?['role'] ?? 'reader';
  String get userName => _user?['name'] ?? 'User';
  String get userEmail => _user?['email'] ?? '';
  Color get primaryColor => _primaryColor;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

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

      final response = await ApiService.post('auth/register', body: body);
      final data = response.data;

      if (response.success) {
        _token = data['token'];
        _user = data['user'];
        _isLoggedIn = true;
        // Sync token to ApiService so HTTP requests include Bearer header
        if (_token != null) await _api.setToken(_token!);
        await _saveSession();
        notifyListeners();
        return true;
      } else {
        _errorMessage = data == null ? response.message : _extractError(data is Map<String, dynamic> ? data : {});
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Tidak dapat terhubung ke server. Pastikan backend berjalan.';
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
      final response = await ApiService.post('auth/login', body: {'email': email, 'password': password});
      final data = response.data;

      if (response.success) {
        _token = data['token'];
        _user = data['user'];
        _isLoggedIn = true;
        _primaryColor = AppTheme.getColorFromHex(_user?['theme_color']);
        _themeMode = (_user?['theme_preference'] == 'light') ? ThemeMode.light : ThemeMode.dark;
        await _saveLocalTheme();
        // Sync token to ApiService so HTTP requests include Bearer header
        if (_token != null) await _api.setToken(_token!);
        await _saveSession();
        notifyListeners();
        return true;
      } else {
        _errorMessage = data == null ? response.message : _extractError(data is Map<String, dynamic> ? data : {});
        notifyListeners();
        return false;
      }
    } on SocketException {
      _errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      notifyListeners();
      return false;
    } on TimeoutException {
      _errorMessage = 'Koneksi timeout. Silakan coba lagi.';
      notifyListeners();
      return false;
    } on FormatException {
      _errorMessage = 'Format response tidak valid.';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      debugPrint('Login error: $e');
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
    // Sync saved token to ApiService so /auth/me request includes Bearer header
    await _api.setToken(savedToken);

    // Verify token is still valid by calling /auth/me
    try {
      final response = await ApiService.get('auth/me');
      if (response.success) {
        final data = response.data;
        _user = data['user'];
        _isLoggedIn = true;
        _primaryColor = AppTheme.getColorFromHex(_user?['theme_color']);
        _themeMode = (_user?['theme_preference'] == 'light') ? ThemeMode.light : ThemeMode.dark;
        await _saveLocalTheme();
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

  /// Refresh user profile data from server
  Future<bool> refreshProfile() async {
    try {
      final response = await ApiService.get('auth/me');
      if (response.success) {
        final data = response.data;
        _user = data['user'];
        _primaryColor = AppTheme.getColorFromHex(_user?['theme_color']);
        _themeMode = (_user?['theme_preference'] == 'light') ? ThemeMode.light : ThemeMode.dark;
        await _saveLocalTheme();
        await _saveSession();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await ApiService.post('auth/logout', body: {});
    } catch (_) {
      // Ignore network errors on logout
    }
    _token = null;
    _user = null;
    _isLoggedIn = false;
    _errorMessage = null;
    await _api.clearToken();
    await _clearSession();
    notifyListeners();
  }

  // Profile existence helpers
  bool get hasReaderProfile =>
      (_user?['has_reader_profile'] == true) || (_user?['name'] != null && (_user!['name'] as String).isNotEmpty);
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

      final response = await ApiService.post('auth/switch-role', body: body);
      final data = response.data;

      if (response.success) {
        // Update local user data with the fresh user data returned from API
        if (data != null && data['user'] != null) {
          _user = {..._user!, ...data['user']};
          await _saveSession();
        }
        return true;
      } else {
        _errorMessage = _extractError(data is Map<String, dynamic> ? data : {});
        return false;
      }
    } on SocketException {
      _errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      return false;
    } on TimeoutException {
      _errorMessage = 'Koneksi timeout. Silakan coba lagi.';
      return false;
    } catch (e) {
      _errorMessage = 'Tidak dapat memproses permintaan ubah role: ${e.toString()}';
      debugPrint('Switch role error: $e');
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

  /// Load standalone theme (so it persists even if logged out)
  Future<void> _loadLocalTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('theme_preference');
    final savedColor = prefs.getString('theme_color');

    if (savedMode != null) {
      _themeMode = savedMode == 'light' ? ThemeMode.light : ThemeMode.dark;
    }
    if (savedColor != null) {
      _primaryColor = AppTheme.getColorFromHex(savedColor);
    }
    notifyListeners();
  }

  Future<void> _saveLocalTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_preference', _themeMode == ThemeMode.light ? 'light' : 'dark');
    await prefs.setString('theme_color', AppTheme.colorToHex(_primaryColor));
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

  /// Update theme color preference
  Future<bool> updateThemeColor(Color color) async {
    final oldColor = _primaryColor;
    _primaryColor = color;
    notifyListeners();

    try {
      final hex = AppTheme.colorToHex(color);
      final response = await ApiService.post(ApiEndpoints.updateProfile, body: {'theme_color': hex});
      if (response.success) {
        if (_user != null) _user!['theme_color'] = hex;
        await _saveSession();
        await _saveLocalTheme();
        return true;
      } else {
        // Revert on failure
        _primaryColor = oldColor;
        notifyListeners();
        return false;
      }
    } catch (_) {
      _primaryColor = oldColor;
      notifyListeners();
      return false;
    }
  }

  /// Toggle between light and dark theme mode
  Future<bool> toggleThemeMode() async {
    final newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final oldMode = _themeMode;
    _themeMode = newMode;
    notifyListeners();

    try {
      final pref = newMode == ThemeMode.light ? 'light' : 'dark';
      final response = await ApiService.post(ApiEndpoints.updateProfile, body: {'theme_preference': pref});
      if (response.success) {
        if (_user != null) _user!['theme_preference'] = pref;
        await _saveSession();
        await _saveLocalTheme();
        return true;
      } else {
        _themeMode = oldMode;
        notifyListeners();
        return false;
      }
    } catch (_) {
      _themeMode = oldMode;
      notifyListeners();
      return false;
    }
  }
}
