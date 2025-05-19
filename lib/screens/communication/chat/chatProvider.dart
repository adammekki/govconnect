import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Chat> _chats = [];
  String? _currentUserId;
  bool _isLoading = false;

  String _searchQuery = '';
  List<Chat> _filteredChats = [];
  StreamSubscription<QuerySnapshot>? _chatSubscription;
  StreamSubscription<User?>? _authSubscription;

  // Getters
  String get searchQuery => _searchQuery;
  List<Chat> get filteredChats =>
      _searchQuery.isEmpty ? _chats : _filteredChats;
  List<Chat> get chats => _chats;
  String? get currentUserId => _currentUserId;
  bool get isLoading => _isLoading;
  bool isInChat(String chatId) =>
      getChatById(chatId)?.inChat[_currentUserId!] ?? false;

  // Constructor to set up auth state listener
  ChatProvider() {
    _setupAuthListener();
  }

  // Set up authentication state listener
  void _setupAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      // Reset state when user changes
      _chats = [];

      if (user != null) {
        _currentUserId = user.uid;
        // Set up chat listener for the new user
        _setupChatListener();
      } else {
        // User signed out
        _currentUserId = null;
        // Cancel chat subscription when user signs out
        _chatSubscription?.cancel();
        _chatSubscription = null;
      }
      notifyListeners();
    });
  }

  void searchChats(String query) {
    _searchQuery = query.toLowerCase();
    if (_searchQuery.isEmpty) {
      _filteredChats = _chats;
    } else {
      _filteredChats =
          _chats.where((chat) {
            final otherUserName =
                chat.getOtherUserName(_currentUserId!).toLowerCase();
            return otherUserName.contains(_searchQuery);
          }).toList();
    }
    notifyListeners();
  }

  // Get user number
  Future<String> getUserNumber(String userId) async {
    try {
      final userDoc = await _firestore.collection('Users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        return data?['phoneNumber'] ?? "";
      }
    } catch (e) {
      print('Error getting user number: $e');
    }
    return "";
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  // Initialize the provider
  Future<void> init() async {
    _setLoading(true);
    // Auth listener will handle setting up chats
    // We don't need to manually call _loadCurrentUserId or _setupChatListener here
    _setLoading(false);
  }

  // Sign out method to properly clean up
  Future<void> signOut() async {
    await _auth.signOut();
    // Auth listener will handle the rest
  }

  void _setupChatListener() {
    // Cancel any existing subscription first
    _chatSubscription?.cancel();
    _chatSubscription = null;

    if (_currentUserId == null) return;

    // Clear existing chats
    _chats = [];
    notifyListeners();

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

              // Verify this chat belongs to current user
              if (!usersData.containsKey(_currentUserId)) {
                print('Chat ${doc.id} does not belong to current user');
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
        'time': Timestamp.now(),
        'userId': _currentUserId,
      };

      await _firestore.collection('chat').doc(chatId).update({
        'messages': FieldValue.arrayUnion([message]),
        'lastUpdate': FieldValue.serverTimestamp(),
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

  Future<void> createChat(String otherUserEmail) async {
    if (_currentUserId == null) return;

    try {
      // Normalize emails to lowercase to handle case sensitivity
      final normalizedOtherEmail = otherUserEmail.trim().toLowerCase();

      DocumentSnapshot? currentUserDoc;
      DocumentSnapshot? otherUserDoc;
      String? otherUserId;

      // Try to find current user
      final currentUserQuery =
          await _firestore.collection('Users').doc(_currentUserId!).get();

      if (currentUserQuery.exists) {
        currentUserDoc = currentUserQuery;
      }

      // Try to find other user
      final otherUserQuery =
          await _firestore
              .collection('Users')
              .where('email', isEqualTo: normalizedOtherEmail)
              .get();

      if (otherUserQuery.docs.isNotEmpty) {
        otherUserDoc = otherUserQuery.docs.first;
        otherUserId = otherUserDoc.id;
      }

      // Check if we found both users
      if (currentUserDoc == null ||
          otherUserDoc == null ||
          otherUserId == null || 
          otherUserId == _currentUserId) {
        return;
      }

      final chatId = const Uuid().v4();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>?;
      final otherUserData = otherUserDoc.data() as Map<String, dynamic>?;

      final chatData = {
        'users': {
          _currentUserId: currentUserData?['fullName'] ?? 'Unknown User',
          otherUserId: otherUserData?['fullName'] ?? 'Unknown User',
        },
        'lastMessageIndex': {_currentUserId: -1, otherUserId: -1},
        'inChat': {_currentUserId: false, otherUserId: false},
        'messages': [],
        'lastUpdate': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('chat').doc(chatId).set(chatData);
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

      // The listener will update local state automatically
    } catch (e) {
      print('Error deleting chat: $e');
    }
  }

  // Open chat method - mark user as being in the chat
  Future<void> openChat(String chatId) async {
    if (_currentUserId == null) return;

    try {
      final chat = _chats.firstWhere((chat) => chat.id == chatId);
      final currentLength = chat.messages.length;

      // Update inChat status to true and set lastMessageIndex
      await _firestore.collection('chat').doc(chatId).update({
        'inChat.${_currentUserId}': true,
        'lastMessageIndex.${_currentUserId}': currentLength - 1,
      });

      // Update local state
      chat.inChat[_currentUserId!] = true;
      chat.lastMessageIndex[_currentUserId!] = currentLength - 1;
      notifyListeners();
    } catch (e) {
      print('Error opening chat: $e');
    }
  }

  // Close chat method - mark user as no longer in the chat
  Future<void> closeChat(String chatId) async {
    if (_currentUserId == null) return;

    try {
      final chat = _chats.firstWhere((chat) => chat.id == chatId);
      final currentLength = chat.messages.length;

      // Update inChat status to false and set lastMessageIndex
      await _firestore.collection('chat').doc(chatId).update({
        'inChat.${_currentUserId}': false,
        'lastMessageIndex.${_currentUserId}': currentLength - 1,
      });

      // Update local state
      chat.inChat[_currentUserId!] = false;
      chat.lastMessageIndex[_currentUserId!] = currentLength - 1;
      notifyListeners();
    } catch (e) {
      print('Error closing chat: $e');
    }
  }

  Future<String> createRandomGovernmentChat() async {
    if (_currentUserId == null) return "";

    try {
      // Get all government users
      final govUsersQuery =
          await _firestore
              .collection('Users')
              .where('role', isEqualTo: 'government')
              .get();

      if (govUsersQuery.docs.isEmpty) {
        print('No government officials found');
        return "";
      }

      // Pick a random government user
      final random = Random();
      var randomGovUser =
          govUsersQuery.docs[random.nextInt(govUsersQuery.docs.length)];
      final govUserId = randomGovUser.id;

      // Don't create chat with self
      if (govUserId == _currentUserId && govUsersQuery.docs.length > 1) {
        while (true) {
          final newRandomGovUser =
              govUsersQuery.docs[random.nextInt(govUsersQuery.docs.length)];
          if (newRandomGovUser.id != _currentUserId) {
            randomGovUser = newRandomGovUser;
            break;
          }
        }
      } else if (govUsersQuery.docs.length == 1) {
        print('No other government officials found');
        return "";
      }

      // Get current user doc
      final currentUserDoc =
          await _firestore.collection('Users').doc(_currentUserId).get();

      // Create new chat
      final chatId = const Uuid().v4();
      final chatData = {
        'users': {
          _currentUserId:
              currentUserDoc.data()?['fullName'] + " (Citizen)" ??
              'Unknown User',
          govUserId:
              randomGovUser.data()['fullName'] + " (Government official)" ??
              'Unknown User',
        },
        'lastMessageIndex': {_currentUserId: 1, govUserId: 1},
        'inChat': {_currentUserId: false, govUserId: false},
        'messages': [
          {
            'text':
                'This is an automated message, will get back to you as soon as possible.',
            'time': Timestamp.now(),
            'userId': govUserId,
            'imageUrl': null,
          },
          {
            'text': 'How may I assist you today?',
            'time': Timestamp.now(),
            'userId': govUserId,
            'imageUrl': null,
          },
        ],
        'lastUpdate': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('chat').doc(chatId).set(chatData);
      return chatId;
    } catch (e) {
      print('Error creating random government chat: $e');
      print('Error details: ${e.toString()}');
      return "";
    }
  }
}
