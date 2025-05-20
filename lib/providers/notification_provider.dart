import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:govconnect/screens/notifications/notifications_card.dart';
import 'package:provider/provider.dart';
import '../models/notification_message.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  List<NotificationMessage> _notifications = [];
  bool _isLoading = false;

  List<NotificationMessage> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  NotificationProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      // Store the token in Firestore for the current user
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('Users').doc(user.uid).update({
          'fcmToken': token,
        });
      }
    }

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        loadNotifications();
      } else {
        _notifications = [];
        notifyListeners();
      }
    });

    // Handle incoming messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleNewNotification(message);
    });
  }

  void _handleNewNotification(RemoteMessage message) {
    final notification = NotificationMessage(
      id: message.messageId ?? DateTime.now().toString(),
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      type: message.data['type'] ?? 'general',
      read: false,
      createdAt: DateTime.now(),
      userId: _auth.currentUser?.uid ?? '',
    );

    _notifications.insert(0, notification);
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('DEBUG: No user logged in');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      print('DEBUG: Loading notifications for user: ${user.uid}');
      print('DEBUG: Current user UID: ${user.uid}');

      // First check if the user is a government official
      final userDoc = await _firestore.collection('Users').doc(user.uid).get();
      final isGovernment = userDoc.data()?['role'] == 'government';
      print('DEBUG: User is government: $isGovernment');

      // Get notifications
      Query query;
      
      if (isGovernment) {
        print('DEBUG: Fetching all problem report notifications for government user');
        // Simplified query that doesn't require a composite index
        query = _firestore.collection('notifications')
            .where('type', isEqualTo: 'problem_report');
            // We'll sort the results in memory instead
      } else {
        print('DEBUG: Fetching user-specific notifications');
        query = _firestore.collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true);
      }

      final snapshot = await query.get();
      print('DEBUG: Found ${snapshot.docs.length} notifications in Firestore');

      _notifications = snapshot.docs
          .map((doc) {
            print('DEBUG: Processing notification document: ${doc.id}');
            print('DEBUG: Document data: ${doc.data()}');
            return NotificationMessage.fromFirestore(doc);
          })
          .toList();

      // Sort notifications in memory if we're a government user
      if (isGovernment) {
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      print('DEBUG: Processed ${_notifications.length} notifications');
      print('DEBUG: Notification types: ${_notifications.map((n) => n.type).toList()}');

    } catch (e) {
      print('ERROR loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createProblemReportNotification({
    required String problemTitle,
    required String userId,
  }) async {
    try {
      // Create notification document
      final notification = NotificationMessage(
        id: '',
        title: 'Problem Report Submitted',
        body: 'New Problem Report "$problemTitle" has been submitted',
        type: 'problem_report',
        read: false,
        createdAt: DateTime.now(),
        userId: userId,
      );

      await _firestore.collection('notifications').add(notification.toMap());

      // Get all government users
      final governmentUsers = await _firestore
          .collection('Users')
          .where('role', isEqualTo: 'government')
          .get();

      // Send FCM notifications to government users
      for (var govUser in governmentUsers.docs) {
        final token = govUser.data()['fcmToken'] as String?;
        if (token != null) {
          await _messaging.sendMessage(
            to: token,
            data: {
              'type': 'problem_report',
              'title': 'New Problem Report',
              'body': 'A new problem has been reported: $problemTitle',
            },
          );
        }
      }

      await loadNotifications();
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(read: true);
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final unreadNotifications = _notifications.where((n) => !n.read);

      for (var notification in unreadNotifications) {
        final ref = _firestore.collection('notifications').doc(notification.id);
        batch.update(ref, {'read': true});
      }

      await batch.commit();
      _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
      notifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<void> createNotification({
    required String title,
    required String body,
    required String type,
    required String userId,
  }) async {
    try {
      final notification = NotificationMessage(
        id: '', // Firestore will generate this
        title: title,
        body: body,
        type: type,
        read: false,
        createdAt: DateTime.now(),
        userId: userId,
      );

      await _firestore.collection('notifications').add(notification.toMap());

      // Reload notifications to get the new one
      await loadNotifications();
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  Future<void> createProblemUpdateNotification({
    required String problemTitle,
    required String status,
    required String userId,
  }) async {
    try {
      // Create notification document
      final notification = NotificationMessage(
        id: '',
        title: 'Problem Status Update',
        body: 'Your reported problem "$problemTitle" status has been updated to: $status',
        type: 'problem_update',
        read: false,
        createdAt: DateTime.now(),
        userId: userId,
      );

      await _firestore.collection('notifications').add(notification.toMap());

      // Get the user's FCM token
      final userDoc = await _firestore.collection('Users').doc(userId).get();
      final token = userDoc.data()?['fcmToken'] as String?;

      // Send FCM notification if token exists
      if (token != null) {
        await _messaging.sendMessage(
          to: token,
          data: {
            'type': 'problem_update',
            'title': 'Problem Status Update',
            'body': 'Your reported problem "$problemTitle" status has been updated to: $status',
          },
        );
      }

      await loadNotifications();
    } catch (e) {
      print('Error creating problem update notification: $e');
    }
  }

  Future<void> createPollResultNotification({
    required String pollTitle,
    required String userId,
  }) async {
    try {
      // Create notification document
      final notification = NotificationMessage(
        id: '',
        title: 'Poll Results Available',
        body: 'Results for poll "$pollTitle" are now available',
        type: 'poll_result',
        read: false,
        createdAt: DateTime.now(),
        userId: userId,
      );

      await _firestore.collection('notifications').add(notification.toMap());

      // Get the user's FCM token
      final userDoc = await _firestore.collection('Users').doc(userId).get();
      final token = userDoc.data()?['fcmToken'] as String?;

      // Send FCM notification if token exists
      if (token != null) {
        await _messaging.sendMessage(
          to: token,
          data: {
            'type': 'poll_result',
            'title': 'Poll Results Available',
            'body': 'Results for poll "$pollTitle" are now available',
          },
        );
      }

      await loadNotifications();
    } catch (e) {
      print('Error creating poll result notification: $e');
    }
  }

  Future<void> createIssueResolvedNotification({
    required String issueTitle,
    required String userId,
  }) async {
    try {
      // Create notification document
      final notification = NotificationMessage(
        id: '',
        title: 'Issue Resolved',
        body: 'Your reported issue "$issueTitle" has been resolved',
        type: 'issue_resolved',
        read: false,
        createdAt: DateTime.now(),
        userId: userId,
      );

      await _firestore.collection('notifications').add(notification.toMap());

      // Get the user's FCM token
      final userDoc = await _firestore.collection('Users').doc(userId).get();
      final token = userDoc.data()?['fcmToken'] as String?;

      // Send FCM notification if token exists
      if (token != null) {
        await _messaging.sendMessage(
          to: token,
          data: {
            'type': 'issue_resolved',
            'title': 'Issue Resolved',
            'body': 'Your reported issue "$issueTitle" has been resolved',
          },
        );
      }

      await loadNotifications();
    } catch (e) {
      print('Error creating issue resolved notification: $e');
    }
  }
}