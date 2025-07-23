import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String role;
  final bool walkthrough;
  final VoidCallback? onWalkthroughNext;
  final VoidCallback? onLogout;
  const DashboardScreen({Key? key, required this.role, this.walkthrough = false, this.onWalkthroughNext, this.onLogout}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Remove walkthroughStep from here
  late final WalkthroughOverlayController _walkthroughController;

  @override
  void initState() {
    super.initState();
    _walkthroughController = WalkthroughOverlayController(
      walkthrough: widget.walkthrough,
      screenIndex: 0,
      onEnd: _endWalkthrough,
      onNext: widget.onWalkthroughNext,
    );
    _checkFirstLogin();
  }

  Future<void> _checkFirstLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: user.email).limit(1).get();
    if (doc.docs.isNotEmpty && (doc.docs.first['firstLogin'] ?? false)) {
      _walkthroughController.show();
    }
  }

  Future<void> _endWalkthrough() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: user.email).limit(1).get();
    if (doc.docs.isNotEmpty) {
      await doc.docs.first.reference.update({'firstLogin': false});
    }
    _walkthroughController.hide();
  }

  Future<List<UserModel>> fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    // Only include users with role 'player'
    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .where((user) => user.role == 'player')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Competitions Dashboard'),
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
            child: FutureBuilder<List<UserModel>>(
              future: fetchUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error:  {snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }
                final users = snapshot.data!;
                final leaderboard = List<UserModel>.from(users)
                  ..sort((a, b) => b.stats.points.compareTo(a.stats.points));
                final totalSales = users.fold<int>(0, (sum, u) => sum + u.stats.sales);
                final totalDeals = users.fold<int>(0, (sum, u) => sum + u.stats.deals);
                final totalPoints = users.fold<int>(0, (sum, u) => sum + u.stats.points);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Leaderboard', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: leaderboard.length,
                        itemBuilder: (context, i) {
                          final user = leaderboard[i];
                          return SizedBox(
                            height: 120,
                            child: LeaderboardCard(
                              name: user.name,
                              avatarUrl: user.pic.isNotEmpty ? user.pic : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}',
                              rank: i + 1,
                              progress: user.stats.points / (leaderboard.first.stats.points == 0 ? 1 : leaderboard.first.stats.points),
                              points: user.stats.points,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Stats', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 90,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          SizedBox(
                            width: 180,
                            child: StatTile(
                              label: 'Sales',
                              value: '$totalSales',
                              icon: Icons.trending_up,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 180,
                            child: StatTile(
                              label: 'Deals',
                              value: '$totalDeals',
                              icon: Icons.handshake,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 180,
                            child: StatTile(
                              label: 'Points',
                              value: '$totalPoints',
                              icon: Icons.emoji_events,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          WalkthroughOverlayWidget(
            controller: _walkthroughController,
            messages: [
              'This is the Leaderboard!\n\nSee who is leading in points and rank among all players.',
              'Here are your Stats!\n\nTrack your sales, deals, and points in real time.',
            ],
          ),
        ],
      ),
    );
  }
} 