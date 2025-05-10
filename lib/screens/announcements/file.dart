import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:govconnect/screens/announcements/announcementCard.dart';
import 'package:govconnect/screens/announcements/announcementProvider.dart';
import 'package:provider/provider.dart';
import 'package:govconnect/components/bottombar.dart'; // Import your bottom bar
import 'package:govconnect/components/header.dart'; // Import your header
import 'package:govconnect/components/drawer.dart'; // Import your drawer

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsFeedState();
}

class _AnnouncementsFeedState extends State<AnnouncementsScreen> {
  int _currentBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnnouncementsProvider>(context, listen: false).fetchAnnouncements();
    });
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
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppHeader(
      ),
      drawer: const AppDrawer(),
      body: announcementsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : announcementsProvider.announcements.isEmpty
              ? const Center(child: Text('No announcements yet'))
              : ListView.builder(
                  itemCount: announcementsProvider.announcements.length,
                  itemBuilder: (context, index) {
                    final announcement =
                        announcementsProvider.announcements[index];
                    return AnnouncementCard(announcement: announcement);
                  },
                ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTap,
      ),
      floatingActionButton: currentUser != null
          ? FloatingActionButton(
              onPressed: () => _showCreateAnnouncementDialog(context),
              child: const Icon(Icons.add),
              backgroundColor: Colors.blue, // Match your theme
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
          title: const Text('Create New Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
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
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }
}