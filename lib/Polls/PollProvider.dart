import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Polls.dart';

class Pollproviders with ChangeNotifier {
  List<Polls> _polls = [];

  List<Polls> get getPolls {
    return _polls;
  }

  // Fetch polls from Firestore
  Future<void> fetchPolls() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('polls').get();
      _polls =
          snapshot.docs.map((doc) {
            return Polls.fromFirestore(doc.id, doc.data());
          }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching polls: $e');
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
      });

      // Add the poll to the local list
      final newPoll = Polls(
        pollId: docRef.id,
        question: question,
        options: options,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );
      _polls.add(newPoll);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding poll: $e');
      throw e; // Re-throw the error to handle it in the UI
    }
  }
}
