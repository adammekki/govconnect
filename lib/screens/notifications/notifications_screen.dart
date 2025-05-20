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
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).loadNotifications();
    });
  }

  void handleNotificationTap(
    BuildContext context,
    NotificationMessage notification,
  ) {
    // Mark the notification as read
    Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).markAsRead(notification.id);

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
      backgroundColor: const Color(0xFF0E1621),
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Icon(Icons.account_balance, color: Colors.white, size: 28),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushNamed('/feed');
            },
          ),
          TextButton(
            onPressed: () {
              Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).markAllAsRead();
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
          print(
            'DEBUG: Building notifications screen. Notifications count: ${provider.notifications.length}',
          );
          print('DEBUG: Loading state: ${provider.isLoading}');

          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child:
                    provider.notifications.isEmpty
                        ? Center(
                          child: Text(
                            'No notifications yet',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: () => provider.loadNotifications(),
                          child: ListView.builder(
                            itemCount: provider.notifications.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, index) {
                              final notification =
                                  provider.notifications[index];
                              return NotificationCard(
                                notification: notification,
                                onTap:
                                    () => handleNotificationTap(
                                      context,
                                      notification,
                                    ),
                                onDismiss:
                                    () => provider.deleteNotification(
                                      notification.id,
                                    ),
                              );
                            },
                          ),
                        ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1C2F41),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/feed');
          }
          if (index == 1) {
            Navigator.of(context).pushReplacementNamed('/chat');
          }
          if (index == 3) {
            Navigator.of(context).pushReplacementNamed('/profile');
          }
          if (index == 4) {
            Navigator.of(context).pushReplacementNamed('/adReview');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 28),
            activeIcon: Icon(Icons.home, size: 28),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined, size: 28),
            activeIcon: Icon(Icons.message, size: 28),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none, size: 28),
            activeIcon: Icon(Icons.notifications, size: 28),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu, size: 28),
            activeIcon: Icon(Icons.menu, size: 28),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.ads_click_outlined, size: 28),
            activeIcon: Icon(Icons.ads_click, size: 28),
            label: '',
          ),
        ],
      ),
    );
  }
}
