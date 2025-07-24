import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../models/bet_model.dart';
import 'login_screen.dart';

class PlayerProfileScreen extends StatefulWidget {
  final bool walkthrough;
  final VoidCallback? onWalkthroughNext;
  final VoidCallback? onLogout;
  const PlayerProfileScreen({Key? key, this.walkthrough = false, this.onWalkthroughNext, this.onLogout}) : super(key: key);

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late final WalkthroughOverlayController _walkthroughController;
  int walkthroughStep = 0;

  Future<UserModel?> fetchProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return UserModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  Future<List<BetModel>> fetchUserBets() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('bets')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => BetModel.fromFirestore(doc)).toList();
  }

  Future<Map<String, dynamic>?> fetchMatchDetails(String matchId) async {
    final doc = await FirebaseFirestore.instance.collection('matches').doc(matchId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return {
      'type': data['type'] ?? '',
      'date': data['date'],
      'side1': data['side1'],
      'side2': data['side2'],
    };
  }

  String _avatarUrl(String name, String pic) {
    if (pic.isNotEmpty && (pic.startsWith('http://') || pic.startsWith('https://'))) {
      return pic;
    }
    // Use initials avatar
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join();
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(initials)}&background=1976D2&color=fff&size=128';
  }

  @override
  void initState() {
    super.initState();
    _walkthroughController = WalkthroughOverlayController(
      walkthrough: widget.walkthrough,
      screenIndex: 3,
      onEnd: _endWalkthrough,
      onNext: widget.onWalkthroughNext,
    );
    if (widget.walkthrough && WalkthroughController.active && WalkthroughController.screenIndex == 3) {
      _walkthroughController.show();
    }
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    if (widget.walkthrough && WalkthroughController.active && WalkthroughController.screenIndex == 3) {
      walkthroughStep = WalkthroughController.stepIndex + 1;
    }
  }

  void _nextWalkthroughStep() async {
    if (widget.onWalkthroughNext != null) widget.onWalkthroughNext!();
    setState(() {
      walkthroughStep++;
    });
    // End walkthrough and set firstLogin to false in Firestore
    if (WalkthroughController.screenIndex == 3 && !WalkthroughController.active) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: user.email).limit(1).get();
        if (doc.docs.isNotEmpty) {
          await doc.docs.first.reference.update({'firstLogin': false});
        }
      }
    }
  }

  Future<void> _endWalkthrough() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: user.email).limit(1).get();
      if (doc.docs.isNotEmpty) {
        await doc.docs.first.reference.update({'firstLogin': false});
      }
    }
    _walkthroughController.hide();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: salesBetsTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Player Profile'),
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
            FutureBuilder<UserModel?>(
              future: fetchProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: \\${snapshot.error}'));
                }
                final user = snapshot.data;
                if (user == null) {
                  return const Center(child: Text('User not found.'));
                }
                return FadeTransition(
                  opacity: _fadeIn,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView(
                      children: [
                        Center(
                          child: ClipOval(
                            child: Image.network(
                              _avatarUrl(user.name, user.pic),
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 96,
                                height: 96,
                                color: AppColors.card,
                                child: Icon(Icons.person, size: 48, color: AppColors.subtitle),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(user.tagline, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 90,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              SizedBox(
                                width: 180,
                                child: StatTile(
                                  label: 'Wins',
                                  value: '${user.stats.wins}',
                                  icon: Icons.emoji_events,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 180,
                                child: StatTile(
                                  label: 'Losses',
                                  value: '${user.stats.losses}',
                                  icon: Icons.close,
                                  color: AppColors.danger,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 180,
                                child: StatTile(
                                  label: 'Close Rate',
                                  value: '${user.stats.closeRate}%',
                                  icon: Icons.percent,
                                  color: AppColors.info,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 180,
                                child: StatTile(
                                  label: 'Deals',
                                  value: '${user.stats.deals}',
                                  icon: Icons.handshake,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 180,
                                child: StatTile(
                                  label: 'Points',
                                  value: '${user.stats.points}',
                                  icon: Icons.emoji_events,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 180,
                                child: StatTile(
                                  label: 'Sales',
                                  value: '${user.stats.sales}',
                                  icon: Icons.trending_up,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Career Progress', style: Theme.of(context).textTheme.titleLarge),
                        ),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: user.stats.points / 2000), // Assume 2000 is max points for demo
                          duration: const Duration(seconds: 1),
                          builder: (context, value, child) => LinearProgressIndicator(
                            value: value,
                            color: AppColors.primary,
                            backgroundColor: Colors.white12,
                            minHeight: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(user.stats.level, style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 16),
                        if (user.stats.streak.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Achievements', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              ...user.stats.streak.map((s) => Text(
                                s,
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              )).toList(),
                            ],
                          ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Bets Placed', style: Theme.of(context).textTheme.titleLarge),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<List<BetModel>>(
                          future: fetchUserBets(),
                          builder: (context, betSnapshot) {
                            if (betSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (betSnapshot.hasError) {
                              return Text('Error loading bets: \\${betSnapshot.error}');
                            }
                            final bets = betSnapshot.data ?? [];
                            if (bets.isEmpty) {
                              return const Text('No bets placed yet.');
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: bets.length,
                              itemBuilder: (context, i) {
                                final bet = bets[i];
                                return FutureBuilder<Map<String, dynamic>?>(
                                  future: fetchMatchDetails(bet.matchId),
                                  builder: (context, matchSnapshot) {
                                    if (matchSnapshot.connectionState == ConnectionState.waiting) {
                                      return const Card(
                                        color: AppColors.card,
                                        margin: EdgeInsets.symmetric(vertical: 6),
                                        child: ListTile(title: Text('Loading match...')),
                                      );
                                    }
                                    final match = matchSnapshot.data;
                                    if (match == null) {
                                      return Card(
                                        color: AppColors.card,
                                        margin: const EdgeInsets.symmetric(vertical: 6),
                                        child: ListTile(title: Text('Match not found')),
                                      );
                                    }
                                    final type = match['type'] ?? '';
                                    final dateStr = match['date'] ?? '';
                                    DateTime? matchDate;
                                    if (dateStr is Timestamp) {
                                      matchDate = dateStr.toDate();
                                    } else if (dateStr is String && dateStr.isNotEmpty) {
                                      matchDate = DateTime.tryParse(dateStr);
                                    }
                                    String formattedDate = matchDate != null ? '${matchDate.year}-${matchDate.month.toString().padLeft(2, '0')}-${matchDate.day.toString().padLeft(2, '0')} ${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}' : 'Unknown Date';
                                    String sideName = bet.sideName;
                                    // If side1/side2 is a map, try to resolve the name
                                    if (match['side1'] is Map && (match['side1']['name'] == bet.sideName || match['side2']['name'] == bet.sideName)) {
                                      sideName = bet.sideName;
                                    } else if (match['side1'] is Map && match['side1']['name'] is String && bet.sideName is! String) {
                                      sideName = match['side1']['name'];
                                    }
                                    return Card(
                                      color: AppColors.card,
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      child: ListTile(
                                        title: Text('Match Type: $type'),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Side: $sideName'),
                                            Text('Amount: ${bet.amount.toStringAsFixed(2)}'),
                                            Text('Date: $formattedDate'),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            WalkthroughOverlayWidget(
              controller: _walkthroughController,
              messages: [
                'Your Stats!\n\nView your personal stats and performance.',
                'Career Progress!\n\nTrack your career growth and milestones.',
                'Player Streaks!\n\nSee your current and best streaks.',
              ],
            ),
          ],
        ),
      ),
    );
  }
} 