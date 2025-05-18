// announcement_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String description;
  final String? mediaUrl;
  final String createdBy;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Comment> comments;
  final String? imageBase64; // <-- Add this

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    this.mediaUrl,
    required this.createdBy,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    required this.comments,
    this.imageBase64, // <-- Add this
  });

  factory Announcement.fromMap(
    Map<String, dynamic> map,
    String id,
    List<Comment> comments,
  ) {
    return Announcement(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      mediaUrl: map['mediaUrl'],
      createdBy: map['createdBy'] ?? '',
      category: map['category'] ?? 'General',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      comments: comments,
      imageBase64: map['imageBase64'] as String?, // <-- Add this
    );
  }
}

class Comment {
  final String userId;
  final String content;
  final bool anonymous;
  final DateTime createdAt;

  Comment({
    required this.userId,
    required this.content,
    required this.anonymous,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
      anonymous: map['anonymous'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
