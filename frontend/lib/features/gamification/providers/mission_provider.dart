import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/mission.dart';

class MissionProvider extends ChangeNotifier {
  List<Mission> _missions = [];
  bool _isLoading = false;
  String? _error;

  List<Mission> get missions => _missions;
  List<Mission> get dailyMissions => _missions.where((m) => m.type == 'daily').toList();
  List<Mission> get weeklyMissions => _missions.where((m) => m.type == 'weekly').toList();
  List<Mission> get onceMissions => _missions.where((m) => m.type == 'once').toList();
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMissions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(ApiEndpoints.missions);
      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map && data['missions'] is List) {
          _missions = (data['missions'] as List).map((m) => Mission.fromJson(m)).toList();
        } else if (data is List) {
          _missions = data.map((m) => Mission.fromJson(m)).toList();
        } else {
          _error = 'Unexpected response format';
        }
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to load missions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> claimMission(int missionId) async {
    try {
      final response = await ApiService.post(ApiEndpoints.claimMission(missionId.toString()));
      if (response.success) {
        await fetchMissions();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Claim all claimable missions at once.
  /// Returns a map with total_xp, total_coins, and claimed_count on success.
  Future<Map<String, dynamic>?> claimAll() async {
    try {
      final response = await ApiService.post(ApiEndpoints.claimAllMissions);
      if (response.success) {
        await fetchMissions(); // Refresh mission states
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
