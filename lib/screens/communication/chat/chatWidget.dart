import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chatProvider.dart';
import 'chat.dart';
import 'chatPage.dart';

class ChatWidget extends StatelessWidget {
  final Chat chat;
  final String userId;

  const ChatWidget({super.key, required this.chat, required this.userId});

  @override
  Widget build(BuildContext context) {
    final lastMessage = chat.messages.isNotEmpty ? chat.messages.last : null;
    final int unreadMessagesCount = _getUnreadCount(chat);
    final otherUserName = chat.getOtherUserName(userId);

    return Column(
      children: [
        Dismissible(
          key: Key(chat.id),
          direction: DismissDirection.startToEnd, // Only left to right swipe
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20.0),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            // Show confirmation dialog
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: const Color.fromARGB(255, 41, 59, 94),
                  title: const Text(
                    'Delete Chat',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    'Are you sure you want to delete chat with $otherUserName?',
                    style: const TextStyle(color: Colors.white),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            // Delete the chat
            Provider.of<ChatProvider>(
              context,
              listen: false,
            ).deleteChat(chat.id);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    radius: 30,
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    otherUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    lastMessage != null ? _formatTime(lastMessage.time) : '',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        lastMessage == null
                            ? 'No messages sent'
                            : '${lastMessage.userId == userId ? 'You' : chat.users[lastMessage.userId]}: ${lastMessage.text ?? "Sent an image"}',
                        style: TextStyle(
                          color:
                              unreadMessagesCount > 0
                                  ? Colors.blue
                                  : Colors.grey,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    if (unreadMessagesCount > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadMessagesCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChatPage(chatId: chat.id, userId: userId),
                  ),
                );
              },
            ),
          ),
        ),
        Divider(color: Colors.grey[800], height: 1, indent: 70, endIndent: 16),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  int _getUnreadCount(Chat chat) {
    if (chat.messages.isEmpty) return 0;

    final lastIndex = chat.lastMessageIndex[userId] ?? -1;
    final unreadCount = chat.messages.length - lastIndex - 1;
    return unreadCount > 0 ? unreadCount : 0;
  }
}