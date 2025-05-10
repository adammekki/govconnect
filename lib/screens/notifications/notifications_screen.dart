import 'package:flutter/material.dart';
import 'package:govconnect/screens/notifications/notifications_card.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_message.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load notifications when screen opens
    Future.microtask(() {
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
  }

  void handleNotificationTap(BuildContext context, NotificationMessage notification) {
    // Mark the notification as read
    Provider.of<NotificationProvider>(context, listen: false).markAsRead(notification.id);

    // Navigate based on notification type
    switch (notification.type) {
      case 'problem_report':
        print('DEBUG: Tapped problem report notification');
        Navigator.pushNamed(context, '/problems');
        break;
      case 'problem_update':
        print('DEBUG: Tapped problem update notification');
        Navigator.pushNamed(context, '/problems');
        break;
      case 'emergency':
        Navigator.pushNamed(context, '/emergencyContacts');
        break;
      case 'chat':
        Navigator.pushNamed(context, '/chat');
        break;
      case 'announcement':
        Navigator.pushNamed(context, '/announcements');
        break;
      case 'advertisement':
        Navigator.pushNamed(context, '/advertisements');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2F41),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2F41),
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false).markAllAsRead();
            },
            child: const Text(
              'Mark All Read',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          print('DEBUG: Building notifications screen. Notifications count: ${provider.notifications.length}');
          print('DEBUG: Loading state: ${provider.isLoading}');

          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadNotifications(),
            child: ListView.builder(
              itemCount: provider.notifications.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                print('DEBUG: Building notification card for ${notification.type}');
                return NotificationCard(
                  notification: notification,
                  onTap: () => handleNotificationTap(context, notification),
                  onDismiss: () => provider.deleteNotification(notification.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

