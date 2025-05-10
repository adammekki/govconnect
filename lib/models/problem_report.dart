import 'package:cloud_firestore/cloud_firestore.dart';

class ProblemReport {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String? imageUrl;
  final GeoPoint location;
  final String status;
  final DateTime createdAt;

  ProblemReport({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.location,
    required this.status,
    required this.createdAt,
  });

  factory ProblemReport.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProblemReport(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      location: data['location'] ?? GeoPoint(0, 0),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'location': location,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
} 