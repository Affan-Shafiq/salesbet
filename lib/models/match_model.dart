import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_model.dart';
import 'team_model.dart';

class MatchModel {
  final String id;
  final Map<String, dynamic> side1; // {'name': String, 'odds': double}
  final Map<String, dynamic> side2; // {'name': String, 'odds': double}
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

  factory MatchModel.fromFirestore(doc) {
    final data = doc.data();
    return MatchModel(
      id: doc.id,
      side1: Map<String, dynamic>.from(data['side1'] ?? {}),
      side2: Map<String, dynamic>.from(data['side2'] ?? {}),
      rewardPoints: data['rewardPoints'] ?? 0,
      date: data['date'] ?? '',
      type: data['type'] ?? '',
    );
  }
} 