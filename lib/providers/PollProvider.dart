// PollProvider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:govconnect/Polls/Votes.dart';
import 'package:govconnect/Polls/PollComment.dart';
import '../Polls/Polls.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Pollproviders with ChangeNotifier {
  List<Polls> _polls = [];
  final Map<String, String> _userVotes = {}; // Tracks user votes locally
  bool _isLoading = false; // Added isLoading property

  List<Polls> get getPolls => _polls;
  bool get isLoading => _isLoading; // Added getter for isLoading

  String? getUserVote(String pollId) => _userVotes[pollId];

  // Fetch polls and user votes from Firestore
  Future<void> fetchPolls() async {
    try {
      _isLoading = true; // Set loading to true before fetching
      notifyListeners();

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Clear the user votes map to avoid conflicts with previous users
      _userVotes.clear();

      // Fetch polls
      final snapshot = await FirebaseFirestore.instance.collection('polls').get();
      _polls = await Future.wait(
        snapshot.docs.map((doc) async {
          final pollData = doc.data();
          final pollId = doc.id;

          // Fetch votes for the poll
          final votesSnapshot = await FirebaseFirestore.instance
              .collection('polls')
              .doc(pollId)
              .collection('votes')
              .get();

          final votes = votesSnapshot.docs.map((voteDoc) {
            return Votes.fromFirestore(voteDoc.id, voteDoc.data());
          }).toList();

          // Fetch comments for the poll
          final commentsSnapshot = await FirebaseFirestore.instance
              .collection('polls')
              .doc(pollId)
              .collection('comments')
              .orderBy('createdAt', descending: true)
              .get();

          final comments = commentsSnapshot.docs.map((commentDoc) {
            return PollComment.fromFirestore(commentDoc.id, commentDoc.data());
          }).toList();

          return Polls(
            pollId: pollId,
            question: pollData['question'] as String,
            options: List<String>.from(pollData['options'] as List),
            createdBy: pollData['createdBy'] as String,
            createdAt: (pollData['createdAt'] as Timestamp).toDate(),
            votes: votes,
            comments: comments, // Include comments in the poll object
          );
        }).toList(),
      );

      // Fetch user votes
      for (var poll in _polls) {
        final voteSnapshot = await FirebaseFirestore.instance
            .collection('polls')
            .doc(poll.pollId)
            .collection('votes')
            .doc(userId)
            .get();

        if (voteSnapshot.exists) {
          _userVotes[poll.pollId] = voteSnapshot.data()?['selectedOption'] as String? ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error fetching polls or votes: $e');
    } finally {
      _isLoading = false; // Set loading to false when done, even if there was an error
      notifyListeners();
    }
  }

  // Add a poll to Firestore and update the local list
  Future<void> addPoll(
    String question,
    List<String> options,
    String createdBy,
  ) async {
    try {
      _isLoading = true; // Set loading to true before adding
      notifyListeners();

      final docRef = await FirebaseFirestore.instance.collection('polls').add({
        'question': question,
        'options': options,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'votes': [], // Initialize with an empty list of votes
      });

      // Add the poll to the local list
      final newPoll = Polls(
        pollId: docRef.id,
        question: question,
        options: options,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        votes: [], // Provide an empty list of Votes as the initial value for votes
        comments: [], // Provide an empty list of Comments as the initial value
      );
      _polls.add(newPoll);
    } catch (e) {
      debugPrint('Error adding poll: $e');
      throw e; // Re-throw the error to handle it in the UI
    } finally {
      _isLoading = false; // Set loading to false when done
      notifyListeners();
    }
  }

  // Submit a vote and update locally
  Future<void> vote(String pollId, String selectedOption) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final pollRef = FirebaseFirestore.instance.collection('polls').doc(pollId);

      // Add user vote to Firestore
      await pollRef.collection('votes').doc(user.uid).set({
        'voteId': user.uid,
        'userId': user.uid,
        'selectedOption': selectedOption,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update local poll object
      final pollIndex = _polls.indexWhere((poll) => poll.pollId == pollId);
      if (pollIndex != -1) {
        final updatedVotes = List<Votes>.from(_polls[pollIndex].votes)
          ..add(
            Votes(
              voteId: user.uid,
              userId: user.uid,
              selectedOption: selectedOption,
              createdAt: DateTime.now(),
            ),
          );
        _polls[pollIndex] = Polls(
          pollId: _polls[pollIndex].pollId,
          question: _polls[pollIndex].question,
          options: _polls[pollIndex].options,
          createdBy: _polls[pollIndex].createdBy,
          createdAt: _polls[pollIndex].createdAt,
          votes: updatedVotes,
          comments: _polls[pollIndex].comments,
        );
        _userVotes[pollId] = selectedOption;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error voting: $e');
      throw e;
    }
  }

  // Add a comment to a poll
  Future<void> addComment(
    String pollId,
    String content,
    bool anonymous,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      final userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      // Add comment to Firestore
      final commentRef = await FirebaseFirestore.instance
          .collection('polls')
          .doc(pollId)
          .collection('comments')
          .add({
        'userId': user.uid,
        'userName': userSnapshot['fullName'],
        'content': content,
        'anonymous': anonymous,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update local poll object with the new comment
      final pollIndex = _polls.indexWhere((poll) => poll.pollId == pollId);
      if (pollIndex != -1) {
        final newComment = PollComment(
          id: commentRef.id,
          userId: user.uid,
          content: content,
          anonymous: anonymous,
          createdAt: DateTime.now(),
        );

        final updatedComments = List<PollComment>.from(_polls[pollIndex].comments)
          ..insert(0, newComment); // Add at the beginning to show newest first

        _polls[pollIndex] = Polls(
          pollId: _polls[pollIndex].pollId,
          question: _polls[pollIndex].question,
          options: _polls[pollIndex].options,
          createdBy: _polls[pollIndex].createdBy,
          createdAt: _polls[pollIndex].createdAt,
          votes: _polls[pollIndex].votes,
          comments: updatedComments,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding comment: $e');
      throw e;
    }
  }

  // Delete a comment from a poll
  Future<void> deleteComment(String pollId, String commentId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Delete comment from Firestore
      await FirebaseFirestore.instance
          .collection('polls')
          .doc(pollId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Update local poll object by removing the comment
      final pollIndex = _polls.indexWhere((poll) => poll.pollId == pollId);
      if (pollIndex != -1) {
        final updatedComments = List<PollComment>.from(_polls[pollIndex].comments)
          ..removeWhere((comment) => comment.id == commentId);

        _polls[pollIndex] = Polls(
          pollId: _polls[pollIndex].pollId,
          question: _polls[pollIndex].question,
          options: _polls[pollIndex].options,
          createdBy: _polls[pollIndex].createdBy,
          createdAt: _polls[pollIndex].createdAt,
          votes: _polls[pollIndex].votes,
          comments: updatedComments,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      throw e;
    }
  }

  Future<void> fetchVotes(String pollId) async {
    try {
      _isLoading = true; // Set loading to true before fetching votes
      notifyListeners();

      final snapshot = await FirebaseFirestore.instance
          .collection('polls')
          .doc(pollId)
          .collection('votes')
          .get();

      final votes = snapshot.docs.map((doc) {
        return Votes.fromFirestore(doc.id, doc.data());
      }).toList();

      // Update the votes for the specific poll
      final pollIndex = _polls.indexWhere((poll) => poll.pollId == pollId);
      if (pollIndex != -1) {
        _polls[pollIndex] = Polls(
          pollId: _polls[pollIndex].pollId,
          question: _polls[pollIndex].question,
          options: _polls[pollIndex].options,
          createdBy: _polls[pollIndex].createdBy,
          createdAt: _polls[pollIndex].createdAt,
          votes: votes,
          comments: _polls[pollIndex].comments,
        );
      }
    } catch (e) {
      debugPrint('Error fetching votes: $e');
    } finally {
      _isLoading = false; // Set loading to false when done
      notifyListeners();
    }
  }

  // Fetch comments for a specific poll
  Future<void> fetchComments(String pollId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('polls')
          .doc(pollId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();

      final comments = commentsSnapshot.docs.map((commentDoc) {
        return PollComment.fromFirestore(commentDoc.id, commentDoc.data());
      }).toList();

      // Update the comments for the specific poll
      final pollIndex = _polls.indexWhere((poll) => poll.pollId == pollId);
      if (pollIndex != -1) {
        _polls[pollIndex] = Polls(
          pollId: _polls[pollIndex].pollId,
          question: _polls[pollIndex].question,
          options: _polls[pollIndex].options,
          createdBy: _polls[pollIndex].createdBy,
          createdAt: _polls[pollIndex].createdAt,
          votes: _polls[pollIndex].votes,
          comments: comments,
        );
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePoll({
    required String pollId,
    required String question,
    required List<String> options,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('polls').doc(pollId).update({
        'question': question,
        'options': options,
      });
      await fetchPolls();
    } catch (e) {
      debugPrint('Error updating poll: $e');
      rethrow;
    }
  }

  Future<void> deletePoll(String pollId) async {
    try {
      await FirebaseFirestore.instance.collection('polls').doc(pollId).delete();
      await fetchPolls();
    } catch (e) {
      debugPrint('Error deleting poll: $e');
      rethrow;
    }
  }
}