import 'package:flutter/material.dart';
import 'package:govconnect/components/bottombar.dart';
import 'package:govconnect/screens/communication/chat/chatPage.dart';
import 'package:provider/provider.dart';
import 'chatProvider.dart';
import 'chatWidget.dart';
import 'chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatGrid extends StatefulWidget {
  const ChatGrid({super.key});

  @override
  State<ChatGrid> createState() => _ChatGridState();
}

class _ChatGridState extends State<ChatGrid> {
  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  String? _userRole;

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .get();
      setState(() {
        _userRole = doc.data()?['role'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1621),
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Make AppBar transparent
          elevation: 0,
          leadingWidth: 60,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: IconButton(
              icon: Icon(Icons.account_balance, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/feed');
              },
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.blue,
                  size: 28,
                ),
                onPressed: () => _showAddChatOptions(context),
              ),
            ),
          ],
        ),
        body: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            if (chatProvider.isLoading || chatProvider.currentUserId == null) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Search section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chats',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search chats...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1C2F41),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                        ),
                        onChanged: (value) => chatProvider.searchChats(value),
                      ),
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 16.0),
                  child: TabBar(
                    isScrollable: true,
                    padding: EdgeInsets.zero,
                    tabAlignment: TabAlignment.start,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 16),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[400],
                    indicator: BoxDecoration(
                      color: const Color(0xFF1C2F41),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        text:
                            'All${_getCountText(chatProvider.filteredChats.where((chat) {
                              final lastIndex = chat.lastMessageIndex[chatProvider.currentUserId!] ?? -1;
                              return lastIndex < chat.messages.length - 1 && !chatProvider.isArchived(chat.id);
                            }).length)}',
                      ),
                      Tab(
                        text:
                            'Unread${_getCountText(chatProvider.filteredChats.where((chat) {
                              final lastIndex = chat.lastMessageIndex[chatProvider.currentUserId!] ?? -1;
                              return lastIndex < chat.messages.length - 1 && !chatProvider.isArchived(chat.id);
                            }).length)}',
                      ),
                      Tab(text: 'Read'),
                      Tab(
                        text:
                            'Government${_getCountText(chatProvider.filteredChats.where((chat) {
                              final otherUserName = chat.getOtherUserName(chatProvider.currentUserId!);
                              final lastIndex = chat.lastMessageIndex[chatProvider.currentUserId!] ?? -1;
                              return otherUserName.toLowerCase().endsWith('(government official)') && lastIndex < chat.messages.length - 1 && !chatProvider.isArchived(chat.id);
                            }).length)}',
                      ),
                      Tab(
                        text:
                            'Archived${_getCountText(chatProvider.filteredChats.where((chat) {
                              final lastIndex = chat.lastMessageIndex[chatProvider.currentUserId!] ?? -1;
                              return chatProvider.isArchived(chat.id) && lastIndex < chat.messages.length - 1;
                            }).length)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    // In the TabBarView children array:
                    children: [
                      // All Chats (non-archived)
                      _buildChatList(
                        chatProvider.filteredChats
                            .where((chat) => !chatProvider.isArchived(chat.id))
                            .toList(),
                        chatProvider.currentUserId!,
                      ),
                      // Unread Chats (non-archived)
                      _buildChatList(
                        chatProvider.filteredChats.where((chat) {
                          final lastIndex =
                              chat.lastMessageIndex[chatProvider
                                  .currentUserId!] ??
                              -1;
                          return lastIndex < chat.messages.length - 1 &&
                              !chatProvider.isArchived(chat.id);
                        }).toList(),
                        chatProvider.currentUserId!,
                      ),
                      // Read Chats (non-archived)
                      _buildChatList(
                        chatProvider.filteredChats.where((chat) {
                          final lastIndex =
                              chat.lastMessageIndex[chatProvider
                                  .currentUserId!] ??
                              -1;
                          return lastIndex >= chat.messages.length - 1 &&
                              !chatProvider.isArchived(chat.id);
                        }).toList(),
                        chatProvider.currentUserId!,
                      ),
                      // Government Chats (non-archived)
                      _buildChatList(
                        chatProvider.filteredChats.where((chat) {
                          final otherUserName = chat.getOtherUserName(
                            chatProvider.currentUserId!,
                          );
                          return otherUserName.toLowerCase().endsWith(
                                '(government official)',
                              ) &&
                              !chatProvider.isArchived(chat.id);
                        }).toList(),
                        chatProvider.currentUserId!,
                      ),
                      // Archived Chats (only archived)
                      _buildChatList(
                        chatProvider.filteredChats
                            .where((chat) => chatProvider.isArchived(chat.id))
                            .toList(),
                        chatProvider.currentUserId!,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1C2F41),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.of(context).pushReplacementNamed('/feed');
            }
            if (index == 2) {
              Navigator.of(context).pushReplacementNamed('/notifications');
            }
            if (index == 3) {
              Navigator.of(context).pushReplacementNamed('/profile');
            }
            if (index == 4) {
              Navigator.of(context).pushReplacementNamed('/adReview');
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              activeIcon: Icon(Icons.home, size: 28),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined, size: 28),
              activeIcon: Icon(Icons.message, size: 28),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none, size: 28),
              activeIcon: Icon(Icons.notifications, size: 28),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 28),
              activeIcon: Icon(Icons.person, size: 28),
              label: '',
            ),
            if (_userRole != null && _userRole != 'citizen')
              BottomNavigationBarItem(
                icon: Icon(Icons.ads_click_outlined, size: 28),
                activeIcon: Icon(Icons.ads_click, size: 28),
                label: '',
              ),
          ],
        ),
      ),
    );
  }

  String _getCountText(int count) {
    return count > 0 ? '  $count' : '';
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
    backgroundColor: const Color(0xFF0E1621),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
