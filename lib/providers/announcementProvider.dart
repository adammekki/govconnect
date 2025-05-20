import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:govconnect/screens/announcements/announcements.dart';

class AnnouncementsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Announcement> _announcements = [];
  bool _isLoading = false;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;

  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot =
          await _firestore
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .get();

      _announcements = await Future.wait(
        snapshot.docs.map((doc) async {
          final commentsSnapshot =
              await doc.reference.collection('comments').get();
          final comments =
              commentsSnapshot.docs
                  .map((commentDoc) => Comment.fromMap(commentDoc.data()))
                  .toList();

          return Announcement.fromMap(doc.data(), doc.id, comments);
        }),
      );
    } catch (error) {
      debugPrint('Error fetching announcements: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> _getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userDoc = await _firestore.collection('Users').doc(user.uid).get();
    if (!userDoc.exists) return null;

    return userDoc['role'] as String?;
  }

  Future<void> addComment(
    String announcementId,
    String content,
    bool anonymous,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final role = await _getUserRole();
      if (role != 'citizen') {
        throw Exception('Only citizens can comment');
      }

      if(anonymous == true){
        await _firestore
          .collection('announcements')
          .doc(announcementId)
          .collection('comments')
          .add({
            'userId': user.uid,
            'content': content,
            'anonymous': anonymous,
            'createdAt': Timestamp.now(),
          });
      } else {
        final userSnapshot = await _firestore
          .collection('Users')
          .doc(user.uid)
          .get();

        await _firestore
          .collection('announcements')
          .doc(announcementId)
          .collection('comments')
          .add({
            'userId': user.uid,
            'userName': userSnapshot['fullName'],
            'content': content,
            'anonymous': anonymous,
            'createdAt': Timestamp.now(),
          });
      }

      await fetchAnnouncements();
    } catch (error) {
      debugPrint('Error adding comment: $error');
      rethrow;
    }
  }

  Future<void> createAnnouncement({
    required String title,
    required String description,
    String? mediaUrl,
    String category = 'General',
    String? imageBase64, // <-- Add this
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final role = await _getUserRole();
      if (role != 'government') {
        throw Exception('Only government users can create announcements');
      }

      await _firestore.collection('announcements').add({
        'title': title,
        'description': description,
        'mediaUrl': mediaUrl,
        'createdBy': user.uid,
        'category': category,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'imageBase64': imageBase64, // <-- Add this
      });

      await fetchAnnouncements();
    } catch (error) {
      debugPrint('Error creating announcement: $error');
      rethrow;
    }
  }

  Future<void> updateAnnouncement({
    required String announcementId,
    required String title,
    required String description,
    String? category,
  }) async {
    try {
      final role = await _getUserRole();
      if (role != 'government') {
        throw Exception('Only government users can update announcements');
      }

      await _firestore.collection('announcements').doc(announcementId).update({
        'title': title,
        'description': description,
        if (category != null) 'category': category,
        'updatedAt': Timestamp.now(),
      });

      await fetchAnnouncements();
    } catch (e) {
      debugPrint('Error updating announcement: $e');
      rethrow;
    }
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      final role = await _getUserRole();
      if (role != 'government') {
        throw Exception('Only government users can delete announcements');
      }

      await _firestore.collection('announcements').doc(announcementId).delete();
      await fetchAnnouncements();
    } catch (e) {
      debugPrint('Error deleting announcement: $e');
      rethrow;
    }
  }
}
