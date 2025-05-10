import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'Votes.dart';

class Polls {
  final String pollId;
  final String question;
  final List<String> options;
  final String createdBy;
  final DateTime createdAt;
  final List<Votes> votes; // Updated to store a list of Votes objects

  Polls({
    required this.pollId,
    required this.question,
    required this.options,
    required this.createdBy,
    required this.createdAt,
    required this.votes,
  });

  // Factory method to create a Polls object from Firestore data
  factory Polls.fromFirestore(String id, Map<String, dynamic> data) {
    final votesData = data['votes'] as List<dynamic>? ?? [];
    final votes =
        votesData.map((vote) {
          return Votes.fromFirestore(vote['voteId'], vote);
        }).toList();

    return Polls(
      pollId: id,
      question: data['question'] as String,
      options: List<String>.from(data['options'] as List),
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      votes: votes,
    );
  }
}
