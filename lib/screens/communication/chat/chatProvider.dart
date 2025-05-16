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

  void _setupChatListener() {
    if (_currentUserId == null) return;

    _chatSubscription?.cancel();

    _chatSubscription = _firestore
        .collection('chat')
        .where('users.${_currentUserId}', isGreaterThan: null)
        .snapshots()
        .listen((snapshot) async {
          try {
            final List<Chat> loadedChats = [];

            for (var doc in snapshot.docs) {
              final data = doc.data();

              // Safely convert data with null checks
              final Map<String, dynamic>? usersData =
                  data['users'] as Map<String, dynamic>?;
              final Map<String, dynamic>? lastMessageIndexData =
                  data['lastMessageIndex'] as Map<String, dynamic>?;
              final Map<String, dynamic>? inChatData =
                  data['inChat'] as Map<String, dynamic>?;
              final List<dynamic>? messagesData =
                  data['messages'] as List<dynamic>?;

              if (usersData == null ||
                  lastMessageIndexData == null ||
                  inChatData == null) {
                print('Missing required data for chat ${doc.id}');
                continue;
              }

              loadedChats.add(
                Chat(
                  id: doc.id,
                  users: Map<String, String>.from(
                    usersData.map(
                      (key, value) =>
                          MapEntry(key, value?.toString() ?? 'Unknown User'),
                    ),
                  ),
                  lastMessageIndex: Map<String, int>.from(
                    lastMessageIndexData.map(
                      (key, value) => MapEntry(key, value as int? ?? -1),
                    ),
                  ),
                  inChat: Map<String, bool>.from(
                    inChatData.map(
                      (key, value) => MapEntry(key, value as bool? ?? false),
                    ),
                  ),
                  messages:
                      messagesData
                          ?.map(
                            (m) => Message(
                              text: m['text'] as String?,
                              imageUrl: m['imageUrl'] as String?,
                              time:
                                  (m['time'] as Timestamp?)?.toDate() ??
                                  DateTime.now(),
                              userId: m['userId'] as String? ?? '',
                            ),
                          )
                          .toList() ??
                      [],
                ),
              );
            }

            _chats = loadedChats;
            sort();
            notifyListeners();
          } catch (e) {
            print('Error in chat listener: $e');
            // Add more detailed error information
            print('Error details: ${e.toString()}');
          }
        });
  }

  Future<void> sendMessage(
    String chatId,
    String text, {
    String? imageUrl,
  }) async {
    if (_currentUserId == null) return;

    try {
      final message = {
        'text': text,
        'imageUrl': imageUrl,
        'time':
            Timestamp.now(), // Change this from FieldValue.serverTimestamp()
        'userId': _currentUserId,
      };

      await _firestore.collection('chat').doc(chatId).update({
        'messages': FieldValue.arrayUnion([message]),
        'lastUpdate':
            FieldValue.serverTimestamp(), // Add this to track last update
      });
    } catch (e) {
      print('Error sending message: $e');
      print('Error details: ${e.toString()}');
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

  Future<void> createChat(String otherUserId) async {
    if (_currentUserId == null) return;

    try {
      // Get user names
      final currentUserDoc =
          await _firestore.collection('Users').doc(_currentUserId).get();
      final otherUserDoc =
          await _firestore.collection('Users').doc(otherUserId).get();

      final chatId = const Uuid().v4();

      final chatData = {
        'users': {
          _currentUserId!: currentUserDoc.data()?['fullName'] ?? 'Unknown User',
          otherUserId: otherUserDoc.data()?['fullName'] ?? 'Unknown User',
        },
        'lastMessageIndex': {_currentUserId!: -1, otherUserId: -1},
        'messages': [],
      };

      await _firestore.collection('chat').doc(chatId).set(chatData);
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

  Future<void> seen(String chatId) async {
    if (_currentUserId == null) return;

    try {
      final chat = _chats.firstWhere((chat) => chat.id == chatId);
      final currentLength = chat.messages.length;
      final bool wasInChat = chat.inChat[_currentUserId!] ?? false;

      // Update both inChat status and lastMessageIndex when entering chat
      if (!wasInChat) {
        await _firestore.collection('chat').doc(chatId).update({
          'inChat.${_currentUserId}': true,
          'lastMessageIndex.${_currentUserId}': currentLength - 1,
        });

        chat.inChat[_currentUserId!] = true;
      } else {
        await _firestore.collection('chat').doc(chatId).update({
          'lastMessageIndex.${_currentUserId}': chat.messages.length - 1,
          'inChat.${_currentUserId}': false,
        });
      }
      chat.lastMessageIndex[_currentUserId!] = chat.messages.length - 1;
      notifyListeners();
    } catch (e) {
      print('Error marking messages as seen: $e');
    }
  }
}
