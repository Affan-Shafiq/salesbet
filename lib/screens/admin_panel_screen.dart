import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  Future<List<Map<String, dynamic>>> fetchPlayers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'player').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
  }

  Future<List<Map<String, dynamic>>> fetchTeams() async {
    final snapshot = await FirebaseFirestore.instance.collection('teams').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
  }

  Future<void> removePlayer(String id) async {
    await FirebaseFirestore.instance.collection('users').doc(id).delete();
    setState(() {});
  }

  Future<void> removeTeam(String id) async {
    await FirebaseFirestore.instance.collection('teams').doc(id).delete();
    setState(() {});
  }

  Future<void> addPlayerToTeam(String teamId, String playerId) async {
    final teamRef = FirebaseFirestore.instance.collection('teams').doc(teamId);
    final teamDoc = await teamRef.get();
    List members = (teamDoc.data()?['members'] ?? []) as List;
    if (!members.contains(FirebaseFirestore.instance.collection('users').doc(playerId))) {
      members.add(FirebaseFirestore.instance.collection('users').doc(playerId));
      await teamRef.update({'members': members});
      setState(() {});
    }
  }

  Future<void> addTeam(String name) async {
    await FirebaseFirestore.instance.collection('teams').add({'name': name, 'members': []});
    setState(() {});
  }

  Future<void> renameTeam(String teamId, String newName) async {
    await FirebaseFirestore.instance.collection('teams').doc(teamId).update({'name': newName});
    setState(() {});
  }

  Future<void> removeMemberFromTeam(String teamId, String memberId) async {
    final teamRef = FirebaseFirestore.instance.collection('teams').doc(teamId);
    final teamDoc = await teamRef.get();
    List members = (teamDoc.data()?['members'] ?? []) as List;
    members.removeWhere((m) => (m as DocumentReference).id == memberId);
    await teamRef.update({'members': members});
    setState(() {});
  }

  void _showTeamMembersDialog(BuildContext context, String teamId, List members) async {
    final allPlayers = await fetchPlayers();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Team Members'),
          content: SizedBox(
            width: 300,
            child: members.isEmpty
                ? const Text('No members in this team.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: members.map<Widget>((m) {
                      final memberId = (m as DocumentReference).id;
                      final player = allPlayers.firstWhere(
                        (p) => p['id'] == memberId,
                        orElse: () => {},
                      );
                      final firstName = (player['name'] ?? '').toString().split(' ').first;
                      return Row(
                        children: [
                          Expanded(child: Text(firstName)),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: AppColors.danger, size: 20),
                            tooltip: 'Remove from Team',
                            onPressed: () async {
                              await removeMemberFromTeam(teamId, memberId);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: salesBetsTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Players List (Top)
              Expanded(
                flex: 1,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchPlayers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final players = snapshot.data ?? [];
                    if (players.isEmpty) {
                      return const Center(child: Text('No players found.'));
                    }
                    return ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final player = players[index];
                        final firstName = (player['name'] ?? '').toString().split(' ').first;
                        return Card(
                          color: AppColors.card,
                          child: ListTile(
                            title: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(firstName, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            subtitle: Text(player['email'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: AppColors.danger),
                              onPressed: () => removePlayer(player['id']),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Teams List (Bottom)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Teams', style: Theme.of(context).textTheme.titleLarge),
                        IconButton(
                          icon: const Icon(Icons.add, color: AppColors.primary),
                          tooltip: 'Add Team',
                          onPressed: () async {
                            final name = await showDialog<String>(
                              context: context,
                              builder: (context) {
                                final controller = TextEditingController();
                                return AlertDialog(
                                  title: const Text('Add Team'),
                                  content: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(labelText: 'Team Name'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, controller.text.trim()),
                                      child: const Text('Add'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (name != null && name.isNotEmpty) {
                              await addTeam(name);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: fetchTeams(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final teams = snapshot.data ?? [];
                          if (teams.isEmpty) {
                            return const Center(child: Text('No teams found.'));
                          }
                          return ListView.builder(
                            itemCount: teams.length,
                            itemBuilder: (context, index) {
                              final team = teams[index];
                              final members = (team['members'] as List?) ?? [];
                              return Card(
                                color: AppColors.card,
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Text(team['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _showTeamMembersDialog(context, team['id'], members),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppColors.info),
                                        tooltip: 'Rename Team',
                                        onPressed: () async {
                                          final newName = await showDialog<String>(
                                            context: context,
                                            builder: (context) {
                                              final controller = TextEditingController(text: team['name'] ?? '');
                                              return AlertDialog(
                                                title: const Text('Rename Team'),
                                                content: TextField(
                                                  controller: controller,
                                                  decoration: const InputDecoration(labelText: 'Team Name'),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(context, controller.text.trim()),
                                                    child: const Text('Rename'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          if (newName != null && newName.isNotEmpty) {
                                            await renameTeam(team['id'], newName);
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.group_add, color: AppColors.primary),
                                        tooltip: 'Add Player',
                                        onPressed: () async {
                                          final allPlayers = await fetchPlayers();
                                          final allTeams = await fetchTeams();
                                          // Collect all player IDs who are already in any team
                                          final Set<String> assignedPlayerIds = {};
                                          for (final team in allTeams) {
                                            final members = (team['members'] as List?) ?? [];
                                            assignedPlayerIds.addAll(members.map((m) => (m as DocumentReference).id));
                                          }
                                          // Only show players not in any team
                                          final availablePlayers = allPlayers.where((p) => !assignedPlayerIds.contains(p['id'])).toList();
                                          if (availablePlayers.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No available players to add.')));
                                            return;
                                          }
                                          final player = await showDialog<Map<String, dynamic>?>(
                                            context: context,
                                            builder: (context) {
                                              return SimpleDialog(
                                                title: const Text('Add Player to Team'),
                                                children: availablePlayers.map((p) => SimpleDialogOption(
                                                  onPressed: () => Navigator.pop(context, p),
                                                  child: Text((p['name'] ?? '').toString().split(' ').first),
                                                )).toList(),
                                              );
                                            },
                                          );
                                          if (player != null) {
                                            await addPlayerToTeam(team['id'], player['id']);
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle, color: AppColors.danger),
                                        onPressed: () => removeTeam(team['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}