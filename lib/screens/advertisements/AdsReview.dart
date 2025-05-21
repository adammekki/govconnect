import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Ads.dart';
import 'dart:convert';

class AdReviewScreen extends StatefulWidget {
  const AdReviewScreen({Key? key}) : super(key: key);

  @override
  _AdReviewScreenState createState() => _AdReviewScreenState();
}

class _AdReviewScreenState extends State<AdReviewScreen> {
  bool _isLoading = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
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
  }

  Future<void> _updateAdStatus(String adId, bool approved) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (approved) {
        await FirebaseFirestore.instance.collection('ads').doc(adId).update({
          'isApproved': true,
        });
      } else {
        await FirebaseFirestore.instance.collection('ads').doc(adId).delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved ? 'Ad approved successfully' : 'Ad declined and removed',
          ),
          backgroundColor: approved ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating ad status: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.account_balance,
            color: theme.appBarTheme.iconTheme?.color ?? theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/feed'),
        ),
        title: Text(
          'Ads Submission Review',
          style: theme.appBarTheme.titleTextStyle,
        ),
      ),
      body:
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                      color: theme.colorScheme.primary))
              : StreamBuilder<QuerySnapshot>(
                stream:
                    _userRole == 'government'
                        ? FirebaseFirestore.instance
                            .collection('ads')
                            .orderBy('createdAt', descending: true)
                            .snapshots()
                        : FirebaseFirestore.instance
                            .collection('ads')
                            .orderBy('createdAt', descending: true)
                            .where('postedBy', isEqualTo: currentUser?.uid)
                            .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(
                            color: theme.colorScheme.primary));
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error}',
                            style: TextStyle(color: theme.colorScheme.error)));
                  }

                  final ads = snapshot.data?.docs ?? [];

                  if (ads.isEmpty) {
                    return Center(
                        child: Text('No ads pending review',
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ads.length,
                    itemBuilder: (context, index) {
                      final doc = ads[index];
                      final ad = AdModel.fromJson(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: theme.cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User info
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: theme.colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.person,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        FutureBuilder<DocumentSnapshot>(
                                          future:
                                              FirebaseFirestore.instance
                                                  .collection('Users')
                                                  .doc(ad.postedBy)
                                                  .get(),
                                          builder: (context, userSnapshot) {
                                            if (userSnapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Text('Loading...',
                                                  style: TextStyle(color: theme.colorScheme.onSurface));
                                            }
                                            final userData =
                                                userSnapshot.data?.data()
                                                    as Map<String, dynamic>?;
                                            return Text(
                                              userData?['fullName'] ??
                                                  userData?['displayName'] ??
                                                  'Anonymous User',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                            );
                                          },
                                        ),
                                        Text(
                                          'Posted ${_formatTimestamp(ad.createdAt)}',
                                          style: TextStyle(
                                            color: theme.textTheme.bodySmall?.color,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Ad image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  ad.imageBase64 != null &&
                                          ad.imageBase64!.isNotEmpty
                                      ? Image.memory(
                                        base64Decode(ad.imageBase64!),
                                        width: double.infinity,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: theme.colorScheme.surfaceVariant,
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.error,
                                                      color: theme.colorScheme.error,
                                                    ),
                                                  ),
                                                ),
                                      )
                                      : Container(
                                        color: theme.colorScheme.surfaceVariant,
                                        height: 180,
                                        child: Center(
                                          child: Icon(Icons.broken_image,
                                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.38)),
                                        ),
                                      ),
                            ),

                            // Ad content
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ad.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(ad.description,
                                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                                ],
                              ),
                            ),

                            // Action buttons
                            if (_userRole == 'government')
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed:
                                            () => _updateAdStatus(ad.id, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.colorScheme.primary,
                                          foregroundColor: theme.colorScheme.onPrimary,
                                        ),
                                        child: const Text('Accept'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed:
                                            () => _updateAdStatus(ad.id, false),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: theme.colorScheme.primary,
                                          side: BorderSide(color: theme.colorScheme.primary),
                                        ),
                                        child: const Text('Decline'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_userRole == 'advertiser')
                              ad.isApproved == true
                                ? const Padding(
                                    padding: EdgeInsets.all(12), // This color is specific
                                    child: Text(
                                      'Ad Approved',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green, // Kept specific green
                                      ),
                                    ),
                                  )
                                : const Padding(
                                    padding: EdgeInsets.all(12), // This color is specific
                                    child: Text(
                                      'Ad Pending Review',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.yellow, // Kept specific yellow
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      );
                    },
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
        currentIndex: 4,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/feed');
          }
          if (index == 1) {
            Navigator.of(context).pushReplacementNamed('/chat');
          }
          if (index == 2) {
            Navigator.of(context).pushReplacementNamed('/notifications');
          }
          if (index == 3) {
            Navigator.of(context).pushReplacementNamed('/profile');
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded, size: 28),
            activeIcon: Icon(Icons.person, size: 28),
            label: '',
          ),
          if (_userRole != null && _userRole != 'citizen')
            BottomNavigationBarItem(
              icon: Icon(Icons.ads_click_outlined, size: 28),
              activeIcon: Icon(Icons.ads_click, size: 28),
              label: '',
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
