import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';
import '../../features/auth/models/user_model.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isReader => _currentUser?.role == 'reader';
  bool get isAuthor => _currentUser?.role == 'author';
  
  Future<void> init() async {
    await _api.loadToken();
    if (_api.isAuthenticated) {
      await getCurrentUser();
    }
  }
  
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    final response = await ApiService.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
    );
    
    _isLoading = false;
    
    if (response.success) {
      final token = response.data['token'];
      await _api.setToken(token);
      _currentUser = UserModel.fromJson(response.data['user']);
      notifyListeners();
      return true;
    } else {
      _error = response.message;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    String? penName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'role': role,
      'pen_name': ?penName,
    };
    
    final response = await ApiService.post(ApiConstants.register, body: body);
    
    _isLoading = false;
    
    if (response.success) {
      final token = response.data['token'];
      await _api.setToken(token);
      _currentUser = UserModel.fromJson(response.data['user']);
      notifyListeners();
      return true;
    } else {
      _error = response.message;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> getCurrentUser() async {
    final response = await ApiService.get(ApiConstants.me);
    
    if (response.success) {
      _currentUser = UserModel.fromJson(response.data);
      notifyListeners();
      return true;
    } else {
      if (response.isUnauthorized) {
        await logout();
      }
      return false;
    }
  }
  
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    
    final response = await ApiService.put(ApiConstants.updateProfile, body: data);
    
    _isLoading = false;
    
    if (response.success) {
      _currentUser = UserModel.fromJson(response.data['user']);
      notifyListeners();
      return true;
    } else {
      _error = response.message;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> switchRole(String role, {String? penName}) async {
    _isLoading = true;
    notifyListeners();
    
    final body = {
      'role': role,
      'pen_name': ?penName,
    };
    
    final response = await ApiService.post(ApiConstants.switchRole, body: body);
    
    _isLoading = false;
    
    if (response.success) {
      _currentUser = UserModel.fromJson(response.data['user']);
      notifyListeners();
      return true;
    } else {
      _error = response.message;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    await ApiService.post(ApiConstants.logout);
    await _api.clearToken();
    _currentUser = null;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
