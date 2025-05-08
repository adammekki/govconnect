import 'package:flutter/material.dart';
import 'chat.dart';
import 'chatPage.dart';

class ChatWidget extends StatelessWidget {
  final Chat chat;
  final String userId;


  const ChatWidget({
    super.key,
    required this.chat,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessage = chat.messages.isNotEmpty ? chat.messages.last : null;
    final int unreadMessagesCount = _getUnreadCount(chat);
    final userName1 = chat.userId1 == userId ? chat.userName1 : chat.userName2;
    final userName2 = chat.userId1 == userId ? chat.userName2 : chat.userName1;

    return Padding(
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
              userId == chat.userId1 ? userName2 : userName1,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              lastMessage != null ? _formatTime(lastMessage.time) : '',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  (lastMessage == null ? 'No messages sent' : '${userId == lastMessage.userId ? 'You': lastMessage.userId == chat.userId1 ? userName1 : userName2}: ${lastMessage.text}'),
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
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => ChatPage(chatId: chat.id, userId: userId),
          ));
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  int _getUnreadCount(Chat chat) {
    final isUser1 = chat.userId1 == userId;
    final lastIndex = isUser1 
        ? chat.lastMessageIndexUser1 
        : chat.lastMessageIndexUser2;
    
    if (chat.messages.isEmpty) return 0;
    
    final unreadCount = chat.messages.length - lastIndex - 1;
    return unreadCount > 0 ? unreadCount : 0;
  }
}