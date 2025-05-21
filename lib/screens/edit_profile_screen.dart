import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userData = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          setState(() {
            _nameController.text = userData.data()?['name'] ?? '';
            _phoneController.text = userData.data()?['phone'] ?? '';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error loading user data: $e';
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Update display name in Firebase Auth
          await user.updateDisplayName(_nameController.text);

          // Update additional user data in Firestore
          await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
            'fullName': _nameController.text,
            'phoneNumber': _phoneController.text,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error updating profile: $e';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: theme.appBarTheme.titleTextStyle,
        ),
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.error),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              _buildInputField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: theme.elevatedButtonTheme.style?.copyWith(
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))), // Keep specific radius if needed
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ), // Color will be theme.colorScheme.onPrimary if button bg is primary
                      )
                    : const Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.inputDecorationTheme.labelStyle ?? TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: theme.hintColor),
        filled: true, // Ensure filled is true to use fillColor
        fillColor: theme.inputDecorationTheme.fillColor, // Use fillColor from theme
        // Explicitly define the border with the desired borderRadius,
        // while trying to respect other border properties from the theme if possible,
        // or just define a new one if the theme's border isn't an OutlineInputBorder.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), // Specific borderRadius for this input field
          borderSide: theme.inputDecorationTheme.border?.borderSide ?? BorderSide.none, // Use theme's borderSide or none
        ),
        enabledBorder: OutlineInputBorder( // Also apply to enabledBorder
          borderRadius: BorderRadius.circular(24),
          borderSide: theme.inputDecorationTheme.enabledBorder?.borderSide ?? BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder( // And focusedBorder for consistency
          borderRadius: BorderRadius.circular(24),
          borderSide: theme.inputDecorationTheme.focusedBorder?.borderSide ?? BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
