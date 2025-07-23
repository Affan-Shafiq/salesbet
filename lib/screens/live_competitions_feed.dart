import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../models/team_model.dart';
import '../models/match_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../widgets.dart';

class LiveCompetitionsFeed extends StatefulWidget {
  final bool walkthrough;
  final VoidCallback? onWalkthroughNext;
  final VoidCallback? onLogout;
  const LiveCompetitionsFeed({Key? key, this.walkthrough = false, this.onWalkthroughNext, this.onLogout}) : super(key: key);

  @override
  State<LiveCompetitionsFeed> createState() => _LiveCompetitionsFeedState();
}

class _LiveCompetitionsFeedState extends State<LiveCompetitionsFeed> with SingleTickerProviderStateMixin {
  final GlobalKey _textKey = GlobalKey();
  late AnimationController _tickerController;
  double _textWidth = 0;
  double _containerWidth = 0;
  late final WalkthroughOverlayController _walkthroughController;

  @override
  void initState() {
    super.initState();
    _walkthroughController = WalkthroughOverlayController(
      walkthrough: widget.walkthrough,
      screenIndex: 2,
      onEnd: null,
      onNext: widget.onWalkthroughNext,
    );
    if (widget.walkthrough && WalkthroughController.active && WalkthroughController.screenIndex == 2) {
      _walkthroughController.show();
    }
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureText());
  }

  @override
  void dispose() {
    _tickerController.dispose();
    super.dispose();
  }

  void _measureText([String? tickerText]) {
    final RenderBox? textBox = _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (textBox != null && _containerWidth > 0) {
      setState(() {
        _textWidth = textBox.size.width;
      });
      _startTicker();
    }
  }

  void _startTicker() {
    _tickerController.reset();
    _tickerController.repeat();
  }

  Future<List<String>> fetchStreaks() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    List<String> streaks = [];
    for (var doc in snapshot.docs) {
      final user = UserModel.fromFirestore(doc);
      for (var streak in user.stats.streak) {
        streaks.add('${user.name}: $streak');
      }
    }
    return streaks;
  }

  Future<List<_MatchDisplay>> fetchMatches() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final snapshot = await FirebaseFirestore.instance.collection('matches')
      .where('date', isGreaterThanOrEqualTo: today.toIso8601String())
      .where('date', isLessThan: tomorrow.toIso8601String())
      .get();
    List<_MatchDisplay> matches = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final side1Ref = data['side1'];
      final side2Ref = data['side2'];
      final rewardPoints = data['rewardPoints'] ?? 0;
      final type = data['type'] ?? '';
      final side1 = await _resolveSide(side1Ref);
      final side2 = await _resolveSide(side2Ref);
      matches.add(_MatchDisplay(
        side1Name: side1.name,
        side1Avatar: side1.avatar,
        side2Name: side2.name,
        side2Avatar: side2.avatar,
        rewardPoints: rewardPoints,
        type: type,
      ));
    }
    return matches;
  }

  Future<_SideDisplay> _resolveSide(DocumentReference ref) async {
    final doc = await ref.get();
    if (ref.parent.id == 'users') {
      final user = UserModel.fromFirestore(doc);
      return _SideDisplay(
        name: user.name,
        avatar: user.pic.isNotEmpty ? user.pic : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}',
      );
    } else if (ref.parent.id == 'teams') {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name'] ?? 'Team';
      final members = data['members'] as List?;
      String avatar = '';
      if (members != null && members.isNotEmpty && members[0] is DocumentReference) {
        final userDoc = await (members[0] as DocumentReference).get();
        final user = UserModel.fromFirestore(userDoc);
        avatar = user.pic.isNotEmpty ? user.pic : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}';
      }
      return _SideDisplay(name: name, avatar: avatar);
    }
    return _SideDisplay(name: 'Unknown', avatar: '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Competitions'),
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
              children: [
                FutureBuilder<List<String>>(
                  future: fetchStreaks(),
                  builder: (context, snapshot) {
                    final streaks = snapshot.data ?? [];
                    final tickerText = streaks.isNotEmpty ? streaks.join('     •     ') : 'No streaks yet';
                    return Container(
                      // color: AppColors.card, // Remove this line to make background transparent
                      height: 40,
                      child: ClipRect(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (_containerWidth != constraints.maxWidth) {
                              _containerWidth = constraints.maxWidth;
                              WidgetsBinding.instance.addPostFrameCallback((_) => _measureText(tickerText + '     •     ' + tickerText));
                            }
                            return AnimatedBuilder(
                              animation: _tickerController,
                              builder: (context, child) {
                                double start = 0;
                                double end = -_textWidth;
                                double dx = start;
                                if (_textWidth > 0) {
                                  dx = start + (_tickerController.value) * (end - start);
                                  if (_tickerController.value == 1.0) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _tickerController.value = 0.0;
                                    });
                                  }
                                }
                                final fullTicker = tickerText + '     •     ' + tickerText;
                                return Stack(
                                  children: [
                                    Positioned(
                                      left: dx,
                                      top: 0,
                                      child: SizedBox(
                                        height: 40,
                                        child: Text(
                                          fullTicker,
                                          key: _textKey,
                                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.clip,
                                          softWrap: false,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<_MatchDisplay>>(
                    future: fetchMatches(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final matches = snapshot.data ?? [];
                      if (matches.isEmpty) {
                        return const Center(child: Text('No live competitions.'));
                      }
                      return ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (context, i) {
                          final match = matches[i];
                          return _buildBattleCard(
                            '${_firstName(match.side1Name)} vs ${_firstName(match.side2Name)}',
                            'Type: ${match.type}, Reward: ${match.rewardPoints}',
                            match.side1Avatar,
                            match.side2Avatar,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          WalkthroughOverlayWidget(
            controller: _walkthroughController,
            messages: [
              'Matches Today!\n\nSee all the matches scheduled for today.',
            ],
          ),
        ],
      ),
    );
  }

  void _nextWalkthroughStep() {
    if (widget.onWalkthroughNext != null) widget.onWalkthroughNext!();
    setState(() {
      // walkthroughStep++; // This line is no longer needed as WalkthroughOverlayController handles its own state
    });
  }

  Widget _buildBattleCard(String title, String subtitle, String avatar1, String avatar2) {
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatar1.isNotEmpty) CircleAvatar(backgroundImage: NetworkImage(avatar1)),
            if (avatar1.isNotEmpty && avatar2.isNotEmpty) const SizedBox(width: 4),
            if (avatar2.isNotEmpty) CircleAvatar(backgroundImage: NetworkImage(avatar2)),
          ],
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.sports_esports, color: AppColors.primary),
      ),
    );
  }

  String _firstName(String name) {
    return name.split(' ').first;
  }
}

class _SideDisplay {
  final String name;
  final String avatar;
  _SideDisplay({required this.name, required this.avatar});
}

class _MatchDisplay {
  final String side1Name;
  final String side1Avatar;
  final String side2Name;
  final String side2Avatar;
  final int rewardPoints;
  final String type;
  _MatchDisplay({
    required this.side1Name,
    required this.side1Avatar,
    required this.side2Name,
    required this.side2Avatar,
    required this.rewardPoints,
    required this.type,
  });
} 