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
  final int createdAt;
  final int updatedAt;
  final int? resolvedAt;
  final int? closedAt;
  final bool? deletedByClient;
  final bool? deletedByStaff;

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
    this.deletedByClient,
    this.deletedByStaff,
  });

  factory Ticket.fromMap(Map<String, dynamic> data) {
    return Ticket(
      id: data['id'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      category: TicketCategory.fromString(data['category'] ?? ''),
      status: TicketStatus.fromString(data['status'] ?? ''),
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      attachments: List<String>.from(data['attachments'] ?? []),
      createdAt: data['createdAt'] ?? 0,
      updatedAt: data['updatedAt'] ?? 0,
      resolvedAt: data['resolvedAt'],
      closedAt: data['closedAt'],
      deletedByClient: data['deletedByClient'],
      deletedByStaff: data['deletedByStaff'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'userId': userId,
      'userName': userName,
      'category': category.value,
      'status': status.value,
      'subject': subject,
      'description': description,
      'attachments': attachments,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'resolvedAt': resolvedAt,
      'closedAt': closedAt,
      'deletedByClient': deletedByClient,
      'deletedByStaff': deletedByStaff,
    };
  }
}
