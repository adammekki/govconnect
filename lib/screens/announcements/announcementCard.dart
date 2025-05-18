import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:govconnect/screens/announcements/announcementProvider.dart';
import 'package:govconnect/screens/announcements/announcements.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:translator/translator.dart';

class AnnouncementCard extends StatefulWidget {
  final Announcement announcement;
  final bool showFullContent;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.showFullContent = false,
  });

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  bool _isCurrentUserCreator = false;
  bool _isGovernmentUser = false;
  String? _creatorFullName;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
    _fetchCreatorFullName();
  }

  void _checkUserStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Check if current user is the creator
      if (currentUser.uid == widget.announcement.createdBy) {
        if (mounted) {
          setState(() {
            _isCurrentUserCreator = true;
          });
        }
      }
      // Check if current user is a government user
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(currentUser.uid)
                .get();
        final data = doc.data();
        if (data != null &&
            (data['role'] == 'government' || data['isGovernment'] == true)) {
          if (mounted) {
            setState(() {
              _isGovernmentUser = true;
            });
          }
        }
      } catch (e) {
        // Optionally handle error
      }
    }
  }

  Future<void> _fetchCreatorFullName() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(widget.announcement.createdBy)
              .get();
      final data = doc.data();
      if (data != null && data['fullName'] != null) {
        if (mounted) {
          setState(() {
            _creatorFullName = data['fullName'];
          });
        }
      }
    } catch (e) {
      // Optionally handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF131E2F);
    const secondaryColor = Color(0xFF24283B);
    const backgroundColor = Color(0xFF131E2F);
    const cardColor = Color(0xFF131E2F);
    const accentColor = Color(0xFF7AA2F7);
    const textColorPrimary = Colors.white;
    const textColorSecondary = Color.fromARGB(255, 255, 255, 255);
    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(widget.announcement.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and user info
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: accentColor,
                  child: Icon(Icons.account_balance, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _creatorFullName ?? 'Loading...',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColorPrimary,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColorSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: textColorSecondary),
                  onPressed: () => _showOptionsMenu(context),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Announcement content
            Text(
              widget.announcement.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColorPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.showFullContent
                  ? widget.announcement.description
                  : _truncateDescription(widget.announcement.description),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: textColorPrimary,
              ),
            ),

            // "Read more" button if content is truncated
            if (!widget.showFullContent &&
                widget.announcement.description.length > 150) ...[
              TextButton(
                onPressed: () => _showFullAnnouncement(context),
                child: const Text(
                  'Read more',
                  style: TextStyle(color: accentColor),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
              ),
            ],

            // Media attachment
            if (widget.announcement.mediaUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap:
                      () => _showFullScreenImage(
                        context,
                        widget.announcement.mediaUrl!,
                      ),
                  child: Image.network(
                    widget.announcement.mediaUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: secondaryColor,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: accentColor,
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: secondaryColor,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: textColorSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            if (widget.announcement.imageBase64 != null &&
                widget.announcement.imageBase64!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(widget.announcement.imageBase64!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                ),
              ),
            ],

            // Action buttons
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Comment button
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.mode_comment_outlined,
                          color: textColorSecondary,
                        ),
                        onPressed: () => _showCommentDialog(context),
                      ),
                      Text(
                        widget.announcement.comments.length.toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColorSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Share button
                  IconButton(
                    icon: const Icon(Icons.share, color: textColorSecondary),
                    onPressed: () => _shareAnnouncement(),
                  ),

                  // Like button (optional)
                  IconButton(
                    icon: const Icon(
                      Icons.favorite_border,
                      color: textColorSecondary,
                    ),
                    onPressed: () {}, // Implement like functionality if needed
                  ),
                ],
              ),
            ),

            // Comments preview
            if (widget.announcement.comments.isNotEmpty) ...[
              const Divider(height: 24, color: textColorSecondary),
              Column(
                children: [
                  for (final comment in widget.announcement.comments.take(2))
                    CommentTile(comment: comment),
                  if (widget.announcement.comments.length > 2)
                    TextButton(
                      onPressed: () => _showAllComments(context),
                      child: Text(
                        'View all ${widget.announcement.comments.length} comments',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: accentColor,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _truncateDescription(String description) {
    if (description.length <= 150) return description;
    return '${description.substring(0, 150)}...';
  }

  void _showOptionsMenu(BuildContext context) {
    const textColorPrimary = Colors.white;
    const textColorSecondary = Color(0xFFA9B1D6);
    const accentColor = Color(0xFF7AA2F7);
    const cardColor = Color(0xFF0E1621);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      builder: (context) {
        return Wrap(
          children: [
            if (_isCurrentUserCreator)
              ListTile(
                leading: const Icon(Icons.edit, color: textColorSecondary),
                title: const Text(
                  'Edit announcement',
                  style: TextStyle(color: textColorPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context);
                },
              ),
            if (_isCurrentUserCreator)
              ListTile(
                leading: const Icon(Icons.delete, color: textColorSecondary),
                title: const Text(
                  'Delete announcement',
                  style: TextStyle(color: textColorPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.flag, color: textColorSecondary),
              title: const Text(
                'Report post',
                style: TextStyle(color: textColorPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: textColorSecondary),
              title: const Text(
                'Cancel',
                style: TextStyle(color: textColorPrimary),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _showFullAnnouncement(BuildContext context) {
    const primaryColor = Color.fromARGB(255, 26, 27, 38);
    const backgroundColor = Color(0xFF0E1621);
    const textColorPrimary = Colors.white;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: backgroundColor,
              appBar: AppBar(
                backgroundColor: primaryColor,
                iconTheme: const IconThemeData(color: textColorPrimary),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AnnouncementCard(
                  announcement: widget.announcement,
                  showFullContent: true,
                ),
              ),
            ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Center(
                child: InteractiveViewer(child: Image.network(imageUrl)),
              ),
            ),
      ),
    );
  }

  void _showCommentDialog(BuildContext context) {
    const cardColor = Color(0xFF1A1B26);
    const accentColor = Color(0xFF7AA2F7);
    const textColorPrimary = Colors.white;
    const textColorSecondary = Color(0xFFA9B1D6);
    const secondaryColor = Color(0xFF24283B);

    final commentController = TextEditingController();
    final isAnonymous = ValueNotifier(false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: accentColor,
                      child: Icon(Icons.person, color: textColorPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isAnonymous,
                        builder: (context, value, child) {
                          return CheckboxListTile(
                            title: const Text(
                              'Post anonymously',
                              style: TextStyle(color: textColorPrimary),
                            ),
                            value: value,
                            onChanged: (v) => isAnonymous.value = v!,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: accentColor,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: commentController,
                  style: const TextStyle(color: textColorPrimary),
                  decoration: InputDecoration(
                    hintText: 'Write your comment...',
                    hintStyle: const TextStyle(color: textColorSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: accentColor),
                      onPressed: () async {
                        if (commentController.text.trim().isEmpty) return;

                        try {
                          final provider = Provider.of<AnnouncementsProvider>(
                            context,
                            listen: false,
                          );
                          await provider.addComment(
                            widget.announcement.id,
                            commentController.text.trim(),
                            isAnonymous.value,
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error posting comment: $e'),
                              backgroundColor: cardColor,
                            ),
                          );
                        }
                      },
                    ),
                    fillColor: secondaryColor,
                    filled: true,
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAllComments(BuildContext context) {
    const cardColor = Color(0xFF1A1B26);
    const textColorPrimary = Colors.white;
    const textColorSecondary = Color(0xFFA9B1D6);
    const accentColor = Color(0xFF7AA2F7);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(
                          color: textColorPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: textColorSecondary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: textColorSecondary),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: widget.announcement.comments.length,
                    itemBuilder: (context, index) {
                      return CommentTile(
                        comment: widget.announcement.comments[index],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _shareAnnouncement() {
    Share.share(
      '${widget.announcement.title}\n\n${widget.announcement.description}\n\nShared via Bristol Community App',
    );
  }

  void _showEditDialog(BuildContext context) {
    const cardColor = Color(0xFF1A1B26);
    const accentColor = Color(0xFF7AA2F7);
    const textColorPrimary = Colors.white;
    const textColorSecondary = Color(0xFFA9B1D6);
    const secondaryColor = Color(0xFF24283B);

    final titleController = TextEditingController(
      text: widget.announcement.title,
    );
    final descriptionController = TextEditingController(
      text: widget.announcement.description,
    );
    String selectedCategory = widget.announcement.category;
    final List<String> categories = [
      'General',
      'Update',
      'Emergency',
      'Event',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Edit Announcement',
            style: TextStyle(color: textColorPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: textColorPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    hintStyle: TextStyle(color: textColorSecondary),
                    border: OutlineInputBorder(),
                    fillColor: secondaryColor,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: textColorPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Description',
                    hintStyle: TextStyle(color: textColorSecondary),
                    border: OutlineInputBorder(),
                    fillColor: secondaryColor,
                    filled: true,
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  dropdownColor: secondaryColor,
                  style: const TextStyle(color: textColorPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: textColorSecondary),
                    border: OutlineInputBorder(),
                    fillColor: secondaryColor,
                    filled: true,
                  ),
                  items:
                      categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedCategory = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: accentColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await Provider.of<AnnouncementsProvider>(
                    context,
                    listen: false,
                  ).updateAnnouncement(
                    announcementId: widget.announcement.id,
                    title: titleController.text,
                    description: descriptionController.text,
                    category: selectedCategory,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Announcement updated!'),
                      backgroundColor: cardColor,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: cardColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    const cardColor = Color(0xFF1A1B26);
    const accentColor = Color(0xFF7AA2F7);
    const textColorPrimary = Colors.white;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: cardColor,
            title: const Text(
              'Delete Announcement',
              style: TextStyle(color: textColorPrimary),
            ),
            content: const Text(
              'Are you sure you want to delete this announcement?',
              style: TextStyle(color: textColorPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: accentColor),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await Provider.of<AnnouncementsProvider>(
                      context,
                      listen: false,
                    ).deleteAnnouncement(widget.announcement.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Announcement deleted!'),
                        backgroundColor: cardColor,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: cardColor,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showReportDialog(BuildContext context) {
    const cardColor = Color(0xFF1A1B26);
    const textColorPrimary = Colors.white;
    const accentColor = Color(0xFF7AA2F7);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: cardColor,
            title: const Text(
              'Report Post',
              style: TextStyle(color: textColorPrimary),
            ),
            content: const Text(
              'Thank you for helping us keep the community safe. This feature is coming soon.',
              style: TextStyle(color: textColorPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: accentColor)),
              ),
            ],
          ),
    );
  }
}

class CommentTile extends StatefulWidget {
  final Comment comment;
  const CommentTile({super.key, required this.comment});

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  String? _translated;
  bool _isTranslating = false;

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  Future<void> _toggleTranslation() async {
    if (_translated != null) {
      setState(() {
        _translated = null;
      });
      return;
    }
    setState(() => _isTranslating = true);
    final translator = GoogleTranslator();
    final text = widget.comment.content;
    final target = _isArabic(text) ? 'en' : 'ar';
    final translation = await translator.translate(text, to: target);
    setState(() {
      _translated = translation.text;
      _isTranslating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(widget.comment.createdAt);
    final isCurrentUserComment =
        FirebaseAuth.instance.currentUser?.uid == widget.comment.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(
                  widget.comment.anonymous
                      ? Icons.visibility_off
                      : Icons.person,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.comment.anonymous
                              ? 'Anonymous'
                              : 'Community Member',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (isCurrentUserComment && !widget.comment.anonymous)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        const Spacer(),
                        // Optionally add a delete button here if you want
                      ],
                    ),
                    Text(
                      widget.comment.content,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_translated != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _translated!,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _isTranslating ? null : _toggleTranslation,
              child:
                  _isTranslating
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(
                        _translated == null
                            ? 'See Translation'
                            : 'Hide Translation',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

bool _isArabic(String text) {
  // Checks if the text contains any Arabic characters
  return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
}
