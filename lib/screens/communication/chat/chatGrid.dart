import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chatProvider.dart';
import 'chatWidget.dart';
import 'chat.dart';

class ChatGrid extends StatelessWidget {
  const ChatGrid({super.key});

  @override
  Widget build(BuildContext context) {
  return DefaultTabController(
    length: 4,
    child: Scaffold(
      backgroundColor: const Color.fromARGB(255, 27, 38, 59),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,  // Align children to the left
            children: [
              // Top row with back button and title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Chats',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tabs aligned to the left
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: TabBar(
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Unread'),
                    Tab(text: 'Read'),
                    Tab(icon: Icon(Icons.add)),
                  ],
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.blueGrey,
                  indicator: BoxDecoration(
                    color: const Color.fromARGB(255, 65, 90, 119),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  dividerColor: Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [
              // All Chats
              _buildChatList(chatProvider.chats, chatProvider.currentUserId!),
              // Unread Chats
              _buildChatList(
                chatProvider.chats.where((chat) {
                  final lastIndex = chat.lastMessageIndex[chatProvider.currentUserId!] ?? -1;
                  return lastIndex < chat.messages.length - 1;
                }).toList(),
                chatProvider.currentUserId!,
              ),
              // Read Chats
              _buildChatList(
                chatProvider.chats.where((chat) {
                  final lastIndex = chat.lastMessageIndex[chatProvider.currentUserId!] ?? -1;
                  return lastIndex >= chat.messages.length - 1;
                }).toList(),
                chatProvider.currentUserId!,
              ),
              // Add Chat Tab
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Start a chat with a government official',
                      style: TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.blue),
                      onPressed: () {},
                    ),
                    const Text(
                      'Start a chat with a friend',
                      style: TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.blue),
                      onPressed: () => _showCreateChatDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}


  Widget _buildChatList(List<Chat> chats, String userId) {
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatWidget(chat: chat, userId: userId);
      },
    );
  }
}

void _showCreateChatDialog(BuildContext context) {
  final TextEditingController userEmailController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color.fromARGB(255, 41, 59, 94),
        title: const Text(
          'Start New Chat',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: userEmailController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter friend\'s Email',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color.fromARGB(255, 27, 38, 59),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Create Chat', style: TextStyle(color: Colors.blue)),
            onPressed: () {
              if (userEmailController.text.isNotEmpty) {
                Provider.of<ChatProvider>(context, listen: false)
                    .createChat(userEmailController.text);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    },
  );
}