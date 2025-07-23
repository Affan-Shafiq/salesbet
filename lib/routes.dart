import 'package:flutter/material.dart';
import 'main.dart';
import 'screens/player_profile_screen.dart';
import 'screens/live_competitions_feed.dart';
import 'screens/create_competition_screen.dart';
import 'screens/gamified_interface_screen.dart';
import 'screens/admin_panel_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  // '/dashboard': (context) => DashboardScreen(), // Removed, requires role
  '/profile': (context) => const PlayerProfileScreen(),
  '/live': (context) => const LiveCompetitionsFeed(),
  '/create': (context) => const CreateCompetitionScreen(),
  '/gamified': (context) => const GamifiedInterfaceScreen(),
  '/admin': (context) => const AdminPanelScreen(),
}; 