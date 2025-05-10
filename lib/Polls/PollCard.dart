import 'package:flutter/material.dart';
import 'package:govconnect/Polls/PollProvider.dart';
import 'package:govconnect/Polls/Polls.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Pollcard extends StatefulWidget {
  final Polls poll;

  const Pollcard({super.key, required this.poll});

  @override
  State<Pollcard> createState() => _PollCardState();
}

class _PollCardState extends State<Pollcard> {
  String? _selectedOption;
  bool _isCurrentUserCreator = false;

  @override
  void initState() {
    super.initState();
    _checkIfUserIsCreator();
  }

  // Check if the current logged-in user is the creator of this poll
  void _checkIfUserIsCreator() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.displayName == widget.poll.createdBy) {
      setState(() {
        _isCurrentUserCreator = true;
      });
    }
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
      color: const Color(0xFF131E2F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: const NetworkImage(
                    'https://via.placeholder.com/40',
                  ),
                  radius: 25,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.poll.createdBy,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (_isCurrentUserCreator)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        ],
                      ),
                      Text(
                        widget.poll.question,
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  onPressed: () {},
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
                      userVote == null
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
                              color: const Color(0xFF1E2939),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),

                          // Progress bar
                          Container(
                            height: 45,
                            width:
                                MediaQuery.of(context).size.width *
                                (percentage / 100) *
                                0.7, // Adjust multiplier as needed
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
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
              ],
            ),

            // Only show vote button if user hasn't voted yet
            if (userVote == null && _selectedOption != null)
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
          ],
        ),
      ),
    );
  }
  
  // Helper method to format the date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}