import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class CreateCompetitionScreen extends StatefulWidget {
  const CreateCompetitionScreen({Key? key}) : super(key: key);

  @override
  State<CreateCompetitionScreen> createState() => _CreateCompetitionScreenState();
}

class _CreateCompetitionScreenState extends State<CreateCompetitionScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _competitionType = '1v1';
  String _competitionFormat = '';
  double _reward = 100;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  final TextEditingController _side1Controller = TextEditingController();
  final TextEditingController _side2Controller = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _side1Controller.dispose();
    _side2Controller.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<DocumentReference?> _findUserOrTeamRef(String name) async {
    // Try user first
    final userSnap = await FirebaseFirestore.instance.collection('users').where('name', isEqualTo: name).limit(1).get();
    if (userSnap.docs.isNotEmpty) {
      return userSnap.docs.first.reference;
    }
    // Try team
    final teamSnap = await FirebaseFirestore.instance.collection('teams').where('name', isEqualTo: name).limit(1).get();
    if (teamSnap.docs.isNotEmpty) {
      return teamSnap.docs.first.reference;
    }
    return null;
  }

  Future<void> _createCompetition() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    final side1Name = _side1Controller.text.trim();
    final side2Name = _side2Controller.text.trim();
    if (side1Name.isEmpty || side2Name.isEmpty) {
      setState(() {
        _errorText = 'Please enter both opponent names.';
        _isSubmitting = false;
      });
      return;
    }
    final side1Ref = await _findUserOrTeamRef(side1Name);
    final side2Ref = await _findUserOrTeamRef(side2Name);
    if (side1Ref == null || side2Ref == null) {
      setState(() {
        _errorText = 'Could not find one or both opponents.';
        _isSubmitting = false;
      });
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('matches').add({
        'side1': side1Ref,
        'side2': side2Ref,
        'rewardPoints': _reward.round(),
        'type': _typeController.text.trim(),
        'format': _competitionType,
        'date': _selectedDate?.toIso8601String() ?? '',
      });
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Competition Created!')));
        _formKey.currentState?.reset();
        _side1Controller.clear();
        _side2Controller.clear();
        _selectedDate = null;
      }
    } catch (e) {
      setState(() {
        _errorText = 'Failed to create competition.';
        _isSubmitting = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.card,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.card,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        ),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _selectedTime = pickedTime;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Competition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                DropdownButtonFormField<String>(
                  value: _competitionType,
                  decoration: const InputDecoration(
                    labelText: 'Competition Format',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '1v1', child: Text('1v1')),
                    DropdownMenuItem(value: 'Teams', child: Text('Teams')),
                  ],
                  onChanged: (val) => setState(() => _competitionType = val!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _typeController,
                  decoration: const InputDecoration(
                    labelText: 'Competition Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _side1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Opponent 1 Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _side2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Opponent 2 Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Reward', style: Theme.of(context).textTheme.bodyLarge),
                Slider(
                  value: _reward,
                  min: 50,
                  max: 1000,
                  divisions: 19,
                  label: ' ${_reward.round()}',
                  onChanged: (val) => setState(() => _reward = val),
                  activeColor: AppColors.accent,
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: Text(
                    _selectedDate == null
                        ? 'Pick date & time'
                        : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}  Time: ${_selectedTime?.format(context) ?? ''}',
                  ),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                  onTap: _pickDateTime,
                ),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _createCompetition,
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 