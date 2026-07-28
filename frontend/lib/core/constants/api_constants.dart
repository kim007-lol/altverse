import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.20.10.52:8000/api/v1';

  static String get imageBaseUrl =>
      dotenv.env['API_IMAGE_URL'] ?? 'http://10.20.10.52:8000';
  

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/profile';
  static const String switchRole = '/auth/switch-role';
  
  // Reader endpoints
  static const String fyp = '/reader/fyp';
  static const String search = '/reader/search';
  static const String searchSuggestions = '/reader/search/suggestions';
  static const String searchHistory = '/reader/search/history';
  static const String myProfile = '/reader/profile';
  static const String readingHistory = '/reader/history';
  static const String bookmarks = '/reader/bookmarks';
  static const String collections = '/reader/collections';
  static const String unlockedEpisodes = '/reader/episodes/unlocked';
  static const String myComments = '/reader/my-comments';
  static const String following = '/reader/following';
  static const String followers = '/reader/followers';
  
  // Series & Episodes
  static String seriesDetail(int seriesId) => '/reader/series/$seriesId';
  static String readEpisode(int seriesId, int episodeId) => '/reader/series/$seriesId/episodes/$episodeId';
  static String toggleSeriesLike(int seriesId) => '/reader/series/$seriesId/like';
  static String toggleEpisodeLike(int seriesId, int episodeId) => '/reader/series/$seriesId/episodes/$episodeId/like';
  static String updateProgress(int seriesId, int episodeId) => '/reader/series/$seriesId/episodes/$episodeId/progress';
  static String unlockEpisode(int episodeId) => '/reader/episodes/$episodeId/unlock';
  
  // Bookmarks & Collections
  static String toggleBookmark(int seriesId) => '/reader/bookmarks/$seriesId/toggle';
  static String checkBookmark(int seriesId) => '/reader/bookmarks/$seriesId/check';
  static String collectionDetail(int collectionId) => '/reader/collections/$collectionId';
  static String addToCollection(int collectionId) => '/reader/collections/$collectionId/series';
  static String removeFromCollection(int collectionId, int seriesId) => '/reader/collections/$collectionId/series/$seriesId';
  
  // Follow
  static String toggleFollow(int userId) => '/reader/follow/$userId/toggle';
  static String checkFollow(int userId) => '/reader/follow/$userId/check';
  static String publicProfile(int userId) => '/reader/profile/$userId';
  static String authorProfile(int userId) => '/reader/author/$userId/profile';
  
  // Comments
  static String episodeComments(int episodeId) => '/episodes/$episodeId/comments';
  static String toggleCommentLike(int commentId) => '/comments/$commentId/like';
  static String deleteComment(int commentId) => '/comments/$commentId';
  
  // Wallet
  static const String wallet = '/wallet';
  static const String dailyStatus = '/wallet/daily-status';
  static const String claimDailyReward = '/wallet/daily-reward';
  static const String sendTip = '/wallet/tip';
  static const String badges = '/wallet/badges';
  static const String tierProgress = '/wallet/tier-progress';
  
  // Missions
  static const String missions = 'missions';
  static String claimMission(int missionId) => 'missions/$missionId/claim';
  static const String claimAllMissions = 'missions/claim-all';
  
  // Gamification
  static const String gamificationDailyStatus = '/gamification/daily-status';
  
  // Leaderboard
  static const String leaderboardOverview = '/leaderboard/overview';
  static const String topXp = '/leaderboard/top-xp';
  static const String topSupporters = '/leaderboard/top-supporters';
  static const String topAuthors = '/leaderboard/top-authors';
  static String authorSupporters(int authorId) => '/leaderboard/author/$authorId/supporters';
  
  // Notifications
  static const String notifications = '/notifications';
  static const String unreadCount = '/notifications/unread-count';
  static String markRead(String notificationId) => '/notifications/$notificationId/read';
  static const String markAllRead = '/notifications/read-all';
  static const String notificationPreferences = '/notifications/preferences';
  static const String cleanupNotifications = '/notifications/cleanup';
  
  // Reports
  static const String reports = '/reports';
  static const String reportReasons = '/reports/reasons';
  static String reportDetail(int reportId) => '/reports/$reportId';
  
  // Author endpoints
  static const String authorDashboard = '/author/dashboard';
  static const String authorSeriesCounts = '/author/series-counts';
  static const String authorSeries = '/author/series';
  static String authorSeriesDetail(int seriesId) => '/author/series/$seriesId';
  static String publishSeries(int seriesId) => '/author/series/$seriesId/publish';
  static String seriesEpisodes(int seriesId) => '/author/series/$seriesId/episodes';
  static String updateEpisode(int episodeId) => '/author/episodes/$episodeId';
  static String deleteEpisode(int episodeId) => '/author/episodes/$episodeId';
  static String publishEpisode(int episodeId) => '/author/episodes/$episodeId/publish';
  
  // Pages
  static const String generateSignedUrl = '/author/uploads/signed-url';
  static String episodePages(int episodeId) => '/author/episodes/$episodeId/pages';
  static String reorderPages(int episodeId) => '/author/episodes/$episodeId/reorder';
  static String replacePage(int pageId) => '/author/pages/$pageId';
  static String deletePage(int pageId) => '/author/pages/$pageId';
  
  // Analytics
  static const String analyticsOverview = '/author/analytics/overview';
  static const String analyticsTrend = '/author/analytics/trend';
  static const String analyticsTopSeries = '/author/analytics/top-series';
  static const String analyticsTopEpisodes = '/author/analytics/top-episodes';
  static const String analyticsEngagement = '/author/analytics/engagement';
  static const String analyticsExport = '/author/analytics/export';
  
  // Public
  static const String genres = '/public/genres';
  
  // Top-Up (Reader)
  static const String topupPackages = '/reader/topup/packages';
  static const String topupHistory = '/reader/topup/history';
  static const String topupCreate = '/reader/topup/create';
  static const String topupCheckStatus = '/reader/topup/check-status';
  
  // Withdrawal (Author)
  static const String withdrawals = '/author/withdrawals';
}
