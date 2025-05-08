import 'package:govconnect/screens/communication/chat/chatList.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat.dart';

class ChatProvider extends ChangeNotifier {
  List<Chat> _chats = [];
  String? _currentUserId;
  bool _isLoading = false;

  // Getters
  List<Chat> get chats => _chats;
  String? get currentUserId => _currentUserId;
  bool get isLoading => _isLoading;

  // Initialize the provider
  Future<void> init() async {
    _setLoading(true);
    await _loadCurrentUserId();
    await _loadChats();
    _setLoading(false);
  }

  // Load current user ID from SharedPreferences
  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');
    notifyListeners();
  }

  // Load chats from storage or API
  Future<void> _loadChats() async {
    // TODO: Implement chat loading logic
    // This could be from local storage or an API
    // For now, we'll just simulate loading with a delay
    await Future.delayed(const Duration(seconds: 2));
    // sort by last message time
    _chats = ChatList.getChats();
    sort();
  }

  // Send a new message
  Future<void> sendMessage(String chatId, String text, {String? imageUrl}) async {
    if (_currentUserId == null) return;

    final message = Message(
      text: text,
      imageUrl: imageUrl,
      time: DateTime.now(),
      userId: _currentUserId!,
    );


    // Find the chat by ID
    final chat = _chats.firstWhere((chat) => chat.id == chatId);

    // TODO: Implement message sending logic
    // This could include:
    // 1. Adding message to local state
    chat.messages.add(message);
    await seen(chatId); // Mark the message as seen
    // 2. Sending to an API
    // 3. Updating local storage
    sort();
    
    notifyListeners();
  }

  // Sort chats by last message time
  void sort() {
    _chats.sort((a, b) {
      final aLastMessage = a.messages.isNotEmpty ? a.messages.last.time : DateTime(0);
      final bLastMessage = b.messages.isNotEmpty ? b.messages.last.time : DateTime(0);
      return bLastMessage.compareTo(aLastMessage); // Sort in descending order
    });
  }

  // Create a new chat
  Future<void> createChat(String otherUserId) async {
    if (_currentUserId == null) return;

    final chat = Chat(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Replace with proper ID generation
      userId1: _currentUserId!,
      userId2: otherUserId,
      lastMessageIndexUser1: -1,
      lastMessageIndexUser2: -1,
      messages: [],
    );

    // TODO: Implement chat creation logic
    // This could include:
    // 1. Adding chat to local state
    // 2. Sending to an API
    // 3. Updating local storage

    notifyListeners();
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
    // TODO: Implement chat deletion logic
    _chats.removeWhere((chat) => chat.id == chatId);
    notifyListeners();
  }

  // Mark messages as read
  Future<void> seen(String chatId) async {
    if (_currentUserId == null) return;

    final chat = _chats.firstWhere((chat) => chat.id == chatId);
    if(chat.userId1 == _currentUserId) {
      chat.lastMessageIndexUser1 = chat.messages.length - 1; // Update last message index for user 1
    } else {
      chat.lastMessageIndexUser2 = chat.messages.length - 1; // Update last message index for user 2
    }

    // TODO: Implement mark as read logic
    notifyListeners();
  }
}