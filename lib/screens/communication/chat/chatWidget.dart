import 'package:flutter/material.dart';
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  radius: 30,
                  child: const Icon(Icons.person, size: 30, color: Colors.grey),
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
                        color: unreadMessagesCount > 0 ? Colors.blue : Colors.grey,
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
                  builder: (context) => ChatPage(chatId: chat.id, userId: userId),
                ),
              );
            },
          ),
        ),
        Divider(
          color: Colors.grey[800],
          height: 1,
          indent: 70,
          endIndent: 16,
        ),
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