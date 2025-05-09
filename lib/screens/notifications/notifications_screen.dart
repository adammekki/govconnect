import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_message.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  void handleNotificationTap(BuildContext context, NotificationMessage notification) {
    // Mark the notification as read
    Provider.of<NotificationProvider>(context, listen: false).markAsRead(notification.id);

    // Navigate based on notification type
    switch (notification.type) {
      case 'problem_report':
        // Navigate to problems list
        Navigator.pushNamed(context, '/problems');
        break;
      
      case 'problem_update':
        // If we have a problem ID in the notification data, navigate to that specific problem
        Navigator.pushNamed(
          context, 
          '/problems',
          // You might want to pass additional arguments here
        );
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

          return ListView.builder(
            itemCount: provider.notifications.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return NotificationCard(
                notification: notification,
                onTap: () => handleNotificationTap(context, notification),
                onDismiss: () => provider.deleteNotification(notification.id),
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationMessage notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  }) : super(key: key);

  IconData getNotificationIcon() {
    switch (notification.type) {
      case 'problem_report':
        return Icons.report_problem;
      case 'problem_update':
        return Icons.update;
      case 'emergency':
        return Icons.emergency;
      case 'chat':
        return Icons.chat;
      case 'announcement':
        return Icons.announcement;
      case 'advertisement':
        return Icons.ad_units;
      default:
        return Icons.notifications;
    }
  }

  Color getNotificationColor() {
    switch (notification.type) {
      case 'problem_report':
        return Colors.orange;
      case 'problem_update':
        return Colors.blue;
      case 'emergency':
        return Colors.red;
      case 'chat':
        return Colors.green;
      case 'announcement':
        return Colors.purple;
      case 'advertisement':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        color: notification.read ? const Color(0xFF22304D) : const Color(0xFF2C3E50),
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: getNotificationColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    getNotificationIcon(),
                    color: getNotificationColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (!notification.read)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: getNotificationColor(),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.body,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeago.format(notification.createdAt),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 