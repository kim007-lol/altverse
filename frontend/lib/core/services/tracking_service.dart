import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'api_service.dart';

/// Fire-and-forget tracking service that sends events to the Go microservice.
///
/// This service is intentionally "best effort" — if the Go service is down
/// or the request fails, the app continues normally. Laravel still handles
/// the primary data flow; Go just provides faster, buffered tracking.
class TrackingService {
  TrackingService._();

  /// Track reading progress (page turn).
  /// Called on every page change in the reading screen.
  static Future<void> trackRead({
    required int seriesId,
    required int episodeId,
    required int lastPage,
    required double progress,
  }) async {
    _fireAndForget('/track/read', {
      'series_id': seriesId,
      'episode_id': episodeId,
      'last_page': lastPage,
      'progress': progress,
    });
  }

  /// Track a view event (episode opened).
  /// Called once when an episode is first loaded.
  static Future<void> trackView({
    required int seriesId,
    required int episodeId,
  }) async {
    _fireAndForget('/track/view', {
      'series_id': seriesId,
      'episode_id': episodeId,
    });
  }

  /// Sends a POST request to the Go service without waiting for a response.
  /// If the service is unreachable, the error is silently swallowed.
  static void _fireAndForget(String endpoint, Map<String, dynamic> body) {
    // Run in an isolate-friendly way — don't block UI
    Future(() async {
      try {
        final token = ApiService().token;
        if (token == null) return;

        final uri = Uri.parse('${ApiConstants.imageBaseUrl}$endpoint');
        await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        // Silent fail — Go tracking is "best effort"
        debugPrint('[TrackingService] $endpoint failed (non-critical): $e');
      }
    });
  }
}
