import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:govconnect/screens/announcements/announcementProvider.dart';
import 'package:govconnect/screens/announcements/announcementCard.dart';
import 'package:govconnect/Polls/PollProvider.dart';
import 'package:govconnect/Polls/PollCard.dart';
import 'package:govconnect/components/bottombar.dart';
import 'package:govconnect/components/header.dart';
import 'package:govconnect/components/drawer.dart';
import 'CreatePostDialog.dart';
import 'package:govconnect/screens/advertisements/AdProvider.dart';
import 'package:govconnect/screens/advertisements/AdCard.dart';
import 'package:govconnect/screens/advertisements/AdsSubmission.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _currentBottomNavIndex = 0;
  bool _isCreatingPost = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<AnnouncementsProvider>(
        context,
        listen: false,
      ).fetchAnnouncements();
      Provider.of<Pollproviders>(context, listen: false).fetchPolls();
      Provider.of<AdProvider>(context, listen: false).fetchApprovedAds();
      Provider.of<AdProvider>(context, listen: false).setupAdListener();

      // Fetch user role
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(user.uid)
                .get();
        setState(() {
          _userRole = doc.data()?['role'];
        });
      }
    });
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });
    // Add navigation logic for different tabs if needed
  }

  void _showCreatePostDialog() {
    setState(() {
      _isCreatingPost = true;
    });
  }

  void _hideCreatePostDialog() {
    setState(() {
      _isCreatingPost = false;
    });
  }

  void _navigateToSubmitAd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubmitAdScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final announcementsProvider = Provider.of<AnnouncementsProvider>(context);
    final pollsProvider = Provider.of<Pollproviders>(context);
    final adProvider = Provider.of<AdProvider>(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    // Combine announcements, polls, and ads for the feed
    List<Widget> feedItems = [];

    final announcements = announcementsProvider.announcements;
    final polls = pollsProvider.getPolls;
    final ads = adProvider.ads;

    // Distribute ads throughout the feed
    int adIndex = 0;
    int contentCount = 0;
    final int adFrequency = 3; // Show an ad every 3 content items

    // Add announcements and polls in alternating order
    int i = 0;
    int j = 0;
    while (i < announcements.length || j < polls.length) {
      // Add an announcement if available
      if (i < announcements.length) {
        feedItems.add(AnnouncementCard(announcement: announcements[i]));
        i++;
        contentCount++;
      }

      // Add an ad every few items if available
      if (contentCount % adFrequency == 0 && adIndex < ads.length) {
        feedItems.add(AdCard(ad: ads[adIndex]));
        adIndex++;
      }

      // Add a poll if available
      if (j < polls.length) {
        feedItems.add(Pollcard(poll: polls[j]));
        j++;
        contentCount++;
      }

      // Add an ad every few items if available
      if (contentCount % adFrequency == 0 && adIndex < ads.length) {
        feedItems.add(AdCard(ad: ads[adIndex]));
        adIndex++;
      }
    }

    // Add any remaining ads
    while (adIndex < ads.length) {
      feedItems.add(AdCard(ad: ads[adIndex]));
      adIndex++;
    }

    return Scaffold(
      appBar: AppHeader(),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Main feed content
          announcementsProvider.isLoading ||
                  pollsProvider.isLoading ||
                  adProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : feedItems.isEmpty
              ? const Center(child: Text('No content yet'))
              : ListView(children: feedItems),

          // Create post overlay
          if (_isCreatingPost)
            CreatePostDialog(
              onClose: _hideCreatePostDialog,
              onPostCreated: () {
                _hideCreatePostDialog();
                // Optionally, you can insert the new post/poll into the provider directly here if you have the data.
                // Otherwise, just close the dialog and let the provider handle UI updates.
              },
            ),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTap,
      ),
      floatingActionButton:
          currentUser != null
              ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Advertisement button (only for advertisers)
                  if (_userRole == 'advertiser')
                    FloatingActionButton.small(
                      heroTag: 'ad_button',
                      onPressed: _navigateToSubmitAd,
                      backgroundColor: Colors.amber[800],
                      child: const Icon(Icons.campaign),
                    ),
                  if (_userRole == 'advertiser') const SizedBox(height: 16),
                  // Create post button (only for government users)
                  if (_userRole == 'government')
                    FloatingActionButton(
                      heroTag: 'post_button',
                      onPressed: _showCreatePostDialog,
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.add),
                    ),
                ],
              )
              : null,
    );
  }
}
