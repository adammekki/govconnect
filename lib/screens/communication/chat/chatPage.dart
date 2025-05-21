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

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // Open chat when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider.openChat(widget.chatId);
      _scrollToBottom();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _chatProvider.closeChat(widget.chatId);
    } else if (state == AppLifecycleState.resumed) {
      _chatProvider.openChat(widget.chatId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final chat = chatProvider.getChatById(widget.chatId);
        if (chat == null) {
          return const Scaffold(body: Center(child: Text('Chat not found')));
        }

        final otherUserName = chat.getOtherUserName(widget.userId);

        return PopScope(
          canPop: true,
          onPopInvoked: (bool didPop) {
            if (didPop) {
              _chatProvider.closeChat(widget.chatId);
            }
          },
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: theme.colorScheme.primary, // Use theme primary color
                ),
                onPressed: () {
                  _chatProvider.closeChat(widget.chatId);
                  Navigator.pop(context);
                },
              ),
              title: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: theme.colorScheme.onSurfaceVariant,
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
                                color: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor, // Border to match app bar bg
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUserName,
                          style: TextStyle(
                            color: theme.appBarTheme.titleTextStyle?.color ?? theme.colorScheme.onPrimaryContainer,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          (chat.inChat[chat.getOtherUserId(widget.userId)] ??
                                  false)
                              ? 'In the chat'
                              : 'Last seen recently',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.phone,
                    color: theme.colorScheme.primary, // Use theme primary color
                  ),
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
                    otherUserId: chat.getOtherUserId(
                      chatProvider.currentUserId!,
                    ),
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
                  decoration: BoxDecoration(
                    color: theme.cardColor, // Use theme card color for input area background
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
                            style: TextStyle(color: theme.colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintStyle: theme.inputDecorationTheme.hintStyle,
                              border: InputBorder.none,
                              filled: true,
                              fillColor: theme.inputDecorationTheme.fillColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: theme.inputDecorationTheme.enabledBorder?.borderSide ?? BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: theme.inputDecorationTheme.focusedBorder?.borderSide ?? BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // IconButton(
                      //   icon: const Icon(Icons.grid_view, color: Colors.blue),
                      //   onPressed: () {
                      //     _showImageUrlDialog(context, chatProvider);
                      //   },
                      // ),
                      IconButton(
                        icon: Icon(
                          Icons.send,
                          color: theme.colorScheme.primary, // Use theme primary color
                        ),
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
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Text(
            'Add Image URL',
            style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface),
          ),
          content: TextField(
            controller: urlController,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Enter image URL...',
              hintStyle: theme.inputDecorationTheme.hintStyle,
              enabledBorder: theme.inputDecorationTheme.enabledBorder ?? UnderlineInputBorder(
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: theme.inputDecorationTheme.focusedBorder ?? UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
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
              child: Text('Send', style: TextStyle(color: theme.colorScheme.primary)),
            ),
          ],
        );
      },
    ).then((_) => urlController.dispose());
  }

  @override
  void dispose() {
    _chatProvider.closeChat(widget.chatId);
    _messageController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}