import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme.dart';
import 'routes.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SalesBetsApp());
}

class SalesBetsApp extends StatefulWidget {
  const SalesBetsApp({Key? key}) : super(key: key);

  @override
  State<SalesBetsApp> createState() => _SalesBetsAppState();
}

class _SalesBetsAppState extends State<SalesBetsApp> {
  String? _role;
  bool _walkthroughChecked = false;

  Future<void> _handleLogin(String role) async {
    // Fetch user doc and check firstLogin
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: user.email).limit(1).get();
      if (doc.docs.isNotEmpty && (doc.docs.first['firstLogin'] ?? false)) {
        WalkthroughController.start();
      }
    }
    setState(() {
      _role = role;
      _walkthroughChecked = true;
    });
  }

  void _handleLogout() {
    setState(() {
      _role = null;
      _walkthroughChecked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SalesBets',
      theme: salesBetsTheme,
      debugShowCheckedModeBanner: false,
      routes: appRoutes,
      home: _role == null
          ? LoginScreen(onLogin: _handleLogin, onLogout: _handleLogout)
          : MainNavigationScreen(role: _role!, onLogout: _handleLogout),
    );
  }
} 