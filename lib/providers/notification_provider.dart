import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initializes notification permissions and FCM token
  Future<void> initialize() async {
    // Request notification permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get current user
    final user = _auth.currentUser;
    if (user != null) {
      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        // Update user document
        await _firestore.collection('Users').doc(user.uid).update({
          'fcmToken': token,
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Sends a notification to admin users
  Future<void> sendNotificationToAdmin({
    required String title,
    required String body,
  }) async {
    try {
      // Get admin's FCM token
      final adminDoc = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'government')
          .limit(1)
          .get();

      if (adminDoc.docs.isNotEmpty) {
        final adminToken = adminDoc.docs.first.data()['fcmToken'];
        if (adminToken != null) {
          // Send notification using Firebase Cloud Functions
          await _firestore.collection('notifications').add({
            'token': adminToken,
            'title': title,
            'body': body,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  /// Sends a notification to a specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      final userDoc = await _firestore.collection('Users').doc(userId).get();
      final userToken = userDoc.data()?['fcmToken'];
      if (userToken != null) {
        await _firestore.collection('notifications').add({
          'token': userToken,
          'title': title,
          'body': body,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error sending notification to user: $e');
    }
  }
}