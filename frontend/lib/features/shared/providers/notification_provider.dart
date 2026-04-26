import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';

class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchUnreadCount() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get(ApiEndpoints.notificationsUnreadCount);
      if (response.success && response.data != null) {
        _unreadCount = response.data['unread_count'] ?? 0;
      }
    } catch (e) {
      // Ignore error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void decrementUnreadCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  void clearUnreadCount() {
    if (_unreadCount > 0) {
      _unreadCount = 0;
      notifyListeners();
    }
  }
}
