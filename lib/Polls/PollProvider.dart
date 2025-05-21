import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:govconnect/Polls/Votes.dart';
import 'package:govconnect/Polls/polls.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Pollproviders with ChangeNotifier {
  List<Polls> _polls = [];
  final Map<String, String> _userVotes = {}; // Tracks user votes locally

  List<Polls> get getPolls => _polls;

  String? getUserVote(String pollId) => _userVotes[pollId];

  // Fetch polls and user votes from Firestore
  Future<void> fetchPolls() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Clear the user votes map to avoid conflicts with previous users
      _userVotes.clear();

      // Fetch polls
      final snapshot =
          await FirebaseFirestore.instance.collection('polls').get();
      _polls = await Future.wait(
        snapshot.docs.map((doc) async {
          final pollData = doc.data();
          final pollId = doc.id;

          // Fetch votes for the poll
          final votesSnapshot =
              await FirebaseFirestore.instance
                  .collection('polls')
                  .doc(pollId)
                  .collection('votes')
                  .get();

          final votes =
              votesSnapshot.docs.map((voteDoc) {
                return Votes.fromFirestore(voteDoc.id, voteDoc.data());
              }).toList();

          return Polls(
            pollId: pollId,
            question: pollData['question'] as String,
            options: List<String>.from(pollData['options'] as List),
            createdBy: pollData['createdBy'] as String,
            createdAt: (pollData['createdAt'] as Timestamp).toDate(),
            votes: votes,
            comments: [], // Initialize with an empty list of comments
          );
        }).toList(),
      );

      // Fetch user votes
      for (var poll in _polls) {
        final voteSnapshot =
            await FirebaseFirestore.instance
                .collection('polls')
                .doc(poll.pollId)
                .collection('votes')
                .doc(userId)
                .get();

        if (voteSnapshot.exists) {
          _userVotes[poll.pollId] =
              voteSnapshot.data()?['selectedOption'] as String? ?? '';
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching polls or votes: $e');
    }
  }

  // Add a poll to Firestore and update the local list
  Future<void> addPoll(
    String question,
    List<String> options,
    String createdBy,
  ) async {
    try {
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
        votes:
            [], // Provide an empty list of Votes as the initial value for votes
        comments: [], // Provide an empty list of PollComment as the initial value for comments
      );
      _polls.add(newPoll);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding poll: $e');
      throw e; // Re-throw the error to handle it in the UI
    }
  }

  // Submit a vote and update locally
  Future<void> vote(String pollId, String selectedOption) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final pollRef = FirebaseFirestore.instance
          .collection('polls')
          .doc(pollId);

      // Update Firestore
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final pollSnapshot = await transaction.get(pollRef);

        if (!pollSnapshot.exists) {
          throw Exception('Poll does not exist');
        }

        // Add user vote
        final voteRef = pollRef.collection('votes').doc(user.uid);
        transaction.set(voteRef, {
          'voteId': user.uid,
          'userId': user.uid,
          'selectedOption': selectedOption,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      // Fetch updated votes for the poll
      await fetchVotes(pollId);

      notifyListeners(); // Notify listeners to refresh the UI
    } catch (e) {
      debugPrint('Error voting: $e');
      throw e;
    }
  }

  Future<void> fetchVotes(String pollId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('polls')
              .doc(pollId)
              .collection('votes')
              .get();

      final votes =
          snapshot.docs.map((doc) {
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
          comments: _polls[pollIndex].comments, // Keep existing comments
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching votes: $e');
    }
  }
}
