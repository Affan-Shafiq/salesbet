import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets.dart';
import '../theme.dart';
import '../models/user_model.dart';
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
    return Scaffold(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(user.pic.isNotEmpty ? user.pic : 'https://ui-avatars.com/api/?name=Chris'),
                        radius: 48,
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
    );
  }
} 