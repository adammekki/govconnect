import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:govconnect/screens/notifications/notifications_card.dart';
import 'package:provider/provider.dart';
import '../models/notification_message.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  List<NotificationMessage> _notifications = [];
  bool _isLoading = false;

  List<NotificationMessage> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  NotificationProvider() {
    _initialize();
  }

Future<void> _initialize() async {
  try {
    // Initialize local notifications with safe fallback
    AndroidInitializationSettings initializationSettingsAndroid;
    try {
      initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');
    } catch (e) {
      print('Error setting Android notification icon: $e');
      // Fallback to app icon name
      initializationSettingsAndroid = const AndroidInitializationSettings('app_icon');
    }
    
    // Simple initialization without iOS/MacOS settings to avoid errors
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    // Initialize with a simpler callback to avoid errors
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification tapped: ${details.payload}');
        if (details.payload != null) {
          _handleLocalNotificationTap(details.payload);
        }
      },
    );
    
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('User notification permission status: ${settings.authorizationStatus}');

    // Configure foreground notification presentation
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      // Store the token in Firestore for the current user
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('Users').doc(user.uid).update({
          'fcmToken': token,
        });
      }
    }

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      final user = _auth.currentUser;
      if (user != null) {
        _firestore.collection('Users').doc(user.uid).update({
          'fcmToken': newToken,
        });
      }
    });

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        loadNotifications();
        _setupPendingNotificationsListener(); // Add this line
      } else {
        _notifications = [];
        notifyListeners();
      }
    });

    // Handle incoming messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleNewNotification(message);
      _showLocalNotification(message);
    });

    // Handle notification taps when app was terminated
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message);
    });
    
    // Setup pending notifications listener if user is already logged in
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _setupPendingNotificationsListener();
    }
  } catch (e) {
    print('Error initializing notifications: $e');
  }
}

// Add this method right after _initialize()
void _setupPendingNotificationsListener() async {
  String? token = await _messaging.getToken();
  if (token == null) return;
  
  // Listen for new pending notifications for this device
  _firestore
      .collection('pendingNotifications')
      .where('token', isEqualTo: token)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .listen((snapshot) async {
    for (var doc in snapshot.docs) {
      final data = doc.data();
      
      // Show a local notification
      await _showLocalNotificationFromData(
        title: data['title'],
        body: data['body'],
        payload: data['data']['type'],
      );
      
      // Mark as delivered
      await doc.reference.update({'status': 'delivered'});
    }
  });
}

// Add this helper method too
Future<void> _showLocalNotificationFromData({
  required String title,
  required String body,
  String? payload,
}) async {
  try {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'govconnect_channel',
      'GovConnect Notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.hashCode,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  } catch (e) {
    print('Error showing local notification: $e');
  }
}

  void _handleNewNotification(RemoteMessage message) {
  try {
    // Create a notification object from the message with safer handling
    final notification = NotificationMessage(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      type: message.data['type'] ?? 'general',
      read: false,
      createdAt: DateTime.now(),
      userId: _auth.currentUser?.uid ?? '',
    );

    // Add to local list
    _notifications.insert(0, notification);
    notifyListeners();
  } catch (e) {
    print('Error handling new notification: $e');
  }
}

void _showLocalNotification(RemoteMessage message) async {
  try {
    final notification = message.notification;
    if (notification == null) return;
    
    // Create Android notification channel details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'govconnect_channel', // Channel ID
      'GovConnect Notifications', // Channel name
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    // Create notification details with only Android for now
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    
    // Show notification with null safety
    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'New Notification',
      notification.body ?? '',
      notificationDetails,
      payload: message.data['type'] ?? 'general',
    );
  } catch (e) {
    print('Error showing local notification: $e');
  }
}

void _handleLocalNotificationTap(String? payload) {
  try {
    if (payload == null) return;
    
    // This would ideally use a navigation service
    print('Should navigate to: $payload');
    // We'll handle actual navigation in the UI part
  } catch (e) {
    print('Error handling local notification tap: $e');
  }
}

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    final notificationType = message.data['type'];
    
    // We'll handle the navigation in the UI using this information
    // This would ideally use a navigation service
    print('Should navigate to: $notificationType');
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
        print(
          'DEBUG: Fetching all problem report notifications for government user',
        );
        // Simplified query that doesn't require a composite index
        query = _firestore
            .collection('notifications')
            .where('type', isEqualTo: 'problem_report');
        // We'll sort the results in memory instead
      } else {
        print('DEBUG: Fetching user-specific notifications');
        query = _firestore
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true);
      }

      final snapshot = await query.get();
      print('DEBUG: Found ${snapshot.docs.length} notifications in Firestore');

      _notifications =
          snapshot.docs.map((doc) {
            print('DEBUG: Processing notification document: ${doc.id}');
            print('DEBUG: Document data: ${doc.data()}');
            return NotificationMessage.fromFirestore(doc);
          }).toList();

      // Sort notifications in memory if we're a government user
      if (isGovernment) {
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      print('DEBUG: Processed ${_notifications.length} notifications');
      print(
        'DEBUG: Notification types: ${_notifications.map((n) => n.type).toList()}',
      );
    } catch (e) {
      print('ERROR loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
        body:
            'Your reported problem "$problemTitle" status has been updated to: $status',
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
        await _sendPushNotification(
          token: token,
          title: 'Problem Status Update',
          body: 'Your reported problem "$problemTitle" status has been updated to: $status',
          data: {
            'type': 'problem_update',
            'problemTitle': problemTitle,
            'status': status,
          },
        );
      }

      await loadNotifications();
    } catch (e) {
      print('Error creating problem update notification: $e');
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
      _notifications =
          _notifications.map((n) => n.copyWith(read: true)).toList();
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
      final governmentUsers =
          await _firestore
              .collection('Users')
              .where('role', isEqualTo: 'government')
              .get();

      // Send FCM notifications to government users
      for (var govUser in governmentUsers.docs) {
        final token = govUser.data()['fcmToken'] as String?;
        if (token != null) {
          await _sendPushNotification(
            token: token,
            title: 'New Problem Report',
            body: 'A new problem has been reported: $problemTitle',
            data: {
              'type': 'problem_report',
              'problemTitle': problemTitle,
            },
          );
        }
      }

      await loadNotifications();
    } catch (e) {
      print('Error creating notification: $e');
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
        await _sendPushNotification(
          token: token,
          title: 'Poll Results Available',
          body: 'Results for poll "$pollTitle" are now available',
          data: {
            'type': 'poll_result',
            'pollTitle': pollTitle,
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
        await _sendPushNotification(
          token: token,
          title: 'Issue Resolved',
          body: 'Your reported issue "$issueTitle" has been resolved',
          data: {
            'type': 'issue_resolved',
            'issueTitle': issueTitle,
          },
        );
      }

      await loadNotifications();
    } catch (e) {
      print('Error creating issue resolved notification: $e');
    }
  }

  Future<void> _sendPushNotification({
  required String token,
  required String title,
  required String body,
  required Map<String, dynamic> data,
}) async {
  try {
    // Store the notification in a pendingNotifications collection
    await _firestore.collection('pendingNotifications').add({
      'token': token,
      'title': title,
      'body': body,
      'data': data,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending'
    });
    
    print('Added notification to pending queue');
  } catch (e) {
    print('Error adding notification to queue: $e');
  }
}
}