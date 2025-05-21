// PollCommentTile.dart
import 'package:flutter/material.dart';
import 'package:govconnect/Polls/PollComment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:translator/translator.dart';

class PollCommentTile extends StatefulWidget {
  final PollComment comment;
  final Function(String)? onDelete;

  const PollCommentTile({super.key, required this.comment, this.onDelete});

  @override
  State<PollCommentTile> createState() => _PollCommentTileState();
}

class _PollCommentTileState extends State<PollCommentTile> {
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
                              : widget.comment.userName ?? 'Anonymous',
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
                          color: Colors.white, // Make the button text white
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteComment(BuildContext context, String commentId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Comment'),
            content: const Text(
              'Are you sure you want to delete this comment?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  if (widget.onDelete != null) {
                    widget.onDelete!(commentId);
                  }
                },
                child: const Text('Delete'),
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
