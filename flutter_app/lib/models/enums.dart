import 'package:flutter/material.dart';

enum UserRole {
  client_user,
  support_agent,
  supervisor,
  admin;

  String get value {
    switch (this) {
      case UserRole.client_user:
        return 'client_user';
      case UserRole.support_agent:
        return 'support_agent';
      case UserRole.supervisor:
        return 'supervisor';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere((e) => e.value == value,
        orElse: () => UserRole.client_user);
  }
}

enum TicketStatus {
  newTicket('New'),
  acknowledged('Acknowledge'),
  inProgress('Progress Work'),
  holdForInfo('Hold for Info'),
  resolved('Resolved'),
  closed('Closed');

  final String value;
  const TicketStatus(this.value);

  static TicketStatus fromString(String value) {
    return TicketStatus.values.firstWhere((e) => e.value == value,
        orElse: () => TicketStatus.newTicket);
  }

  Color get color {
    switch (this) {
      case TicketStatus.newTicket:
        return const Color(0xFFEFF6FF); // blue-100
      case TicketStatus.acknowledged:
        return const Color(0xFFE0E7FF); // indigo-100
      case TicketStatus.inProgress:
        return const Color(0xFFFEF9C3); // yellow-100
      case TicketStatus.holdForInfo:
        return const Color(0xFFF3E8FF); // purple-100
      case TicketStatus.resolved:
        return const Color(0xFFD1FAE5); // emerald-100
      case TicketStatus.closed:
        return const Color(0xFFF3F4F6); // gray-100
    }
  }

  Color get textColor {
    switch (this) {
      case TicketStatus.newTicket:
        return const Color(0xFF1D4ED8); // blue-700
      case TicketStatus.acknowledged:
        return const Color(0xFF4338CA); // indigo-700
      case TicketStatus.inProgress:
        return const Color(0xFFA16207); // yellow-700
      case TicketStatus.holdForInfo:
        return const Color(0xFF7E22CE); // purple-700
      case TicketStatus.resolved:
        return const Color(0xFF047857); // emerald-700
      case TicketStatus.closed:
        return const Color(0xFF4B5563); // gray-600
    }
  }
}

enum TicketCategory {
  productQuality('Product Quality Issues'),
  logistics('Delivery / Logistics Issues'),
  technicalSupport('Technical Support'),
  commercial('Commercial / Documentation Requests'),
  general('General Queries');

  final String value;
  const TicketCategory(this.value);

  static TicketCategory fromString(String value) {
    return TicketCategory.values.firstWhere((e) => e.value == value,
        orElse: () => TicketCategory.general);
  }
}
