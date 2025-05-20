import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:govconnect/screens/settings.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/problem_report_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userRole; // Move this to be a class field

  @override
  void initState() {
    super.initState();
    _fetchUserRole(); // Keep this in initState
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userDataFuture = FirebaseFirestore.instance
        .collection('Users')
        .doc(user?.uid)
        .get()
        .then((doc) => doc.data());
    final provider = Provider.of<ProblemReportProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1621),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Icon(Icons.account_balance, color: Colors.white, size: 28),
        ),
        actions: [],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: userDataFuture,
        builder: (context, snapshot) {
          // Show loading indicator while waiting
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle errors
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading profile data',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Get the user data from snapshot
          final userData = snapshot.data ?? {};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 24.0),
                child: Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Rest of your profile content in an Expanded widget
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        // Profile Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181B2C),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white24,
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userData['fullName'] ?? 'User',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.email ?? '',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      userData['role'] == 'government'
                                          ? 'Government Official'
                                          : userData['role'] == 'citizen'
                                          ? 'Citizen'
                                          : 'Advertiser',
                                      style: TextStyle(
                                        color:
                                            userData['role'] == 'government'
                                                ? Colors.blue
                                                : userData['role'] == 'citizen'
                                                ? Colors.green
                                                : Colors.orange,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Rest of your UI remains the same
                        const SizedBox(height: 24),

                        // Profile Actions
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF181B2C),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _buildProfileAction(
                                context,
                                icon: Icons.edit,
                                title: 'Edit Profile',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const EditProfileScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildProfileAction(
                                context,
                                icon: Icons.settings,
                                title: 'Settings',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const SettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Account Actions
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF181B2C),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _buildProfileAction(
                                context,
                                icon: Icons.logout,
                                title: 'Sign Out',
                                onTap: () async {
                                  // Your existing sign out code here
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor: const Color(
                                          0xFF1C2F41,
                                        ),
                                        title: const Text(
                                          'Sign Out',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: const Text(
                                          'Are you sure you want to sign out?',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: const Text(
                                              'CANCEL',
                                              style: TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('SIGN OUT'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirmed == true && context.mounted) {
                                    await FirebaseAuth.instance.signOut();
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed('/auth');
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1C2F41),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
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

  // Your existing helper methods below
  Widget _buildProfileAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: Colors.white12,
      height: 1,
      indent: 56,
      endIndent: 16,
    );
  }
}
