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
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 27, 38, 59),
          elevation: 0,
          title: Container(
            margin: const EdgeInsets.only(top: 8),

            child: TabBar(
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Unread'),
                Tab(text: 'Read'),
                Tab(icon: Icon(Icons.add)),
              ],
              labelColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              unselectedLabelColor: Colors.blueGrey,
              indicator: BoxDecoration(
                color: const Color.fromARGB(255,65, 90, 119),
                borderRadius: BorderRadius.circular(15),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
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
                _buildChatList(
                  chatProvider.chats,
                  chatProvider.currentUserId!,
                ),
                // Unread Chats
                _buildChatList(
                  chatProvider.chats.where((chat) {
                    final isUser1 = chat.userId1 == chatProvider.currentUserId;
                    final lastIndex = isUser1 
                        ? chat.lastMessageIndexUser1 
                        : chat.lastMessageIndexUser2;
                    return lastIndex < chat.messages.length - 1;
                  }).toList(),
                  chatProvider.currentUserId!,
                ),
                // Read Chats
                _buildChatList(
                  chatProvider.chats.where((chat) {
                    final isUser1 = chat.userId1 == chatProvider.currentUserId;
                    final lastIndex = isUser1 
                        ? chat.lastMessageIndexUser1 
                        : chat.lastMessageIndexUser2;
                    return lastIndex >= chat.messages.length - 1;
                  }).toList(),
                  chatProvider.currentUserId!,
                ),
                // Pinned Chats
                Center(
                  child: Column(
                    // Option to start chat with a goverment official
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Start a chat with a government official',
                        style: TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.blue),
                        onPressed: () {}
                      ),
                      // Option to start chat with a friend
                      const Text(
                        'Start a chat with a friend',
                        style: TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.blue),
                        onPressed: () {}
                      ),
                    ]
                  )
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