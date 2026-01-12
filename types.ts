
export enum UserRole {
  CLIENT_USER = 'client_user',
  SUPPORT_AGENT = 'support_agent',
  SUPERVISOR = 'supervisor',
  ADMIN = 'admin'
}

export enum TicketStatus {
  NEW = 'New',
  ACKNOWLEDGED = 'Acknowledged',
  IN_PROGRESS = 'In Progress',
  WAITING_FOR_CLIENT = 'Waiting for Client',
  RESOLVED = 'Resolved',
  CLOSED = 'Closed'
}

export enum TicketCategory {
  PRODUCT_QUALITY = 'Product Quality Issues',
  LOGISTICS = 'Delivery / Logistics Issues',
  TECHNICAL_SUPPORT = 'Technical Support',
  COMMERCIAL = 'Commercial / Documentation Requests',
  GENERAL = 'General Queries'
}

export interface User {
  uid: string;
  email: string;
  role: UserRole;
  name: string;
  clientId: string; // "manufacturer" for internal staff
  clientName?: string;
}

export interface Ticket {
  id: string;
  clientId: string;
  clientName: string;
  userId: string;
  userName: string;
  category: TicketCategory;
  status: TicketStatus;
  subject: string;
  description: string;
  attachments: string[];
  createdAt: number;
  updatedAt: number;
  resolvedAt?: number;
  closedAt?: number;
  deletedByClient?: boolean;
  deletedByStaff?: boolean;
}

export interface Comment {
  id: string;
  ticketId: string;
  userId: string;
  userName: string;
  userRole: UserRole;
  text: string;
  timestamp: number;
  isSystemMessage?: boolean;
  clientId?: string;
}

export interface Client {
  id: string;
  name: string;
  domain: string;
}

export interface Notification {
  id: string;
  userId: string; // recipient
  ticketId: string;
  text: string;
  timestamp: number;
  read: boolean;
  type: 'COMMENT' | 'STATUS';
}
