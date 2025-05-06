import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class Polls {
  final String pollId;
  final String question;
  final List<String> options;
  final String createdBy;
  final DateTime createdAt;

  Polls({
    required this.pollId,
    required this.question,
    required this.options,
    required this.createdBy,
    required this.createdAt,
  });

  // Factory method to create a Polls object from Firestore data
  factory Polls.fromFirestore(String id, Map<String, dynamic> data) {
    return Polls(
      pollId: id,
      question: data['question'] as String,
      options: List<String>.from(data['options'] as List),
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}




