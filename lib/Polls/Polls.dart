// Polls.dart
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'Votes.dart';
import 'PollComment.dart';

class Polls {
  final String pollId;
  final String question;
  final List<String> options;
  final String createdBy;
  final DateTime createdAt;
  final List<Votes> votes;
  final List<PollComment> comments; // Added comments list

  Polls({
    required this.pollId,
    required this.question,
    required this.options,
    required this.createdBy,
    required this.createdAt,
    required this.votes,
    required this.comments, // Added comments parameter
  });

  // Factory method to create a Polls object from Firestore data
  factory Polls.fromFirestore(String id, Map<String, dynamic> data, {List<PollComment> comments = const []}) {
    final votesData = data['votes'] as List<dynamic>? ?? [];
    final votes = votesData.map((vote) {
      return Votes.fromFirestore(vote['voteId'], vote);
    }).toList();

    return Polls(
      pollId: id,
      question: data['question'] as String,
      options: List<String>.from(data['options'] as List),
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      votes: votes,
      comments: comments, // Include the comments
    );
  }
}