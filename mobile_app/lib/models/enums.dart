enum UserRole {
  client_user,
  support_agent,
  supervisor,
  admin;

  String get value {
    switch (this) {
      case UserRole.client_user: return 'client_user';
      case UserRole.support_agent: return 'support_agent';
      case UserRole.supervisor: return 'supervisor';
      case UserRole.admin: return 'admin';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.client_user,
    );
  }
}

enum TicketStatus {
  newTicket,
  acknowledged,
  inProgress,
  holdForInfo,
  resolved,
  closed;

  String get value {
    switch (this) {
      case TicketStatus.newTicket: return 'New';
      case TicketStatus.acknowledged: return 'Acknowledge';
      case TicketStatus.inProgress: return 'Progress Work';
      case TicketStatus.holdForInfo: return 'Hold for Info';
      case TicketStatus.resolved: return 'Resolved';
      case TicketStatus.closed: return 'Closed';
    }
  }

  static TicketStatus fromString(String value) {
    return TicketStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TicketStatus.newTicket,
    );
  }
}

enum TicketCategory {
  productQuality,
  logistics,
  technicalSupport,
  commercial,
  general;

  String get value {
    switch (this) {
      case TicketCategory.productQuality: return 'Product Quality Issues';
      case TicketCategory.logistics: return 'Delivery / Logistics Issues';
      case TicketCategory.technicalSupport: return 'Technical Support';
      case TicketCategory.commercial: return 'Commercial / Documentation Requests';
      case TicketCategory.general: return 'General Queries';
    }
  }

  static TicketCategory fromString(String value) {
    return TicketCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TicketCategory.general,
    );
  }
}
