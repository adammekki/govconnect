import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Ads.dart';
import 'dart:convert';

class AdCard extends StatelessWidget {
  final AdModel ad;

  const AdCard({Key? key, required this.ad}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: const Color(0xFF1C2F41),
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
                  backgroundColor: const Color(0xFF131E2F),
                  child: Icon(Icons.business, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('Users')
                                .doc(ad.postedBy) // This is the ad poster's ID
                                .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                              'Loading...',
                              style: TextStyle(color: Colors.white),
                            );
                          }
                          final adPosterProfileData = // Renamed for clarity: this is ad.postedBy's profile
                              snapshot.data?.data() as Map<String, dynamic>?;
                          return Text(
                            adPosterProfileData?['fullName'] ??
                                adPosterProfileData?['displayName'] ??
                                'Advertiser',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.local_offer, // Was const, but color is not const
                            size: 12,
                            color: Color(0xFF7AA2F7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Advertisement', // Was const, but style is not const
                            style: TextStyle(
                              color: Color(0xFF7AA2F7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Conditional IconButton for options menu
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('Users').doc(ad.postedBy).snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.hasData && userSnapshot.data?.exists == true) {
                      final adPosterData = userSnapshot.data!.data() as Map<String, dynamic>;
                      final adPosterRole = adPosterData['role'] as String?;
                      final currentAuthUser = FirebaseAuth.instance.currentUser;

                      // Show button if:
                      // 1. The ad poster's role is 'advertiser'
                      // 2. The current logged-in user is the one who posted the ad
                      if (adPosterRole == 'advertiser' && currentAuthUser?.uid == ad.postedBy) {
                        return IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () => _showOptionsMenu(context),
                        );
                      }
                    }
                    return const SizedBox.shrink(); // Otherwise, show nothing
                  },
                ),
              ],
            ),
          ),

          // Ad image
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child:
                ad.imageBase64 != null
                    ? Image.memory(
                      base64Decode(ad.imageBase64!),
                      width:
                          double.infinity, // Optional: remove for natural width
                      fit: BoxFit.contain, // Show the whole image, no cropping
                    )
                    : Container(
                      color: const Color(0xFF232B3E),
                      height: 180,
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.white38)),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ad.description,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _formatTimestamp(ad.createdAt),
                      style: TextStyle(color: Color(0xFF7AA2F7), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
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

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Ad',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Delete Ad'),
                          content: const Text(
                            'Are you sure you want to delete this ad?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                  );
                  if (confirm == true) {
                    await FirebaseFirestore.instance
                        .collection('ads')
                        .doc(ad.id)
                        .delete();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Ad deleted')));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}