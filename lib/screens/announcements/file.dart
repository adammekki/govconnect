import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:govconnect/screens/announcements/announcementCard.dart';
import 'package:govconnect/providers/announcementProvider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:govconnect/components/bottombar.dart'; // Import your bottom bar
import 'package:govconnect/components/drawer.dart'; // Import your drawer

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsFeedState();
}

class _AnnouncementsFeedState extends State<AnnouncementsScreen> {
  int _currentBottomNavIndex = 0;
  String? _userRole;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<AnnouncementsProvider>(context, listen: false).fetchAnnouncements();
      await _getUserRole(); // Fetch user role
    });
  }

  Future<void> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userRole = userDoc['role'];
          _loadingRole = false;
        });
      } else {
        setState(() {
          _userRole = null;
          _loadingRole = false;
        });
      }
    } else {
      setState(() {
        _userRole = null;
        _loadingRole = false;
      });
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });
    // Add navigation logic for different tabs if needed
  }

  @override
  Widget build(BuildContext context) {
    final announcementsProvider = Provider.of<AnnouncementsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2F41),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.account_balance, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Announcements',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFF1C2F41),
      drawer: const AppDrawer(),
      body: announcementsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : announcementsProvider.announcements.isEmpty
              ? const Center(child: Text('No announcements yet', style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: announcementsProvider.announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = announcementsProvider.announcements[index];
                    return AnnouncementCard(announcement: announcement);
                  },
                ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTap,
      ),
      floatingActionButton: _userRole == 'government'
          ? FloatingActionButton(
              onPressed: () => _showCreateAnnouncementDialog(context),
              child: const Icon(Icons.add),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  void _showCreateAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF232B3E),
          title: const Text('Create New Announcement', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFF131E2F),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFF131E2F),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFF131E2F),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                final provider = Provider.of<AnnouncementsProvider>(
                  context,
                  listen: false,
                );
                await provider.createAnnouncement(
                  title: titleController.text,
                  description: descriptionController.text,
                  category: categoryController.text.isNotEmpty
                      ? categoryController.text
                      : 'General',
                );
                Navigator.pop(context);
              },
              child: const Text('Post', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}
