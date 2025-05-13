import 'package:flutter/material.dart';
import 'package:govconnect/Polls/DisplayPoll.dart';
import 'package:govconnect/screens/advertisements/AdsReview.dart';
import 'package:govconnect/screens/advertisements/file.dart';
import 'package:govconnect/screens/Feed/FeedScreen.dart';
import 'package:govconnect/screens/announcements/file.dart';
import 'package:govconnect/screens/communication/chat/chatGrid.dart';
import 'package:govconnect/screens/emergencies/file.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          const Text('Hello from the main screen'),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatGrid()),
              );
            },
            child: const Text('Go to Chat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnnouncementsScreen()),
              );
            },
            child: const Text('Go to Announcements'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdvertisementsScreen()),
              );
            },
            child: const Text('Go to Advertisements'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EmergenciesScreen()),
              );
            },
            child: const Text('Go to Emeregency'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DisplayPoll()),
              );
            },
            child: const Text('Go to Polls'),
          ), 
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FeedScreen()),
              );
            },
            child: const Text('Go to Feed'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdReviewScreen()),
              );
            },
            child: const Text('Go to ad review'),
          ), 
          ElevatedButton(
            onPressed: () {
              signUserOut(context);
            },
            child: const Text('Sign Out'),
          )
        ],
      ),
    );
  }
}