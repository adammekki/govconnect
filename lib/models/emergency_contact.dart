class EmergencyContact {
  final String id;
  final String title;
  final String phoneNumber;
  final String category;
  final String createdBy;

  EmergencyContact({
    required this.id,
    required this.title,
    required this.phoneNumber,
    required this.category,
    required this.createdBy,
  });

  factory EmergencyContact.fromMap(String id, Map<String, dynamic> data) {
    return EmergencyContact(
      id: id,
      title: data['title'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      category: data['category'] ?? '',
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'phoneNumber': phoneNumber,
      'category': category,
      'createdBy': createdBy,
    };
  }
} 