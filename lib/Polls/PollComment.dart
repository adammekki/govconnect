// PollComment.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PollComment {
  final String id;
  final String userId;
  final String content;
  final bool anonymous;
  final DateTime createdAt;

  PollComment({
    required this.id,
    required this.userId,
    required this.content,
    required this.anonymous,
    required this.createdAt,
  });

  factory PollComment.fromFirestore(String id, Map<String, dynamic> data) {
    return PollComment(
      id: id,
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      anonymous: data['anonymous'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}