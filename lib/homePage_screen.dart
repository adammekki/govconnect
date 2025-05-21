import 'package:flutter/material.dart';
import 'package:govconnect/Polls/DisplayPoll.dart';
import 'package:govconnect/screens/Feed/FeedScreen.dart';
import 'package:govconnect/screens/advertisements/AdsReview.dart';
import 'package:govconnect/screens/announcements/file.dart';
import 'package:govconnect/screens/communication/chat/chatGrid.dart';
import 'package:govconnect/screens/emergencies/emergency.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:govconnect/screens/problems/problems.dart';
import 'package:govconnect/screens/problems/report_problem.dart';
import 'package:govconnect/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'providers/notification_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.title});

  final String title;

  void signUserOut(BuildContext context) async {
    try {
      // Sign out the user
      await FirebaseAuth.instance.signOut();
      
      // Navigate back to login screen
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/login', 
          (route) => false
        );
      }
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2F41),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2F41),
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              final unreadCount = provider.unreadCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/notifications');
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              icon: const Icon(Icons.person),
              label: const Text('View Profile'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatGrid()),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Chat'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AnnouncementsScreen()),
                );
              },
              icon: const Icon(Icons.announcement),
              label: const Text('Announcements'),
            ),
            const SizedBox(height: 12),
             ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DisplayPoll()),
              );
            },
            icon: const Icon(Icons.poll),
            label: const Text('Go to Polls'),
          ),
          const SizedBox(height: 12), 
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FeedScreen()),
              );
            },
             icon: const Icon(Icons.feed),
            label: const Text('Go to Feed'),
          ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdReviewScreen()),
                );
              },
              icon: const Icon(Icons.ad_units),
              label: const Text('Advertisements'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EmergencyContactsScreen()),
                );
              },
              icon: const Icon(Icons.emergency),
              label: const Text('Emergency'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProblemsScreen()),
                );
              },
              icon: const Icon(Icons.list),
              label: const Text('View Problems'),
            ),
            const SizedBox(height: 12),
            // ElevatedButton.icon(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => const ReportProblemScreen()),
            //     );
            //   },
            //   icon: const Icon(Icons.report_problem),
            //   label: const Text('Report Problem'),
            // ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => signUserOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}