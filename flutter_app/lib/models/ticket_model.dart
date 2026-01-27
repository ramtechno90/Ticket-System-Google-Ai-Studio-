import 'enums.dart';

class Ticket {
  final String id;
  final String clientId;
  final String clientName;
  final String userId;
  final String userName;
  final TicketCategory category;
  final TicketStatus status;
  final String subject;
  final String description;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final bool deletedByClient;
  final bool deletedByStaff;

  Ticket({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.userId,
    required this.userName,
    required this.category,
    required this.status,
    required this.subject,
    required this.description,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.closedAt,
    this.deletedByClient = false,
    this.deletedByStaff = false,
  });

  factory Ticket.fromMap(Map<String, dynamic> data, String id) {
    return Ticket(
      id: id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      category: TicketCategory.fromString(data['category'] ?? ''),
      status: TicketStatus.fromString(data['status'] ?? ''),
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      attachments: List<String>.from(data['attachments'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] ?? 0),
      resolvedAt: data['resolvedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['resolvedAt'])
          : null,
      closedAt: data['closedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['closedAt'])
          : null,
      deletedByClient: data['deletedByClient'] ?? false,
      deletedByStaff: data['deletedByStaff'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'userId': userId,
      'userName': userName,
      'category': category.value,
      'status': status.value,
      'subject': subject,
      'description': description,
      'attachments': attachments,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'resolvedAt': resolvedAt?.millisecondsSinceEpoch,
      'closedAt': closedAt?.millisecondsSinceEpoch,
      'deletedByClient': deletedByClient,
      'deletedByStaff': deletedByStaff,
    };
  }
}
