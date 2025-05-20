import 'package:cloud_firestore/cloud_firestore.dart';

class Votes {
  final String voteId;
  final String userId;
  final String selectedOption;
  final DateTime createdAt;

  Votes({
    required this.voteId,
    required this.userId,
    required this.selectedOption,
    required this.createdAt,
  });

  // Factory method to create a Votes object from Firestore data
  factory Votes.fromFirestore(String id, Map<String, dynamic> data) {
    return Votes(
      voteId: id,
      userId: data['userId'] as String,
      selectedOption: data['selectedOption'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
