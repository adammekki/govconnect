import 'package:flutter/material.dart';
import 'package:govconnect/providers/PollProvider.dart';
import 'package:govconnect/Polls/Polls.dart';
import 'package:provider/provider.dart';
import 'package:govconnect/Polls/PollCommentTile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:profanity_filter/profanity_filter.dart';

class Pollcard extends StatefulWidget {
  final Polls poll;

  const Pollcard({super.key, required this.poll});

  @override
  State<Pollcard> createState() => _PollCardState();
}

class _PollCardState extends State<Pollcard> {
  String? _selectedOption;
  bool _isGovernmentUser = false;
  bool _isCitizenUser = false;
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
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(currentUser.uid)
                .get();

        final data = doc.data();
        if (data != null && data['role'] != null) {
          setState(() {
            _isGovernmentUser = data['role'] == 'government';
            _isCitizenUser = data['role'] == 'citizen';
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _fetchCreatorFullName() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('polls')
              .doc(widget.poll.pollId)
              .get();

      if (!mounted)
        return; // Check if widget is still mounted before setting state

      final data = doc.data();
      if (data?['createdBy'] != null) {
        setState(() {
          _creatorFullName = data?['createdBy'];
        });
      } else {
        // Fallback if fullName field doesn't exist
        setState(() {
          _creatorFullName = data?['createdBy'] ?? 'User1';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _creatorFullName = 'User2'; // Fallback on error
        });
        print('Error fetching user name: $e');
      }
    }
  }

  void _showPollOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit poll'),
              onTap: () {
                Navigator.pop(context);
                _showEditPollDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete poll'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletePoll(context);
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

  void _confirmDeletePoll(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Poll'),
            content: const Text('Are you sure you want to delete this poll?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  try {
                    Navigator.pop(context);
                    await Provider.of<Pollproviders>(
                      context,
                      listen: false,
                    ).deletePoll(widget.poll.pollId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Poll deleted!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showEditPollDialog(BuildContext context) {
    final questionController = TextEditingController(
      text: widget.poll.question,
    );
    final List<TextEditingController> optionControllers =
        widget.poll.options
            .map((option) => TextEditingController(text: option))
            .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Poll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ...optionControllers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Option ${idx + 1}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        if (optionControllers.length > 2)
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              optionControllers.removeAt(idx);
                              (context as Element).markNeedsBuild();
                            },
                          ),
                      ],
                    ),
                  );
                }),
                if (optionControllers.length < 4)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Option'),
                      onPressed: () {
                        optionControllers.add(TextEditingController());
                        (context as Element).markNeedsBuild();
                      },
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
            ElevatedButton(
              onPressed: () async {
                final question = questionController.text.trim();
                final options =
                    optionControllers
                        .map((c) => c.text.trim())
                        .where((o) => o.isNotEmpty)
                        .toList();
                if (question.isEmpty || options.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a question and at least 2 options.',
                      ),
                    ),
                  );
                  return;
                }
                try {
                  await Provider.of<Pollproviders>(
                    context,
                    listen: false,
                  ).updatePoll(
                    pollId: widget.poll.pollId,
                    question: question,
                    options: options,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Poll updated!')),
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

  void _showPollCommentDialog(BuildContext context) {
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
      backgroundColor: Color(0xFF1C2F41),
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
                        final commentText = commentController.text.trim();
                        if (commentText.isEmpty) return;

                        final customDictionary =
                            [
                              // Arabic profanity words
                              'كلمة_سيئة',
                              'شتيمة',
                              'لعنة',
                              'قذر',
                              'سخيف',
                              'تباً',
                              'تفو',
                              'أحمق',
                              'كلب',
                              'حمار',
                              'خنزير',
                              'حقير',
                              'وقح',
                              'تافه',
                              'غبي',
                              'مجنون',
                              'سافل',
                              'نذل',
                              'منحرف',
                              'نجس',
                              'واطي',
                              'مقرف',
                              'ملعون',
                              'مخنث',
                              'شرموطة',
                              'زاني',
                              'زانية',
                              'زفت',
                              'عرص',
                              'متخلف',
                              'معفن',
                              'مزبلة',
                              'كس',
                              'طيز',
                              'نيك',
                              'منيوك',
                              'قحبة',
                              'شرموط',
                              'بعبص',
                              'زق',
                              'عرصة',
                              'زب',
                            ];

                        final filter = ProfanityFilter.filterAdditionally(customDictionary);
                       
                        if (filter.hasProfanity(commentText)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Your comment contains inappropriate language and cannot be posted.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          final provider = Provider.of<Pollproviders>(
                            context,
                            listen: false,
                          );
                          await provider.addComment(
                            widget.poll.pollId,
                            commentText,
                            isAnonymous.value,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error posting comment: $e'),
                                backgroundColor: cardColor,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    fillColor: Color(0xFF1C2F41),
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

  void _showAllPollComments(BuildContext context) {
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
                      const Text('Comments'),
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
                    itemCount: widget.poll.comments.length,
                    itemBuilder: (context, index) {
                      final comment = widget.poll.comments[index];
                      return PollCommentTile(
                        comment: comment,
                        onDelete: (commentId) async {
                          await Provider.of<Pollproviders>(
                            context,
                            listen: false,
                          ).deleteComment(widget.poll.pollId, commentId);
                        },
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

  @override
  Widget build(BuildContext context) {
    final pollProvider = Provider.of<Pollproviders>(context);
    final userVote = pollProvider.getUserVote(widget.poll.pollId);

    // Calculate total votes
    final totalVotes = widget.poll.votes.length;

    // Calculate percentage for each option
    Map<String, double> percentages = {};
    Map<String, int> voteCounts = {};

    for (var option in widget.poll.options) {
      final voteCount =
          widget.poll.votes
              .where((vote) => vote.selectedOption == option)
              .length;
      voteCounts[option] = voteCount;
      percentages[option] = totalVotes > 0 ? (voteCount / totalVotes) * 100 : 0;
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      color: const Color(0xFF1C2F41),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFF1E2A39),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _creatorFullName ?? 'Loading...',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.poll.question,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_isGovernmentUser)
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                    onPressed: () => _showPollOptionsMenu(context),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Poll options with progress bars
            ...widget.poll.options.map((option) {
              final percentage = percentages[option]?.round() ?? 0;
              final isSelected =
                  (userVote == option || _selectedOption == option);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GestureDetector(
                  onTap:
                      (_isCitizenUser && userVote == null)
                          ? () {
                            setState(() {
                              _selectedOption = option;
                            });
                          }
                          : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          // Background container
                          Container(
                            height: 45,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 46, 66, 94),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),

                          // Progress bar
                          Container(
                            height: 45,
                            width:
                                MediaQuery.of(context).size.width *
                                (percentage / 100) *
                                0.7,
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? Colors.blue
                                      : Colors.blue.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),

                          // Option text
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    option,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    '$percentage%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 10),

            // Vote count and date
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalVotes votes',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    Text(
                      'Created on: ${_formatDate(widget.poll.createdAt)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                // Comment button - visible to all users
                IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                  ),
                  onPressed: () => _showPollCommentDialog(context),
                ),
                Text(
                  widget.poll.comments.length.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),

            // Only citizens can submit a vote
            if (_isCitizenUser && userVote == null && _selectedOption != null)
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await pollProvider.vote(
                        widget.poll.pollId,
                        _selectedOption!,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vote submitted successfully!'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to submit vote: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Submit Vote'),
                ),
              ),

            if (widget.poll.comments.isNotEmpty) ...[
              const Divider(height: 24),
              Column(
                children: [
                  for (final comment in widget.poll.comments.take(2))
                    PollCommentTile(
                      comment: comment,
                      onDelete: (commentId) async {
                        await Provider.of<Pollproviders>(
                          context,
                          listen: false,
                        ).deleteComment(widget.poll.pollId, commentId);
                      },
                    ),
                  if (widget.poll.comments.length > 2)
                    TextButton(
                      onPressed: () => _showAllPollComments(context),
                      child: Text(
                        'View all ${widget.poll.comments.length} comments',
                        style: const TextStyle(color: Colors.blue),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
