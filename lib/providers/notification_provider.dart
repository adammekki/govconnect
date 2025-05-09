import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_message.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<NotificationMessage> _notifications = [];
  bool _isLoading = false;

  List<NotificationMessage> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  NotificationProvider() {
    _initialize();
  }

  void _initialize() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        loadNotifications();
      } else {
        _notifications = [];
        notifyListeners();
      }
    });
  }

  Future<void> loadNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _notifications = snapshot.docs
          .map((doc) => NotificationMessage.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });

      // Update local state
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

      // Update local state
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

      // Update local state
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

  Future<void> createProblemReportNotification({
    required String problemTitle,
    required String userId,
  }) async {
    await createNotification(
      title: 'New Problem Report',
      body: 'A new problem has been reported: $problemTitle',
      type: 'problem_report',
      userId: userId,
    );
  }

  Future<void> createProblemUpdateNotification({
    required String problemTitle,
    required String status,
    required String userId,
  }) async {
    await createNotification(
      title: 'Problem Status Update',
      body: 'Problem "$problemTitle" status has been updated to: $status',
      type: 'problem_update',
      userId: userId,
    );
  }
}