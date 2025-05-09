import 'dart:async';
import 'package:govconnect/screens/communication/chat/chatList.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Chat> _chats = [];
  String? _currentUserId;
  bool _isLoading = false;

  // Getters
  List<Chat> get chats => _chats;
  String? get currentUserId => _currentUserId;
  bool get isLoading => _isLoading;

  // Load current user ID from SharedPreferences
  Future<void> _loadCurrentUserId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
      } else {
        // Fallback to SharedPreferences if needed
        final prefs = await SharedPreferences.getInstance();
        _currentUserId = prefs.getString('userId');
      }
      notifyListeners();
    } catch (e) {
      print('Error loading current user ID: $e');
      _currentUserId = null;
    }
  }

  StreamSubscription<QuerySnapshot>? _chatSubscription;

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }

  // Modify init method to use real-time updates
  Future<void> init() async {
    _setLoading(true);
    await _loadCurrentUserId();
    _setupChatListener(); // Replace _loadChats() with this
    _setLoading(false);
  }

  // Add new method for real-time updates
  void _setupChatListener() {
    if (_currentUserId == null) return;

    // Cancel any existing subscription
    _chatSubscription?.cancel();

    // Listen to chats where user is user1
    _chatSubscription = _firestore
        .collection('chat')
        .where('userId1', isEqualTo: _currentUserId)
        .snapshots()
        .listen((snapshot1) async {
      try {
        // Get chats where user is user2
        final snapshot2 = await _firestore
            .collection('chat')
            .where('userId2', isEqualTo: _currentUserId)
            .get();

        final List<Chat> loadedChats = [];

        // Process chats where user is user1
        for (var doc in snapshot1.docs) {
          final data = doc.data();
          loadedChats.add(
            Chat(
              id: doc.id,
              userId1: data['userId1'],
              userId2: data['userId2'],
              lastMessageIndexUser1: data['lastMessageIndexUser1'],
              lastMessageIndexUser2: data['lastMessageIndexUser2'],
              userName1: data['userName1'],
              userName2: data['userName2'],
              messages: List<Message>.from(
                (data['messages'] as List).map(
                  (m) => Message(
                    text: m['text'],
                    imageUrl: m['imageUrl'],
                    time: (m['time'] as Timestamp).toDate(),
                    userId: m['userId'],
                  ),
                ),
              ),
            ),
          );
        }

        // Process chats where user is user2
        for (var doc in snapshot2.docs) {
          final data = doc.data();
          loadedChats.add(
            Chat(
              id: doc.id,
              userId1: data['userId1'],
              userId2: data['userId2'],
              lastMessageIndexUser1: data['lastMessageIndexUser1'],
              lastMessageIndexUser2: data['lastMessageIndexUser2'],
              userName1: data['userName1'],
              userName2: data['userName2'],
              messages: List<Message>.from(
                (data['messages'] as List).map(
                  (m) => Message(
                    text: m['text'],
                    imageUrl: m['imageUrl'],
                    time: (m['time'] as Timestamp).toDate(),
                    userId: m['userId'],
                  ),
                ),
              ),
            ),
          );
        }

        _chats = loadedChats;
        sort();
        notifyListeners();
      } catch (e) {
        print('Error in chat listener: $e');
      }
    });
  }
  
  // Send a new message
  Future<void> sendMessage(
    String chatId,
    String text, {
    String? imageUrl,
  }) async {
    if (_currentUserId == null) return;

    try {
      final message = Message(
        text: text,
        imageUrl: imageUrl,
        time: DateTime.now(),
        userId: _currentUserId!,
      );

      // Update Firestore
      await _firestore.collection('chat').doc(chatId).update({
        'messages': FieldValue.arrayUnion([
          {
            'text': message.text,
            'imageUrl': message.imageUrl,
            'time': message.time,
            'userId': message.userId,
          },
        ]),
      });

      await seen(chatId);
      sort();
      notifyListeners();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // Sort chats by last message time
  void sort() {
    _chats.sort((a, b) {
      final aLastMessage =
          a.messages.isNotEmpty ? a.messages.last.time : DateTime(0);
      final bLastMessage =
          b.messages.isNotEmpty ? b.messages.last.time : DateTime(0);
      return bLastMessage.compareTo(aLastMessage); // Sort in descending order
    });
  }

  // Create a new chat
  Future<void> createChat(String otherUserId) async {
    if (_currentUserId == null) return;

        // Helper function to get user display name
    Future<String> getUserName(String? userId) async {
      final userDoc = await _firestore.collection('Users').doc(userId).get();
      return userDoc.data()?['fullName'] ?? 'Unknown User';
    }

    final user2 = await getUserName(otherUserId);
    final user1 = await getUserName(_currentUserId);

    try {
      final chatId = const Uuid().v4();
      final chat = Chat(
        id: chatId,
        userId1: _currentUserId!,
        userId2: otherUserId,
        lastMessageIndexUser1: -1,
        lastMessageIndexUser2: -1,
        userName1: user1,
        userName2: user2,
        messages: [],
      );

      // Add to Firestore
      await _firestore.collection('chat').doc(chatId).set({
        'userId1': chat.userId1,
        'userId2': chat.userId2,
        'lastMessageIndexUser1': chat.lastMessageIndexUser1,
        'lastMessageIndexUser2': chat.lastMessageIndexUser2,
        'messages': [],
        'userName1': chat.userName1,
        'userName2': chat.userName2,
      });

      notifyListeners();
    } catch (e) {
      print('Error creating chat: $e');
    }
  }

  // Helper method to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Get a specific chat by ID
  Chat? getChatById(String chatId) {
    try {
      return _chats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('chat').doc(chatId).delete();

      // Update local state
      _chats.removeWhere((chat) => chat.id == chatId);
      notifyListeners();
    } catch (e) {
      print('Error deleting chat: $e');
    }
  }

  // Modify seen to use Firebase
  Future<void> seen(String chatId) async {
    if (_currentUserId == null) return;

    try {
      final chat = _chats.firstWhere((chat) => chat.id == chatId);
      final fieldToUpdate =
          chat.userId1 == _currentUserId
              ? 'lastMessageIndexUser1'
              : 'lastMessageIndexUser2';

      await _firestore.collection('chat').doc(chatId).update({
        fieldToUpdate: chat.messages.length - 1,
      });

      // Update local state
      if (chat.userId1 == _currentUserId) {
        chat.lastMessageIndexUser1 = chat.messages.length - 1;
      } else {
        chat.lastMessageIndexUser2 = chat.messages.length - 1;
      }
      notifyListeners();
    } catch (e) {
      print('Error marking messages as seen: $e');
    }
  }
}