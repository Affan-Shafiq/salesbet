import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  final void Function(String role)? onLogin;
  final VoidCallback? onLogout;
  const LoginScreen({Key? key, this.onLogin, this.onLogout}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  String? _error;
  bool _isLoading = false;
  bool _isRegister = false;
  bool _showPassword = false;

  Future<void> _login() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Only fetch, do not create user doc for email/password login
      final userDoc = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: cred.user!.email).limit(1).get();
      if (userDoc.docs.isNotEmpty) {
        final role = userDoc.docs.first['role'] ?? 'player';
        widget.onLogin?.call(role);
      } else {
        setState(() => _error = 'No user profile found for this email. Please register first.');
      }
    } catch (e) {
      setState(() => _error = _friendlyAuthError(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });
    try {
      // Check if user with this email already exists in Firestore
      final existing = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: _emailController.text.trim()).limit(1).get();
      if (existing.docs.isNotEmpty) {
        setState(() {
          _error = 'A user with this email already exists.';
          _isLoading = false;
        });
        return;
      }
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Create user doc with default role 'player'
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': _nameController.text.trim(),
        'email': cred.user!.email ?? '',
        'tagline': _taglineController.text.trim(),
        'role': 'player',
        'firstLogin': true,
        'stats': {},
      });
      setState(() {
        _isRegister = false;
        _error = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful! Please log in.')));
      }
    } catch (e) {
      setState(() => _error = _friendlyAuthError(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      final role = await _getOrCreateUserRoleGoogle(cred.user!);
      widget.onLogin?.call(role);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getOrCreateUserRoleGoogle(User user) async {
    // For Google login, create user doc if not exists
    final userDoc = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: user.email).limit(1).get();
    if (userDoc.docs.isNotEmpty) {
      return userDoc.docs.first['role'] ?? 'player';
    } else {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'role': 'player',
        'stats': {},
      });
      return 'player';
    }
  }

  String _friendlyAuthError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('user-not-found')) return 'No user found for that email.';
    if (msg.contains('wrong-password')) return 'Wrong password provided.';
    if (msg.contains('invalid-email')) return 'Invalid email address.';
    if (msg.contains('email-already-in-use')) return 'Email is already in use.';
    if (msg.contains('weak-password')) return 'Password is too weak.';
    return 'Authentication failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: salesBetsTheme,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Login'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('SalesBet', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.card,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  if (_isRegister) ...[
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppColors.card,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _taglineController,
                      decoration: InputDecoration(
                        labelText: 'Tagline',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppColors.card,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                  ],
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.card,
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    obscureText: !_showPassword,
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : (_isRegister ? _register : _login),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(_isRegister ? 'Register' : 'Login', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isRegister ? 'Already have an account?' : 'Don\'t have an account?', style: Theme.of(context).textTheme.bodyMedium),
                      TextButton(
                        onPressed: _isLoading ? null : () => setState(() => _isRegister = !_isRegister),
                        child: Text(_isRegister ? 'Login' : 'Register'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Image.asset('assets/google_logo.png', height: 24),
                      label: const Text('Continue with Google'),
                      onPressed: _isLoading ? null : _googleLogin,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }
} 