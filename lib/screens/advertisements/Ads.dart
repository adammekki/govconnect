import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final String id;
  final String postedBy;
  final String title;
  final String imageUrl;
  final String description;
  final bool isApproved;
  final Timestamp createdAt;
  final String? imageBase64; // <-- Add this line

  AdModel({
    required this.id,
    required this.postedBy,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.isApproved,
    required this.createdAt,
    this.imageBase64, // <-- Add this line
  });

  factory AdModel.fromJson(Map<String, dynamic> json, String id) {
    return AdModel(
      id: id,
      postedBy: json['postedBy'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      isApproved: json['isApproved'] ?? false,
      createdAt: json['createdAt'] ?? Timestamp.now(),
      imageBase64: json['imageBase64'] as String?, // <-- Add this line
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postedBy': postedBy,
      'title': title,
      'imageUrl': imageUrl,
      'description': description,
      'isApproved': isApproved,
      'createdAt': createdAt,
      'imageBase64': imageBase64, // <-- Add this line
    };
  }
}
