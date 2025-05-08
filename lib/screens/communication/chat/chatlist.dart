// make temp chat list for testing

import 'chat.dart';

class ChatList {
  static List<Chat> getChats() {
    return [
      Chat(
        id: '1',
        userId1: 'Abdelrahman',
        userId2: 'Maryam',
        lastMessageIndexUser1: 1,
        lastMessageIndexUser2: 1,
        messages: [
          Message(text: 'Hello!', time: DateTime.now().subtract(const Duration(minutes: 5)),userId: 'Abdelrahman'),
          Message(text: 'Hii', time: DateTime.now().subtract(const Duration(minutes: 3)), userId: 'Maryam'),
        ],
      ),
      Chat(
        id: '2',
        userId1: 'Abdelrahman',
        userId2: 'Adam',
        lastMessageIndexUser1: 0,
        lastMessageIndexUser2: 1,
        messages: [
          Message(text: 'Hi!', time: DateTime.now().subtract(const Duration(minutes: 10)), userId: 'Abdelrahman'),
          Message(text: 'What\'s up?', time: DateTime.now().subtract(const Duration(minutes: 8)), userId: 'Adam'),
          Message(text: 'What\'s up?', time: DateTime.now().subtract(const Duration(minutes: 8)), userId: 'Adam'),
          Message(text: 'What\'s up?', time: DateTime.now().subtract(const Duration(minutes: 8)), userId: 'Adam'),
          Message(text: 'Hi!', time: DateTime.now().subtract(const Duration(minutes: 3)), userId: 'Abdelrahman'),
          Message(text: 'Hi!', time: DateTime.now().subtract(const Duration(minutes: 3)), userId: 'Abdelrahman'),
          Message(text: 'Hi!', time: DateTime.now().subtract(const Duration(minutes: 3)), userId: 'Abdelrahman'),
        ],
      ),
    ];
  }
}
