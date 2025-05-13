import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:govconnect/screens/announcements/announcementProvider.dart';
import 'package:govconnect/screens/announcements/announcements.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  void _checkUserStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Check if current user is the creator
      if (currentUser.uid == widget.announcement.createdBy) {
        setState(() {
          _isCurrentUserCreator = true;
        });
      }
      // Check if current user is a government user
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
      final data = doc.data();
      if (data != null &&
          (data['role'] == 'government' || data['isGovernment'] == true)) {
        setState(() {
          _isGovernmentUser = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    const primaryColor = Color(
      0xFF172B4D,
    ); // Dark blue for app bar and main elements
    // ignore: unused_local_variable
    const secondaryColor = Color(
      0xFF3B5998,
    ); // Slightly lighter blue for buttons
    // ignore: unused_local_variable
    const backgroundColor = Color(0xFF0A1929); // Very dark blue for background
    // ignore: unused_local_variable
    const cardColor = Color(0xFF1C3A5F); // Card background color
    // ignore: unused_local_variable
    const accentColor = Color(
      0xFF4D8DFF,
    ); // Blue accent color for interactive elements
    // ignore: unused_local_variable
    const textColorPrimary = Colors.white;
    // ignore: unused_local_variable
    const textColorSecondary = Color(
      0xFFAFBFD2,
    ); // Light gray-blue for secondary text
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final currentUser = FirebaseAuth.instance.currentUser;
    final timeAgo = _formatTimeAgo(widget.announcement.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
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
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.account_balance, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bristol Government',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
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
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.showFullContent
                  ? widget.announcement.description
                  : _truncateDescription(widget.announcement.description),
              style: theme.textTheme.bodyLarge,
            ),

            // "Read more" button if content is truncated
            if (!widget.showFullContent &&
                widget.announcement.description.length > 150) ...[
              TextButton(
                onPressed: () => _showFullAnnouncement(context),
                child: const Text('Read more'),
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
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
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
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.broken_image)),
                      );
                    },
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
                        icon: const Icon(Icons.mode_comment_outlined),
                        onPressed: () => _showCommentDialog(context),
                      ),
                      Text(
                        widget.announcement.comments.length.toString(),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),

                  // Share button
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _shareAnnouncement(),
                  ),

                  // Like button (optional)
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {}, // Implement like functionality if needed
                  ),
                ],
              ),
            ),

            // Comments preview
            if (widget.announcement.comments.isNotEmpty) ...[
              const Divider(height: 24),
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
                          color: theme.primaryColor,
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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            if (_isCurrentUserCreator)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit announcement'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context);
                },
              ),
            if (_isCurrentUserCreator)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete announcement'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Report post'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _showFullAnnouncement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(),
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
    final commentController = TextEditingController();
    final isAnonymous = ValueNotifier(false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                    const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isAnonymous,
                        builder: (context, value, child) {
                          return CheckboxListTile(
                            title: const Text('Post anonymously'),
                            value: value,
                            onChanged: (v) => isAnonymous.value = v!,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
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
                  decoration: InputDecoration(
                    hintText: 'Write your comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
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
                            ),
                          );
                        }
                      },
                    ),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                      Text('Comments'),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
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
          title: const Text('Edit Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
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
              child: const Text('Cancel'),
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
                    const SnackBar(content: Text('Announcement updated!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Announcement'),
            content: const Text(
              'Are you sure you want to delete this announcement?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
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
                      const SnackBar(content: Text('Announcement deleted!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showReportDialog(BuildContext context) {
    // Implement report functionality if needed
  }
}

class CommentTile extends StatelessWidget {
  final Comment comment;

  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Icon(
              comment.anonymous ? Icons.visibility_off : Icons.person,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.anonymous ? 'Anonymous' : 'Community Member',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(comment.content),
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
