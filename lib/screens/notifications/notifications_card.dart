import 'package:flutter/material.dart';
import 'package:govconnect/models/notification_message.dart';
import 'package:timeago/timeago.dart' as timeago;

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
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: Card(
        color: const Color(0xFF181B2C),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: getNotificationColor().withOpacity(0.2),
                child: Icon(
                  getNotificationIcon(),
                  color: getNotificationColor(),
                ),
              ),
              if (!notification.read)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF181B2C), width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.body,
                style: const TextStyle(color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                timeago.format(notification.createdAt),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
} 