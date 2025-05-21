import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:govconnect/providers/announcementProvider.dart';
import 'package:govconnect/providers/PollProvider.dart';
import 'package:govconnect/Polls/PollForm.dart';
import 'package:govconnect/screens/announcements/AnnouncementForm.dart';
import 'dart:ui';

class CreatePostDialog extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onPostCreated;

  const CreatePostDialog({
    Key? key,
    required this.onClose,
    required this.onPostCreated,
  }) : super(key: key);

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  bool _isPollSelected = false;
  String? _announcementImageBase64;

  // Controllers for announcement
  final TextEditingController _announcementTitleController =
      TextEditingController();
  final TextEditingController _announcementController = TextEditingController();
  String _selectedCategory = 'General';

  // Controllers for poll
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  void _togglePostType(bool isPoll) {
    setState(() {
      _isPollSelected = isPoll;
    });
  }

  void _addOption() {
    if (_optionControllers.length < 4) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 options are required')),
      );
    }
  }

  Future<void> _createPost() async {
    if (_isPollSelected) {
      await _createPoll();
    } else {
      await _createAnnouncement();
    }
    widget.onPostCreated();
  }

  Future<void> _createAnnouncement() async {
    final title = _announcementTitleController.text.trim();
    final description = _announcementController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for your announcement'),
        ),
      );
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something for your announcement'),
        ),
      );
      return;
    }

    try {
      final provider = Provider.of<AnnouncementsProvider>(
        context,
        listen: false,
      );
      await provider.createAnnouncement(
        title: title,
        description: description,
        category: _selectedCategory,
        imageBase64: _announcementImageBase64, // <-- pass this!
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement posted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post announcement: $e')),
      );
    }
  }

  Future<void> _createPoll() async {
    final question = _questionController.text;
    final options =
        _optionControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();

    if (question.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a question')));
      return;
    }

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 2 options are required')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final userFullName = user.displayName ?? 'Anonymous';
      await Provider.of<Pollproviders>(
        context,
        listen: false,
      ).addPoll(question, options, userFullName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poll created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create poll: $e')));
    }
  }

@override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    child: Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0E1621),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2F41),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: widget.onClose,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Create new post',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Toggle between Announcement and Polls
                  // Toggle buttons with padding
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      // Announcement button
                      GestureDetector(
                        onTap: () => _togglePostType(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                !_isPollSelected
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  !_isPollSelected ? Colors.blue : Colors.grey,
                            ),
                          ),
                          child: Text(
                            'Announcement',
                            style: TextStyle(
                              color:
                                  !_isPollSelected ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Poll button
                      GestureDetector(
                        onTap: () => _togglePostType(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _isPollSelected
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  _isPollSelected ? Colors.blue : Colors.grey,
                            ),
                          ),
                          child: Text(
                            'Polls',
                            style: TextStyle(
                              color:
                                  _isPollSelected ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                                         ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Content with padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _isPollSelected
                        ? PollForm(
                            questionController: _questionController,
                            optionControllers: _optionControllers,
                            onAddOption: _addOption,
                            onRemoveOption: _removeOption,
                          )
                        : AnnouncementForm(
                            titleController: _announcementTitleController,
                            descriptionController: _announcementController,
                            selectedCategory: _selectedCategory,
                            onCategoryChanged: (category) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            onImageSelected: (base64) {
                              _announcementImageBase64 = base64;
                            },
                          ),
                  ),

                  // Create post button with padding
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: _createPost,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B5998),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Create post',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  @override
  void dispose() {
    _announcementTitleController.dispose();
    _announcementController.dispose();
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
