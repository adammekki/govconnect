class Chat {
  String id;
  Map<String, String> users; // userId1 and userId2 as keys, values are user names
  Map<String, int> lastMessageIndex; // lastMessageIndex for each user, key is userId and value is index
  Map<String, bool> inChat; // inChat status for each user
  List<Message> messages;

  Chat({
    required this.id,
    required this.users,
    required this.messages,
    required this.lastMessageIndex,
    required this.inChat,
  });

  // Helper method to get other user's ID
  String getOtherUserId(String currentUserId) {
    return users.keys.firstWhere((id) => id != currentUserId);
  }

  // Helper method to get other user's name
  String getOtherUserName(String currentUserId) {
    return users[getOtherUserId(currentUserId)] ?? 'Unknown User';
  }
}

class Message {
  String? text;
  String? imageUrl;
  DateTime time;
  String userId;

  Message({this.text, required this.time, required this.userId, this.imageUrl});
}
