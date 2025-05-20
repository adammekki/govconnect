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
        backgroundColor: const Color(0xFF1C2F41),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1C2F41),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.account_balance, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true, // Center the title
          title: const Text(
            "Chats",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28, // Increased font size
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.blue, size: 28),
              onPressed: () => _showAddChatOptions(context),
            ),
          ],
        ),
        body: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            if (chatProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add search bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search chats...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 51, 74, 117),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                    ),
                    onChanged: (value) => chatProvider.searchChats(value),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: TabBar(
                    isScrollable: true, // Makes tabs independent width
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 16),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[400],
                    indicator: BoxDecoration(
                      color: const Color.fromARGB(255, 65, 90, 119),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: const Text('All'),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: const Text('Unread'),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: const Text('Read'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      // All Chats
                      _buildChatList(
                        chatProvider.filteredChats,
                        chatProvider.currentUserId!,
                      ),
                      // Unread Chats
                      _buildChatList(
                        chatProvider.filteredChats.where((chat) {
                          final lastIndex =
                              chat.lastMessageIndex[chatProvider
                                  .currentUserId!] ??
                              -1;
                          return lastIndex < chat.messages.length - 1;
                        }).toList(),
                        chatProvider.currentUserId!,
                      ),
                      // Read Chats
                      _buildChatList(
                        chatProvider.filteredChats.where((chat) {
                          final lastIndex =
                              chat.lastMessageIndex[chatProvider
                                  .currentUserId!] ??
                              -1;
                          return lastIndex >= chat.messages.length - 1;
                        }).toList(),
                        chatProvider.currentUserId!,
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
  return chats.isEmpty
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'No chats available',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a new conversation using the + button',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
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
                final chatProvider = Provider.of<ChatProvider>(
                  context,
                  listen: false,
                );
                final chatId = await chatProvider.createRandomGovernmentChat();
                if (chatId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChatPage(
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