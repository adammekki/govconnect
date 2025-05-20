import 'package:flutter/material.dart';
import 'chat.dart';

class MessagesGrid extends StatelessWidget {
  final List<Message> messages;
  final String currentUserId;
  final String otherUserId;
  final Map<String, int> lastMessageIndices;
  final Map<String, bool> inChat;
  final ScrollController scrollController;

  const MessagesGrid({
    Key? key,
    required this.messages,
    required this.currentUserId,
    required this.otherUserId,
    required this.lastMessageIndices,
    required this.scrollController,
    required this.inChat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      reverse: false,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final message = messages[index];
        final bool isMyMessage = message.userId == currentUserId;
        final bool isNextMessageSameUser =
            index < messages.length - 1 &&
            messages[index + 1].userId == message.userId;
        final bool isPreviousMessageSameUser =
            index > 0 && messages[index - 1].userId == message.userId;

        final bool isSeen =
            (isMyMessage && (inChat[otherUserId] ?? false)) || ((lastMessageIndices[otherUserId] ?? -1) >= index);

        return Padding(
          padding: EdgeInsets.only(
            bottom: isNextMessageSameUser ? 2 : 8,
            top: isPreviousMessageSameUser ? 2 : 8,
          ),
          child: Row(
            mainAxisAlignment:
                isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      isMyMessage
                          // change colors to hex
                          ? const Color.fromARGB(255, 51, 74, 117)
                          : Colors.grey[800],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(
                      isMyMessage || !isPreviousMessageSameUser ? 16 : 4,
                    ),
                    topRight: Radius.circular(
                      !isMyMessage || !isPreviousMessageSameUser ? 16 : 4,
                    ),
                    bottomLeft: Radius.circular(isMyMessage ? 16 : 4),
                    bottomRight: Radius.circular(!isMyMessage ? 16 : 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      isMyMessage
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                  children: [
                    if (message.text != null && message.text!.isNotEmpty)
                      Text(
                        message.text!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )
                    else if (message.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          message.imageUrl!,
                          fit: BoxFit.cover,
                          width: 200, // You can adjust this
                          height: 200, // You can adjust this
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.error,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.time),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        if (isMyMessage) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all,
                            size: 16,
                            color:
                                isSeen
                                    ? Colors.blue
                                    : Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
