class Mission {
  final int id;
  final String name;
  final String description;
  final String type; // 'daily', 'weekly', 'once'
  final int targetCount;
  final int xpReward;
  final int coinReward;
  final int progress;
  final bool isCompleted;
  final bool isClaimed;
  final bool canClaim;

  Mission({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.targetCount,
    required this.xpReward,
    required this.coinReward,
    required this.progress,
    required this.isCompleted,
    required this.isClaimed,
    required this.canClaim,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'once',
      targetCount: json['target_count'] ?? 1,
      xpReward: json['xp_reward'] ?? 0,
      coinReward: json['coin_reward'] ?? 0,
      progress: json['progress'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      isClaimed: json['is_claimed'] ?? false,
      canClaim: json['can_claim'] ?? false,
    );
  }
}
