import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../widgets.dart';

class GamifiedInterfaceScreen extends StatefulWidget {
  final bool walkthrough;
  final VoidCallback? onWalkthroughNext;
  final VoidCallback? onLogout;
  const GamifiedInterfaceScreen({Key? key, this.walkthrough = false, this.onWalkthroughNext, this.onLogout}) : super(key: key);

  @override
  State<GamifiedInterfaceScreen> createState() => _GamifiedInterfaceScreenState();
}

class _GamifiedInterfaceScreenState extends State<GamifiedInterfaceScreen> with TickerProviderStateMixin {
  late AnimationController _badgeController;
  late Animation<double> _badgeScale;
  late AnimationController _matchupController;
  late Animation<Offset> _matchupSlide;
  late final WalkthroughOverlayController _walkthroughController;
  int walkthroughStep = 0;

  @override
  void initState() {
    super.initState();
    _walkthroughController = WalkthroughOverlayController(
      walkthrough: widget.walkthrough,
      screenIndex: 1,
      onEnd: null,
      onNext: widget.onWalkthroughNext,
    );
    if (widget.walkthrough && WalkthroughController.active && WalkthroughController.screenIndex == 1) {
      _walkthroughController.show();
    }
    _badgeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _badgeScale = CurvedAnimation(parent: _badgeController, curve: Curves.elasticOut);
    _badgeController.forward();
    _matchupController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _matchupSlide = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(CurvedAnimation(parent: _matchupController, curve: Curves.easeOut));
    _matchupController.forward();
  }

  void _nextWalkthroughStep() {
    if (widget.onWalkthroughNext != null) widget.onWalkthroughNext!();
    setState(() {
      walkthroughStep++;
    });
  }

