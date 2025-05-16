import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat.dart';
import 'chatProvider.dart';
import 'messagesGrid.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String userId;

  const ChatPage({Key? key, required this.chatId, required this.userId})
    : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Schedule the seen call for after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).seen(widget.chatId);
      _scrollToBottom();
    });
    Provider.of<ChatProvider>(context, listen: false).seen(widget.chatId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final chat = chatProvider.getChatById(widget.chatId);
        if (chat == null) {
          return const Scaffold(body: Center(child: Text('Chat not found')));
        }

        final otherUserName = chat.getOtherUserName(widget.userId);

        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 27, 38, 59),
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 51, 74, 117),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.blue),
              onPressed: () {
                Provider.of<ChatProvider>(
                  context,
                  listen: false,
                ).seen(widget.chatId);
                Navigator.pop(context);
              },
            ),
            title: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey,
                      ),
                    ),
                    // Online indicator
                    if (chat.inChat[chat.getOtherUserId(widget.userId)] ??
                        false)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color.fromARGB(255, 51, 74, 117),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUserName,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      (chat.inChat[chat.getOtherUserId(widget.userId)] ??
                        false)
                          ? 'In the chat'
                          : 'Last seen recently',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.phone, color: Colors.blue),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: MessagesGrid(
                  messages: chat.messages,
                  currentUserId: chatProvider.currentUserId!,
                  otherUserId: chat.getOtherUserId(chatProvider.currentUserId!),
                  lastMessageIndices: chat.lastMessageIndex,
                  scrollController: _scrollController,
                  inChat: chat.inChat,
                ),
              ),
              Container(
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 8,
                  bottom: 8, // Added bottom padding
                ),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 51, 74, 117),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                        ), // Added left padding for text
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Color.fromARGB(
                              255,
                              41,
                              59,
                              94,
                            ), // darker shade for text input
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.grid_view, color: Colors.blue),
                      onPressed: () {
                        _showImageUrlDialog(context, chatProvider);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () {
                        if (_messageController.text.isNotEmpty) {
                          chatProvider.sendMessage(
                            widget.chatId,
                            _messageController.text,
                          );
                          _messageController.clear();

                          // Ensure scroll happens after the message is added and layout is complete
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          });
                        }
                      },
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showImageUrlDialog(BuildContext context, ChatProvider chatProvider) {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 51, 74, 117),
          title: const Text(
            'Add Image URL',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: urlController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter image URL...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (urlController.text.isNotEmpty) {
                  chatProvider.sendMessage(
                    widget.chatId,
                    '', // Empty text for image-only messages
                    imageUrl: urlController.text,
                  );
                  Navigator.pop(context);
                  _scrollToBottom();
                }
              },
              child: const Text('Send', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    ).then((_) => urlController.dispose());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
