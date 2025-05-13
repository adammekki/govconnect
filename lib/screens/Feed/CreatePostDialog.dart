import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:govconnect/screens/announcements/announcementProvider.dart';
import 'package:govconnect/Polls/PollProvider.dart';
import 'package:govconnect/Polls/PollForm.dart';
import 'package:govconnect/screens/announcements/AnnouncementForm.dart';
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
  
  // Controllers for announcement
  final TextEditingController _announcementTitleController = TextEditingController();
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
        const SnackBar(content: Text('Please enter a title for your announcement')),
      );
      return;
    }
    
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something for your announcement')),
      );
      return;
    }

    try {
      final provider = Provider.of<AnnouncementsProvider>(context, listen: false);
      await provider.createAnnouncement(
        title: title,
        description: description,
        category: _selectedCategory,
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
    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
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
      await Provider.of<Pollproviders>(context, listen: false).addPoll(
        question,
        options,
        userFullName,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poll created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create poll: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on tap outside
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: const Color(0xFF1C3A5F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Arrow/cancel button at the top left
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: widget.onClose,
                        tooltip: 'Cancel',
                      ),
                      const Spacer(),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Create new post',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Toggle between Announcement and Polls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Announcement button
                      GestureDetector(
                        onTap: () => _togglePostType(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isPollSelected 
                                ? Colors.blue.withOpacity(0.2) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: !_isPollSelected ? Colors.blue : Colors.grey,
                            ),
                          ),
                          child: Text(
                            'Announcement',
                            style: TextStyle(
                              color: !_isPollSelected ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 10),
                      
                      // Poll button
                      GestureDetector(
                        onTap: () => _togglePostType(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isPollSelected 
                                ? Colors.blue.withOpacity(0.2) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isPollSelected ? Colors.blue : Colors.grey,
                            ),
                          ),
                          child: Text(
                            'Polls',
                            style: TextStyle(
                              color: _isPollSelected ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Content based on selected type
                  _isPollSelected 
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
                      ),
                  
                  const SizedBox(height: 16),
                  
                  // Create post button
                  GestureDetector(
                    onTap: _createPost,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
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