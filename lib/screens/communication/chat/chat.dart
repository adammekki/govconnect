class Chat {
  String id;
  String userId1;
  String userId2;
  int lastMessageIndexUser1;
  int lastMessageIndexUser2;
  String userName1;
  String userName2;
  List<Message> messages;

  Chat({
    required this.id, 
    required this.userId1, 
    required this.userId2, 
    required this.messages, 
    required this.lastMessageIndexUser1, 
    required this.lastMessageIndexUser2,
    required this.userName1, 
    required this.userName2, 
    });
}

class Message {
  String? text;
  String? imageUrl;
  DateTime time;
  String userId; 

  Message({this.text, required this.time, required this.userId, this.imageUrl});
}