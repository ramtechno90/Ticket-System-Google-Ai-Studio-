import 'enums.dart';

class Comment {
  final String id;
  final String ticketId;
  final String userId;
  final String userName;
  final UserRole userRole;
  final String text;
  final int timestamp;
  final bool isSystemMessage;
  final String? clientId;

  Comment({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.text,
    required this.timestamp,
    this.isSystemMessage = false,
    this.clientId,
  });

  factory Comment.fromMap(Map<String, dynamic> data) {
    return Comment(
      id: data['id'] ?? '',
      ticketId: data['ticketId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userRole: UserRole.fromString(data['userRole'] ?? ''),
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? 0,
      isSystemMessage: data['isSystemMessage'] ?? false,
      clientId: data['clientId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole.value,
      'text': text,
      'timestamp': timestamp,
      'isSystemMessage': isSystemMessage,
      'clientId': clientId,
    };
  }
}
