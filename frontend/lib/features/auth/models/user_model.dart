class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? penName;
  final String? avatarUrl;
  final String? authorAvatarUrl;
  final int coins;
  final int level;
  final String authorTier;
  final String themePreference;
  
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.penName,
    this.avatarUrl,
    this.authorAvatarUrl,
    required this.coins,
    required this.level,
    required this.authorTier,
    required this.themePreference,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      penName: json['pen_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      authorAvatarUrl: json['author_avatar_url'] as String?,
      coins: json['coins'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      authorTier: json['author_tier'] as String? ?? 'bronze',
      themePreference: json['theme_preference'] as String? ?? 'light',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'pen_name': penName,
      'avatar_url': avatarUrl,
      'author_avatar_url': authorAvatarUrl,
      'coins': coins,
      'level': level,
      'author_tier': authorTier,
      'theme_preference': themePreference,
    };
  }
  
  String get displayName => role == 'author' && penName != null ? penName! : name;
  String get displayAvatar => role == 'author' && authorAvatarUrl != null ? authorAvatarUrl! : (avatarUrl ?? '');
  bool get isDarkMode => themePreference == 'dark';
}
