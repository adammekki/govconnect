import 'package:flutter/material.dart';
import 'package:govconnect/screens/notifications/notifications_card.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_message.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      case 'poll_result':
        Navigator.pushNamed(context, '/polls');
        break;
      case 'issue_resolved':
        Navigator.pushNamed(context, '/problems');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Icon(
            Icons.account_balance,
            color: theme.appBarTheme.iconTheme?.color ?? theme.colorScheme.onSurface,
            size: 28,
          ),
        ),
        actions: [
          // Test button (only visible in debug mode)
          // if (const bool.fromEnvironment('dart.vm.product') == false)
          IconButton(
            icon: Icon(Icons.home,
                color: theme.appBarTheme.actionsIconTheme?.color ??
                    theme.colorScheme.onSurface),
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
            child: Text(
              'Mark All Read',
              style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.7)),
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
                // CircularProgressIndicator will use the theme's accent color by default
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0), // Added top and increased bottom padding
                child: Text(
                  'Notifications',
                  style: TextStyle( // This will now inherit from theme.textTheme.headlineSmall or similar
                    // color: theme.textTheme.headlineSmall?.color, // Example if you want to be explicit
                    fontSize: 32, // Adjusted for better visual hierarchy
                    fontWeight: FontWeight.bold,
                  ), // Text color will be based on theme
                ),
              ),
              Expanded(
                child:
                    provider.notifications.isEmpty
                        ? Center(
                            child: Text(
                              'No notifications yet',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
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
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor ?? theme.cardColor,
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor ?? theme.colorScheme.primary,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor ?? theme.colorScheme.onSurface.withOpacity(0.7),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        currentIndex: 2, // This should ideally be managed by a state variable if you want it to change
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
