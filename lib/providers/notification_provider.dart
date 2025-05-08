import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initializes notification permissions and FCM token
  Future<void> initialize() async {
    // Request notification permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      // Create or update user document
      final userDocRef = _firestore.collection('users').doc('current_user_id');
      final userDoc = await userDocRef.get();
      
      if (!userDoc.exists) {
        // Create new user document
        await userDocRef.set({
          'fcmToken': token,
          'role': 'citizen', // Default role
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing user document
        await userDocRef.update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
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
          .collection('users')
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
      final userDoc = await _firestore.collection('users').doc(userId).get();
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