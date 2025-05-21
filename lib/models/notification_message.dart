import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationMessage {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime createdAt;
  final String userId;  // Added to track which user the notification belongs to
  final Map<String, dynamic>? data;  // Added to store additional notification data

  NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
    required this.userId,
    this.data,
  });

  factory NotificationMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Handle Timestamp conversion
    DateTime createdAtDate;
    if (data['createdAt'] is Timestamp) {
      createdAtDate = (data['createdAt'] as Timestamp).toDate();
    } else {
      createdAtDate = DateTime.now(); // Fallback if timestamp is missing
    }

    return NotificationMessage(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'general',
      read: data['read'] ?? false,
      createdAt: createdAtDate,
      userId: data['userId'] ?? '',
      data: data['data'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'data': data,
    };
  }

  NotificationMessage copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    bool? read,
    DateTime? createdAt,
    String? userId,
    Map<String, dynamic>? data,
  }) {
    return NotificationMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      data: data ?? this.data,
    );
  }
} 