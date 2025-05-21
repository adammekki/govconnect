import 'package:flutter/material.dart';
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
        title: Text(
          'Settings',
          style: theme.appBarTheme.titleTextStyle,
        ),
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsCard(
            context,
            icon: Icons.person,
            title: 'Edit Profile',
            onTap: () {
              Navigator.pushNamed(context, '/edit_profile');
            },
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            context,
            icon: Icons.lock,
            title: 'Change Password',
            onTap: () {
              // Add your navigation or logic here
            },
          ),
          const SizedBox(height: 16),

          // Theme selection section
          _buildThemeSelector(),

          const SizedBox(height: 16),
          _buildSettingsCard(
            context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              // Add your logout logic here
            },
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
