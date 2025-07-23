import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_model.dart';
import 'team_model.dart';

class MatchModel {
  final String id;
  final dynamic side1; // UserModel or TeamModel
  final dynamic side2; // UserModel or TeamModel
  final int rewardPoints;
  final Timestamp date;
  final String type;

  MatchModel({
    required this.id,
    required this.side1,
    required this.side2,
    required this.rewardPoints,
    required this.date,
    required this.type,
  });

  factory MatchModel.fromFirestore(doc, dynamic side1, dynamic side2) {
    final data = doc.data();
    return MatchModel(
      id: doc.id,
      side1: side1,
      side2: side2,
      rewardPoints: data['rewardPoints'] ?? 0,
      date: data['date'] ?? '',
      type: data['type'] ?? '',
    );
  }
} 