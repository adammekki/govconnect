import 'package:flutter/material.dart';
import 'package:govconnect/screens/edit_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:govconnect/providers/Themeprovider.dart';
import 'package:provider/provider.dart'; // Make sure this is imported

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 24.0),
            child: Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 35,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildSettingsCard(
              context,
              icon: Icons.person,
              title: 'Edit Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildSettingsCard(
              context,
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {
                // Add your navigation or logic here
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildThemeSelector(),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildSettingsCard(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.all(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E1621),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1C2F41),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.logout,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Sign Out',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Are you sure you want to sign out?',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        GestureDetector(
                                          onTap:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              'Sign Out',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );

                if (confirmed == true && context.mounted) {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacementNamed('/auth');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final theme = Theme.of(context); // Get theme here for specific styling
        return Card(
          color: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Consistent with AppTheme
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.brightness_6, color: theme.colorScheme.onSurface),
                  title: Text(
                    'App Theme',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
                  ),
                ),
                RadioListTile<ThemeMode>(
                  activeColor: theme.colorScheme.primary,
                  title: Text('Light Mode', style: TextStyle(color: theme.colorScheme.onSurface)),
                  value: ThemeMode.light,
                  groupValue: themeProvider.themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) themeProvider.setThemeMode(value);
                  },
                ),
                RadioListTile<ThemeMode>(
                  activeColor: theme.colorScheme.primary,
                  title: Text('Dark Mode', style: TextStyle(color: theme.colorScheme.onSurface)),
                  value: ThemeMode.dark,
                  groupValue: themeProvider.themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) themeProvider.setThemeMode(value);
                  },
                ),
                RadioListTile<ThemeMode>(
                  activeColor: theme.colorScheme.primary,
                  title: Text('System Default', style: TextStyle(color: theme.colorScheme.onSurface)),
                  value: ThemeMode.system,
                  groupValue: themeProvider.themeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) themeProvider.setThemeMode(value);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsCard(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Consistent with AppTheme
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.onSurface),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurface.withOpacity(0.54), size: 16),
        onTap: onTap,
      ),
    );
  }
}
