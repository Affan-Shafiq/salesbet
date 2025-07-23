import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'gamified_interface_screen.dart';
import 'live_competitions_feed.dart';
import 'player_profile_screen.dart';
import 'create_competition_screen.dart';
import 'admin_panel_screen.dart';
import '../theme.dart';
import '../widgets.dart';

class MainNavigationScreen extends StatefulWidget {
  final String role;
  final VoidCallback? onLogout;
  const MainNavigationScreen({Key? key, required this.role, this.onLogout}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  late final List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    if (WalkthroughController.active) {
      _currentIndex = WalkthroughController.screenIndex;
    }
    if (widget.role == 'admin') {
      _screens = [
        DashboardScreen(role: widget.role, walkthrough: true, onWalkthroughNext: _handleWalkthroughNext, onLogout: widget.onLogout),
        GamifiedInterfaceScreen(walkthrough: true, onWalkthroughNext: _handleWalkthroughNext, onLogout: widget.onLogout),
        LiveCompetitionsFeed(walkthrough: true, onWalkthroughNext: _handleWalkthroughNext, onLogout: widget.onLogout),
        PlayerProfileScreen(walkthrough: true, onWalkthroughNext: _handleWalkthroughNext, onLogout: widget.onLogout),
        const CreateCompetitionScreen(),
        const AdminPanelScreen(),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'Gamified'),
        BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Live'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Create'),
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
      ];
    } else {
      _screens = [
        DashboardScreen(role: widget.role, walkthrough: true, onWalkthroughNext: _handleWalkthroughNext, onLogout: widget.onLogout),
        GamifiedInterfaceScreen(walkthrough: true, onWalkthroughNext: _handleWalkthroughNext, onLogout: widget.onLogout),
        LiveCompetitionsFeed(walkthrough: true, onWalkthroughNext: _handleWalkthroughNext, onLogout: widget.onLogout),
        PlayerProfileScreen(walkthrough: true, onWalkthroughNext: _handleWalkthroughNext, onLogout: widget.onLogout),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'Gamified'),
        BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Live'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    }
  }

  void _handleWalkthroughNext() {
    setState(() {
      WalkthroughController.nextStep(_walkthroughSteps);
      _currentIndex = WalkthroughController.screenIndex;
    });
  }

  final List<List<String>> _walkthroughSteps = const [
    [
      'This is the Leaderboard!\n\nSee who is leading in points and rank among all players.',
      'Here are your Stats!\n\nTrack your sales, deals, and points in real time.',
    ],
    [
      'Welcome to the Gamified Interface!\n\nSee badges, rewards, and matchups.',
      'Check out your recent streaks and achievements here.',
    ],
    [
      'Live Competitions!\n\nSee ongoing and upcoming matches here.',
    ],
    [
      'This is your Profile!\n\nView your stats, achievements, and career progress.',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    if (WalkthroughController.active && _currentIndex != WalkthroughController.screenIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentIndex = WalkthroughController.screenIndex;
        });
      });
    }
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.white54,
        items: _navItems,
      ),
    );
  }
} 