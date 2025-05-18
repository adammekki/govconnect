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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ads Submission Review',
          style: TextStyle(
            fontSize: 22, // Larger font size
            fontWeight: FontWeight.bold, // Bold text
            color: Colors.white, // Ensure high contrast
            letterSpacing: 1.2, // Optional: add some spacing
          ),
        ),
        backgroundColor: const Color(0xFF1B2141),
        iconTheme: const IconThemeData(color: Colors.white, size: 28),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('ads')
                        .where('isApproved', isEqualTo: false)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final ads = snapshot.data?.docs ?? [];

                  if (ads.isEmpty) {
                    return const Center(child: Text('No ads pending review'));
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
                                    backgroundColor: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.grey[600],
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
                                                  .collection(
                                                    'Users',
                                                  ) // Use 'Users' with capital U if that's your collection
                                                  .doc(ad.postedBy)
                                                  .get(),
                                          builder: (context, userSnapshot) {
                                            if (userSnapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Text('Loading...');
                                            }
                                            final userData =
                                                userSnapshot.data?.data()
                                                    as Map<String, dynamic>?;
                                            return Text(
                                              userData?['fullName'] ??
                                                  userData?['displayName'] ??
                                                  'Anonymous User',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          },
                                        ),
                                        Text(
                                          'Posted ${_formatTimestamp(ad.createdAt)}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () {
                                      // Show options menu
                                    },
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
                                        width:
                                            double
                                                .infinity, // or remove this if you want natural width too
                                        fit:
                                            BoxFit
                                                .contain, // Show the whole image without cropping
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.error,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                      )
                                      : Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(Icons.broken_image),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(ad.description),
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
                                          backgroundColor:
                                              Colors.deepPurple[900],
                                          foregroundColor: Colors.white,
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
                                          foregroundColor:
                                              Colors.deepPurple[900],
                                        ),
                                        child: const Text('Decline'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
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
