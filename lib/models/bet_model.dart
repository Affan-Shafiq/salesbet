import 'package:cloud_firestore/cloud_firestore.dart';

class BetModel {
  final String id;
  final String matchId;
  final String sideName;
  final Map<String, dynamic> sideRef;
  final double amount;
  final String userId;
  final DocumentReference userRef;
  final Timestamp timestamp;

  BetModel({
    required this.id,
    required this.matchId,
    required this.sideName,
    required this.sideRef,
    required this.amount,
    required this.userId,
    required this.userRef,
    required this.timestamp,
  });

  factory BetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BetModel(
      id: doc.id,
      matchId: data['matchId'] ?? '',
      sideName: data['side'] ?? '',
      sideRef: Map<String, dynamic>.from(data['sideRef'] ?? {}),
      amount: (data['amount'] ?? 0).toDouble(),
      userId: data['userId'] ?? '',
      userRef: data['userRef'],
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
} 