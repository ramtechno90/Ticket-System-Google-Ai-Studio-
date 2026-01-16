class NotificationModel {
  final String id;
  final String userId;
  final String ticketId;
  final String text;
  final int timestamp;
  final bool read;
  final String type; // 'COMMENT' or 'STATUS'

  NotificationModel({
    required this.id,
    required this.userId,
    required this.ticketId,
    required this.text,
    required this.timestamp,
    required this.read,
    required this.type,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data) {
    return NotificationModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      ticketId: data['ticketId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? 0,
      read: data['read'] ?? false,
      type: data['type'] ?? 'COMMENT',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'ticketId': ticketId,
      'text': text,
      'timestamp': timestamp,
      'read': read,
      'type': type,
    };
  }
}
