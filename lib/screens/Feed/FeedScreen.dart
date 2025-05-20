import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:govconnect/providers/announcementProvider.dart';
import 'package:govconnect/screens/announcements/announcementCard.dart';
import 'package:govconnect/providers/PollProvider.dart';
import 'package:govconnect/Polls/PollCard.dart';
import 'package:govconnect/components/bottombar.dart';
import 'package:govconnect/components/drawer.dart';
import 'CreatePostDialog.dart';
import 'package:govconnect/providers/AdProvider.dart';
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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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

  bool _isCreatingAd = false;

  void _showCreateAdDialog() {
    setState(() {
      _isCreatingAd = true;
    });
  }

  void _hideCreateAdDialog() {
    setState(() {
      _isCreatingAd = false;
    });
  }

  // Update the onPressed in the advertiser action button:
  // onPressed: _showCreateAdDialog,

  List<Widget> _buildFeedItems(List announcements, List polls, List ads) {
    List<Widget> feedItems = [];
    int adIndex = 0;
    int contentCount = 0;
    final int adFrequency = 3;
    int i = 0;
    int j = 0;
    while (i < announcements.length || j < polls.length) {
      if (i < announcements.length) {
        feedItems.add(AnnouncementCard(announcement: announcements[i]));
        i++;
        contentCount++;
      }
      if (contentCount % adFrequency == 0 && adIndex < ads.length) {
        feedItems.add(AdCard(ad: ads[adIndex]));
        adIndex++;
      }
      if (j < polls.length) {
        feedItems.add(Pollcard(poll: polls[j]));
        j++;
        contentCount++;
      }
      if (contentCount % adFrequency == 0 && adIndex < ads.length) {
        feedItems.add(AdCard(ad: ads[adIndex]));
        adIndex++;
      }
    }
    while (adIndex < ads.length) {
      feedItems.add(AdCard(ad: ads[adIndex]));
      adIndex++;
    }
    return feedItems;
  }

  @override
  Widget build(BuildContext context) {
    final announcementsProvider = Provider.of<AnnouncementsProvider>(context);
    final pollsProvider = Provider.of<Pollproviders>(context);
    final adProvider = Provider.of<AdProvider>(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    final announcements =
        announcementsProvider.announcements
            .where(
              (a) =>
                  _searchQuery.isEmpty ||
                  (a.title?.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ??
                      false) ||
                  (a.description.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  )),
            )
            .toList();
    final polls =
        pollsProvider.getPolls
            .where(
              (p) =>
                  _searchQuery.isEmpty ||
                  (p.question?.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ??
                      false),
            )
            .toList();
    final ads =
        adProvider.ads
            .where(
              (ad) =>
                  _searchQuery.isEmpty ||
                  (ad.title?.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ??
                      false) ||
                  (ad.description?.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ??
                      false),
            )
            .toList();

    final feedItems = _buildFeedItems(announcements, polls, ads);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1621),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Icon(Icons.account_balance, color: Colors.white, size: 28),
        ),
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1C2F41),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.blue,
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              filled: true,
              fillColor: const Color(0xFF1C2F41),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        actions: [
          if (_userRole == 'government')
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _showCreatePostDialog,
                  icon: const Icon(Icons.add, color: Colors.blue),
                  iconSize: 24,
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ),
          if (_userRole == 'advertiser')
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _showCreateAdDialog,
                  icon: const Icon(Icons.add, color: Colors.orange),
                  iconSize: 24,
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ),
          if (_userRole == 'citizen')
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/reportProblem');
                  },
                  icon: const Icon(Icons.add, color: Colors.green),
                  iconSize: 24,
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child:
                    announcementsProvider.isLoading ||
                            pollsProvider.isLoading ||
                            adProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : feedItems.isEmpty
                        ? const Center(
                          child: Text(
                            'No content yet',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                        : ListView(children: feedItems),
              ),
            ],
          ),
          if (_isCreatingPost)
            CreatePostDialog(
              onClose: _hideCreatePostDialog,
              onPostCreated: () {
                _hideCreatePostDialog();
              },
            ),
          if (_isCreatingAd)
            CreateAdDialog(
              onClose: _hideCreateAdDialog,
              onAdCreated: () {
                _hideCreateAdDialog();
                // Refresh ads
                Provider.of<AdProvider>(
                  context,
                  listen: false,
                ).fetchApprovedAds();
              },
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1C2F41),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).pushReplacementNamed('/chat');
          }
          if (index == 2) {
            Navigator.of(context).pushReplacementNamed('/notifications');
          }
          if (index == 4) {
            Navigator.of(context).pushReplacementNamed('/profile');
          }
          if (index == 3) {
            Navigator.of(context).pushReplacementNamed('/adReview');
          }
        },
        items: [
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

          if (_userRole != 'citizen')
            BottomNavigationBarItem(
              icon: Icon(Icons.ads_click_outlined, size: 28),
              activeIcon: Icon(Icons.ads_click, size: 28),
              label: '',
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded, size: 28),
            activeIcon: Icon(Icons.person, size: 28),
            label: '',
          ),
        ],
      ),
    );
  }
}
