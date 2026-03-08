/// API endpoint constants for AU Reader V2
/// All endpoints are relative to ApiService.baseUrl (/api/v1/)
class ApiEndpoints {
  ApiEndpoints._();

  // ─── Auth ───
  static const String register = 'auth/register';
  static const String login = 'auth/login';
  static const String logout = 'auth/logout';
  static const String me = 'auth/me';
  static const String updateProfile = 'auth/profile';
  static const String switchRole = 'auth/switch-role';

  // ─── Public ───
  static const String genres = 'public/genres';

  // ─── Notifications ───
  static const String notifications = 'notifications';
  static const String notificationsUnreadCount = 'notifications/unread-count';
  static String notificationMarkRead(String id) => 'notifications/$id/read';
  static const String notificationMarkAllRead = 'notifications/read-all';

  // ─── Wallet & Gamification ───
  static const String wallet = 'wallet';
  static const String dailyReward = 'wallet/daily-reward';
  static const String dailyStatus = 'wallet/daily-status';
  static const String missions = 'missions';
  static String claimMission(String code) => 'missions/$code/claim';
  static const String tip = 'wallet/tip';
  static const String badges = 'wallet/badges';
  static String pinBadge(int id) => 'users/badges/$id/pin';
  static const String tierProgress = 'wallet/tier-progress';

  // ─── Episode Unlock ───
  static const String unlockedEpisodes = 'reader/episodes/unlocked';
  static String episodeUnlock(int episodeId) =>
      'reader/episodes/$episodeId/unlock';

  // ─── Comments (per episode) ───
  static String episodeComments(int episodeId) =>
      'episodes/$episodeId/comments';
  static String commentLike(int commentId) => 'comments/$commentId/like';
  static String deleteComment(int commentId) => 'comments/$commentId';
  static const String myComments = 'reader/my-comments';

  // ─── Daily Login XP ───
  static const String dailyLoginClaim = 'daily-login';
  static const String dailyLoginStatus = 'daily-login/status';

  // ─── Reader: FYP & Search ───
  static const String fyp = 'reader/fyp';
  static const String search = 'reader/search';

  // ─── Reader: Bookmarks ───
  static const String bookmarks = 'reader/bookmarks';
  static String bookmarkToggle(int seriesId) =>
      'reader/bookmarks/$seriesId/toggle';
  static String bookmarkCheck(int seriesId) =>
      'reader/bookmarks/$seriesId/check';

  // ─── Reader: Following ───
  static const String following = 'reader/following';
  static const String followers = 'reader/followers';
  static String followToggle(int userId) => 'reader/follow/$userId/toggle';
  static String followCheck(int userId) => 'reader/follow/$userId/check';
  static String authorProfile(int userId) => 'reader/author/$userId/profile';

  // ─── Reader: Reading ───
  static const String readingHistory = 'reader/history';
  static String seriesDetail(int seriesId) => 'reader/series/$seriesId';
  static String readEpisode(int seriesId, int episodeId) =>
      'reader/series/$seriesId/episodes/$episodeId';
  static String updateProgress(int seriesId, int episodeId) =>
      'reader/series/$seriesId/episodes/$episodeId/progress';
  static String likeToggle(int seriesId) => 'reader/series/$seriesId/like';
  static String episodeLikeToggle(int seriesId, int episodeId) =>
      'reader/series/$seriesId/episodes/$episodeId/like';

  // ─── Reader: Collections ───
  static const String collections = 'reader/collections';
  static String collectionDetail(int colId) => 'reader/collections/$colId';
  static String collectionAddSeries(int colId) =>
      'reader/collections/$colId/series';
  static String collectionRemoveSeries(int colId, int seriesId) =>
      'reader/collections/$colId/series/$seriesId';

  // ─── Author: Dashboard & Analytics ───
  static const String authorDashboard = 'author/dashboard';
  static const String authorAnalyticsOverview = 'author/analytics/overview';
  static const String authorAnalyticsTrend = 'author/analytics/trend';
  static const String authorAnalyticsTopSeries = 'author/analytics/top-series';
  static const String authorAnalyticsTopEpisodes =
      'author/analytics/top-episodes';
  static const String authorSeriesCounts = 'author/series-counts';

  // ─── Author: Series CRUD ───
  static const String authorSeries = 'author/series';
  static String authorSeriesUpdate(int seriesId) => 'author/series/$seriesId';
  static String authorSeriesPublish(int seriesId) =>
      'author/series/$seriesId/publish';

  // ─── Author: Episodes ───
  static String authorEpisodes(int seriesId) =>
      'author/series/$seriesId/episodes';
  static String authorEpisodeUpdate(int episodeId) =>
      'author/episodes/$episodeId';
  static String authorEpisodePublish(int episodeId) =>
      'author/episodes/$episodeId/publish';
  static String authorEpisodeDelete(int episodeId) =>
      'author/episodes/$episodeId';

  // ─── Author: Pages (R2 signed URL flow) ───
  static const String authorSignedUrl = 'author/uploads/signed-url';
  static String authorPages(int episodeId) =>
      'author/episodes/$episodeId/pages';
  static String authorPageReplace(int pageId) => 'author/pages/$pageId';
  static String authorPageReorder(int episodeId) =>
      'author/episodes/$episodeId/reorder';
  static String authorPageDelete(int pageId) => 'author/pages/$pageId';

  // ─── Leaderboard ───
  static const String leaderboardOverview = 'leaderboard/overview';
  static const String leaderboardTopXp = 'leaderboard/top-xp';
  static const String leaderboardTopSupporters = 'leaderboard/top-supporters';
  static const String leaderboardTopAuthors = 'leaderboard/top-authors';
  static String leaderboardAuthorSupporters(int authorId) =>
      'leaderboard/author/$authorId/supporters';

  // ─── Reader Profile ───
  static const String readerProfile = 'reader/profile';
  static String readerProfilePublic(int userId) => 'reader/profile/$userId';
}
