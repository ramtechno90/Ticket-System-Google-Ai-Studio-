import 'enums.dart';

class Comment {
  final String id;
  final String ticketId;
  final String userId;
  final String userName;
  final UserRole userRole;
  final String text;
  final DateTime timestamp;
  final bool isSystemMessage;
  final String? clientId;
  final List<String> attachments;

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
    this.attachments = const [],
  });

  factory Comment.fromMap(Map<String, dynamic> data, String id) {
    return Comment(
      id: id,
      ticketId: data['ticketId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userRole: UserRole.fromString(data['userRole'] ?? ''),
      text: data['text'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      isSystemMessage: data['isSystemMessage'] ?? false,
      clientId: data['clientId'],
      attachments: List<String>.from(data['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole.value,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isSystemMessage': isSystemMessage,
      'clientId': clientId,
      'attachments': attachments,
    };
  }
}
