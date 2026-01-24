class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String ticketId;
  final DateTime timestamp;
  final bool isRead;
  final String userId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.ticketId,
    required this.timestamp,
    required this.isRead,
    required this.userId,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) {
    return NotificationModel(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      ticketId: data['ticketId'] ?? '',
      timestamp: data['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'])
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'ticketId': ticketId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'userId': userId,
    };
  }
}
