import 'package:flutter/material.dart';
import 'package:govconnect/screens/communication/chat/chatPage.dart';
import 'package:provider/provider.dart';
import 'chatProvider.dart';
import 'chatWidget.dart';
import 'chat.dart';

class ChatGrid extends StatelessWidget {
  const ChatGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Reduced to 3 tabs since Add is now a button
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 27, 38, 59),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button and title
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
                  // Add chat button
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue, size: 28),
                    onPressed: () => _showAddChatOptions(context),
                  ),
                ],
              ),
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
                    final lastIndex =
                        chat.lastMessageIndex[chatProvider.currentUserId!] ??
                        -1;
                    return lastIndex < chat.messages.length - 1;
                  }).toList(),
                  chatProvider.currentUserId!,
                ),
                // Read Chats
                _buildChatList(
                  chatProvider.chats.where((chat) {
                    final lastIndex =
                        chat.lastMessageIndex[chatProvider.currentUserId!] ??
                        -1;
                    return lastIndex >= chat.messages.length - 1;
                  }).toList(),
                  chatProvider.currentUserId!,
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: Container(
          color: const Color.fromARGB(255, 27, 38, 59),
          child: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.blueGrey,
            indicator: BoxDecoration(
              color: const Color.fromARGB(255, 65, 90, 119),
              borderRadius: BorderRadius.circular(15),
            ),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Unread'),
              Tab(text: 'Read'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatList(List<Chat> chats, String userId) {
    return chats.isEmpty
        ? Center(
            child: Text(
              'No chats available',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          )
        : ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ChatWidget(chat: chat, userId: userId);
            },
          );
  }
}

void _showAddChatOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color.fromARGB(255, 41, 59, 94),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Start a new chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.public, color: Colors.white),
              ),
              title: const Text(
                'Chat with government official',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                final chatId = await chatProvider.createRandomGovernmentChat();
                if (chatId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatId: chatId,
                        userId: chatProvider.currentUserId!,
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: const Text(
                'Chat with a friend',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showCreateChatDialog(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
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
            child: const Text(
              'Create Chat',
              style: TextStyle(color: Colors.blue),
            ),
            onPressed: () {
              if (userEmailController.text.isNotEmpty) {
                Provider.of<ChatProvider>(
                  context,
                  listen: false,
                ).createChat(userEmailController.text);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    },
  );
}