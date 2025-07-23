import 'user_model.dart';

class TeamModel {
  final String id;
  final String name;
  final List<UserModel> members;

  TeamModel({
    required this.id,
    required this.name,
    required this.members,
  });

  factory TeamModel.fromFirestore(doc, List<UserModel> members) {
    final data = doc.data();
    return TeamModel(
      id: doc.id,
      name: data['name'] ?? '',
      members: members,
    );
  }
} 