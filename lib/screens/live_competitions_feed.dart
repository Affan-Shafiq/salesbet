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
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
      .where('date', isLessThan: Timestamp.fromDate(tomorrow))
      .get();
    List<_MatchDisplay> matches = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      dynamic side1 = data['side1'] ?? {};
      dynamic side2 = data['side2'] ?? {};
      debugPrint('side1 type: ${side1.runtimeType}, value: ${side1.toString()}');
      debugPrint('side2 type: ${side2.runtimeType}, value: ${side2.toString()}');
      Map<String, dynamic> side1Map = {};
      Map<String, dynamic> side2Map = {};
      String side1Name = '';
      String side2Name = '';
      // Handle DocumentReference (old) or Map (new)
      if (side1 is DocumentReference) {
        final side1Doc = await side1.get();
        final side1Data = side1Doc.data() as Map<String, dynamic>?;
        side1Name = side1Data?['name'] ?? 'Unknown';
        side1Map = {'name': side1Name, 'odds': 1.0};
      } else if (side1 is Map<String, dynamic>) {
        if (side1['name'] is DocumentReference) {
          final docSnap = await side1['name'].get();
          side1Name = docSnap.data()?['name'] ?? 'Unknown';
          side1Map = Map<String, dynamic>.from(side1);
          side1Map['name'] = side1Name;
        } else {
          side1Name = side1['name'] ?? '';
          side1Map = Map<String, dynamic>.from(side1);
        }
      }
      if (side2 is DocumentReference) {
        final side2Doc = await side2.get();
        final side2Data = side2Doc.data() as Map<String, dynamic>?;
        side2Name = side2Data?['name'] ?? 'Unknown';
        side2Map = {'name': side2Name, 'odds': 1.0};
      } else if (side2 is Map<String, dynamic>) {
        if (side2['name'] is DocumentReference) {
          final docSnap = await side2['name'].get();
          side2Name = docSnap.data()?['name'] ?? 'Unknown';
          side2Map = Map<String, dynamic>.from(side2);
          side2Map['name'] = side2Name;
        } else {
          side2Name = side2['name'] ?? '';
          side2Map = Map<String, dynamic>.from(side2);
        }
      }
      debugPrint('side1Name type: ${side1Name.runtimeType}, value: ${side1Name.toString()}');
      debugPrint('side2Name type: ${side2Name.runtimeType}, value: ${side2Name.toString()}');
      final rewardPoints = data['rewardPoints'] ?? 0;
      final type = data['type'] ?? '';
      matches.add(_MatchDisplay(
        id: doc.id,
        side1Name: side1Name,
        side1Avatar: '',
        side2Name: side2Name,
        side2Avatar: '',
        rewardPoints: rewardPoints,
        type: type,
        side1: side1Map,
        side2: side2Map,
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
    return Theme(
      data: salesBetsTheme,
      child: Scaffold(
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
                              match.side1,
                              match.side2,
                              match.id,
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
      ),
    );
  }

  void _nextWalkthroughStep() {
    if (widget.onWalkthroughNext != null) widget.onWalkthroughNext!();
    setState(() {
      // walkthroughStep++; // This line is no longer needed as WalkthroughOverlayController handles its own state
    });
  }

  Widget _buildBattleCard(String title, String subtitle, String avatar1, String avatar2, Map<String, dynamic> side1, Map<String, dynamic> side2, String matchId) {
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
        trailing: ElevatedButton(
          onPressed: () => _showBetOverlay(context, matchId, side1, side2),
          child: const Text('Bet'),
        ),
      ),
    );
  }

  void _showBetOverlay(BuildContext context, String matchId, Map<String, dynamic> side1, Map<String, dynamic> side2) {
    showDialog(
      context: context,
      builder: (context) {
        int selectedSide = 1;
        TextEditingController amountController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              title: const Text('Place Your Bet'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('${side1['name']} (Odds: ${side1['odds']})'),
                    leading: Radio<int>(
                      value: 1,
                      groupValue: selectedSide,
                      onChanged: (val) => setState(() => selectedSide = val!),
                    ),
                  ),
                  ListTile(
                    title: Text('${side2['name']} (Odds: ${side2['odds']})'),
                    leading: Radio<int>(
                      value: 2,
                      groupValue: selectedSide,
                      onChanged: (val) => setState(() => selectedSide = val!),
                    ),
                  ),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Bet Amount'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text.trim()) ?? 0;
                    if (amount <= 0) return;
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
                    await FirebaseFirestore.instance.collection('bets').add({
                      'matchId': matchId,
                      'side': selectedSide == 1 ? side1['name'] : side2['name'],
                      'sideRef': selectedSide == 1 ? side1 : side2,
                      'amount': amount,
                      'userId': user.uid,
                      'userRef': userRef,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bet placed!')));
                  },
                  child: const Text('Place Bet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _firstName(dynamic name) {
    if (name is String) {
      return name.split(' ').first;
    }
    return 'Unknown';
  }
}

class _SideDisplay {
  final String name;
  final String avatar;
  _SideDisplay({required this.name, required this.avatar});
}

class _MatchDisplay {
  final String id;
  final String side1Name;
  final String side1Avatar;
  final String side2Name;
  final String side2Avatar;
  final int rewardPoints;
  final String type;
  final Map<String, dynamic> side1;
  final Map<String, dynamic> side2;
  _MatchDisplay({
    required this.id,
    required this.side1Name,
    required this.side1Avatar,
    required this.side2Name,
    required this.side2Avatar,
    required this.rewardPoints,
    required this.type,
    required this.side1,
    required this.side2,
  });
} 