  @override
  void dispose() {
    _badgeController.dispose();
    _matchupController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _buildMatchMap(Map<String, dynamic> side1, Map<String, dynamic> side2, String type) async {
    String side1Name = 'Unknown';
    String side2Name = 'Unknown';
    String avatar1 = '';
    String avatar2 = '';

    Future<Map<String, String>> resolveNameAndAvatar(DocumentReference ref) async {
      final doc = await ref.get();
      final data = doc.data() as Map<String, dynamic>?;
      if (ref.parent.id == 'users') {
        return {
          'name': data?['name'] ?? 'Unknown',
          'avatar': data?['pic'] ?? '',
        };
      } else if (ref.parent.id == 'teams') {
        return {
          'name': data?['name'] ?? 'Unknown',
          'avatar': '', // Add team avatar logic if needed
        };
      }
      return {'name': 'Unknown', 'avatar': ''};
    }

    if (side1['name'] is DocumentReference) {
      final resolved = await resolveNameAndAvatar(side1['name']);
      side1Name = resolved['name']!;
      avatar1 = resolved['avatar']!;
    } else if (side1['name'] is String) {
      side1Name = side1['name'];
    }

    if (side2['name'] is DocumentReference) {
      final resolved = await resolveNameAndAvatar(side2['name']);
      side2Name = resolved['name']!;
      avatar2 = resolved['avatar']!;
    } else if (side2['name'] is String) {
      side2Name = side2['name'];
    }

    return {
      'side1': side1Name,
      'side2': side2Name,
      'avatar1': avatar1,
      'avatar2': avatar2,
      'type': type,
    };
  }

  Future<List<Map<String, String>>> fetchAllMatches() async {
    final now = DateTime.now();
    final startOfTomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    print('DEBUG: startOfTomorrow = ' + startOfTomorrow.toIso8601String());
    final snapshot = await FirebaseFirestore.instance.collection('matches')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfTomorrow))
      .get();
    print('DEBUG: snapshot.docs.length = ${snapshot.docs.length}');
    List<Future<Map<String, String>>> futureMatches = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final side1 = data['side1'] ?? {};
      final side2 = data['side2'] ?? {};
      final type = data['type'] ?? '';
      final dateField = data['date'];
      DateTime? matchDate;
      if (dateField is Timestamp) {
        matchDate = dateField.toDate();
      } else if (dateField is String && dateField.isNotEmpty) {
        matchDate = DateTime.tryParse(dateField);
      }
      print('DEBUG: matchId=${doc.id}, matchDate=$matchDate, type=${data['type']}');
      print('DEBUG: Included match ${doc.id}');
      futureMatches.add(_buildMatchMap(side1, side2, type));
    }
    final matches = await Future.wait(futureMatches);
    print('DEBUG: Matches list: ' + matches.toString());
    return matches;
  }

  Future<Map<String, String>> _resolveSideWithAvatar(DocumentReference ref) async {
    final doc = await ref.get();
    if (ref.parent.id == 'users') {
      final user = UserModel.fromFirestore(doc);
      return {
        'name': user.name.split(' ').first,
        'avatar': user.pic.isNotEmpty ? user.pic : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}',
      };
    } else if (ref.parent.id == 'teams') {
      final data = doc.data() as Map<String, dynamic>;
      String avatar = '';
      final name = data['name'] ?? 'Team';
      final members = data['members'] as List?;
      if (members != null && members.isNotEmpty && members[0] is DocumentReference) {
        final userDoc = await (members[0] as DocumentReference).get();
        final user = UserModel.fromFirestore(userDoc);
        avatar = user.pic.isNotEmpty ? user.pic : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}';
      }
      return {
        'name': name,
        'avatar': avatar,
      };
    }
    return {'name': 'Unknown', 'avatar': ''};
  }

  Future<List<String>> fetchStreaks() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    List<String> streaks = [];
    for (var doc in snapshot.docs) {
      final user = UserModel.fromFirestore(doc);
      for (var streak in user.stats.streak) {
        streaks.add('${user.name.split(' ').first}: $streak');
      }
    }
    return streaks;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: salesBetsTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gamified Interface'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (widget.onLogout != null) widget.onLogout!();
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<List<Map<String, String>>>(
                    future: fetchAllMatches(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(height: 70, child: Center(child: CircularProgressIndicator()));
                      }
                      final matches = snapshot.data ?? [];
                      print('DEBUG: matches in UI builder: ' + matches.toString());
                      if (matches.isEmpty) {
                        return const SizedBox(height: 70, child: Center(child: Text('No upcoming matches.')));
                      }
                      return Column(
                        children: matches.map((m) =>
                          SlideTransition(
                            position: _matchupSlide,
                            child: Card(
                              color: AppColors.card,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if ((m['avatar1'] ?? '').isNotEmpty) CircleAvatar(backgroundImage: NetworkImage(m['avatar1']!)),
                                    if ((m['avatar1'] ?? '').isNotEmpty && (m['avatar2'] ?? '').isNotEmpty) const SizedBox(width: 4),
                                    if ((m['avatar2'] ?? '').isNotEmpty) CircleAvatar(backgroundImage: NetworkImage(m['avatar2']!)),
                                  ],
                                ),
                                title: Text('${m['side1']} vs ${m['side2']}'),
                                subtitle: Text(m['type'] ?? ''),
                                trailing: const Icon(Icons.sports_kabaddi, color: AppColors.primary),
                              ),
                            ),
                          )
                        ).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text('Badges & Rewards', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ScaleTransition(
                        scale: _badgeScale,
                        child: _buildBadge('Gold', Icons.emoji_events, AppColors.accent),
                      ),
                      ScaleTransition(
                        scale: _badgeScale,
                        child: _buildBadge('MVP', Icons.star, Colors.purpleAccent),
                      ),
                      ScaleTransition(
                        scale: _badgeScale,
                        child: _buildBadge('Streak', Icons.flash_on, Colors.orangeAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text('Recent Streaks', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  FutureBuilder<List<String>>(
                    future: fetchStreaks(),
                    builder: (context, snapshot) {
                      final streaks = snapshot.data ?? [];
                      return SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: streaks.map((s) => _StreakTicker(text: s)).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            WalkthroughOverlayWidget(
              controller: _walkthroughController,
              messages: [
                'Upcoming Matches!\n\nSee all upcoming matches and plan your strategy.',
                'Badges & Rewards!\n\nEarn badges and rewards for your achievements.',
                'Recent Achievements!\n\nCheck out the latest achievements of all players.',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color,
          radius: 28,
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _StreakTicker extends StatefulWidget {
  final String text;
  const _StreakTicker({required this.text});

  @override
  State<_StreakTicker> createState() => _StreakTickerState();
}

class _StreakTickerState extends State<_StreakTicker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(widget.text, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
      ),
    );
  }
} 