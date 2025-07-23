class UserModel {
  final String id;
  final String name;
  final String pic;
  final String tagline;
  final String email;
  final String role;
  final bool firstLogin;
  final UserStats stats;

  UserModel({
    required this.id,
    required this.name,
    required this.pic,
    required this.tagline,
    required this.email,
    required this.role,
    required this.firstLogin,
    required this.stats,
  });

  factory UserModel.fromFirestore(doc) {
    final data = doc.data();
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      pic: data['pic'] ?? '',
      tagline: data['tagline'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'player',
      firstLogin: data['firstLogin'] ?? false,
      stats: UserStats.fromMap(data['stats'] ?? {}),
    );
  }
}

class UserStats {
  final int closeRate;
  final int deals;
  final String level;
  final int losses;
  final int points;
  final int sales;
  final List<String> streak;
  final int wins;

  UserStats({
    required this.closeRate,
    required this.deals,
    required this.level,
    required this.losses,
    required this.points,
    required this.sales,
    required this.streak,
    required this.wins,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      closeRate: map['closeRate'] ?? 0,
      deals: map['deals'] ?? 0,
      level: map['level'] ?? '',
      losses: map['losses'] ?? 0,
      points: map['points'] ?? 0,
      sales: map['sales'] ?? 0,
      streak: (map['streak'] is List)
          ? List<String>.from(map['streak'])
          : [],
      wins: map['wins'] ?? 0,
    );
  }
} 