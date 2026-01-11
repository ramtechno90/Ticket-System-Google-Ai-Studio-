
import { User, UserRole, Ticket, TicketStatus, TicketCategory, Comment, Notification } from '../types';

// Initial Mock Data
const MOCK_CLIENTS = [
  { id: 'client_apple', name: 'Apple Inc.', domain: 'apple.com' },
  { id: 'client_tesla', name: 'Tesla Motors', domain: 'tesla.com' },
];

const MOCK_USERS: User[] = [
  { 
    uid: 'user_1', 
    email: 'client@apple.com', 
    role: UserRole.CLIENT_USER, 
    name: 'John Doe', 
    clientId: 'client_apple',
    clientName: 'Apple Inc.'
  },
  { 
    uid: 'user_2', 
    email: 'agent@factory.com', 
    role: UserRole.SUPPORT_AGENT, 
    name: 'Jane Support', 
    clientId: 'manufacturer' 
  },
  { 
    uid: 'user_3', 
    email: 'admin@factory.com', 
    role: UserRole.ADMIN, 
    name: 'Admin Boss', 
    clientId: 'manufacturer' 
  },
];

const INITIAL_TICKETS: Ticket[] = [
  {
    id: 'T-1001',
    clientId: 'client_apple',
    clientName: 'Apple Inc.',
    userId: 'user_1',
    userName: 'John Doe',
    category: TicketCategory.PRODUCT_QUALITY,
    status: TicketStatus.IN_PROGRESS,
    subject: 'Batch #402 Surface Scratches',
    description: 'We received 500 units of aluminum housing today. Approximately 15% show visible hairline scratches on the top bezel.',
    attachments: [],
    createdAt: Date.now() - 86400000,
    updatedAt: Date.now() - 3600000,
  },
  {
    id: 'T-1002',
    clientId: 'client_tesla',
    clientName: 'Tesla Motors',
    userId: 'tesla_user',
    userName: 'Elon Musk',
    category: TicketCategory.LOGISTICS,
    status: TicketStatus.NEW,
    subject: 'Custom Cable Delay',
    description: 'Shipment of wiring harnesses for Model Y is 3 days overdue.',
    attachments: [],
    createdAt: Date.now() - 7200000,
    updatedAt: Date.now() - 7200000,
  }
];

const INITIAL_COMMENTS: Comment[] = [
  {
    id: 'C-1',
    ticketId: 'T-1001',
    userId: 'system',
    userName: 'System',
    userRole: UserRole.ADMIN,
    text: 'Ticket created and assigned to Quality Assurance team.',
    timestamp: Date.now() - 86300000,
    isSystemMessage: true
  },
  {
    id: 'C-2',
    ticketId: 'T-1001',
    userId: 'user_2',
    userName: 'Jane Support',
    userRole: UserRole.SUPPORT_AGENT,
    text: 'Hello John, I am looking into Batch #402. Could you please confirm if the scratches are only on the top bezel or if the side panels are affected as well?',
    timestamp: Date.now() - 80000000,
  }
];

// Initial Example Notification for user_1
const INITIAL_NOTIFICATIONS: Notification[] = [
  {
    id: 'N-INIT-1',
    userId: 'user_1',
    ticketId: 'T-1001',
    text: 'Jane Support replied to Batch #402',
    timestamp: Date.now() - 3600000,
    read: false,
    type: 'COMMENT'
  }
];

class MockFirebase {
  private tickets: Ticket[] = [...INITIAL_TICKETS];
  private comments: Comment[] = [...INITIAL_COMMENTS];
  private notifications: Notification[] = [...INITIAL_NOTIFICATIONS];
  private currentUser: User | null = null;

  async login(email: string): Promise<User | null> {
    const user = MOCK_USERS.find(u => u.email === email);
    if (user) {
      this.currentUser = user;
      localStorage.setItem('forge_user', JSON.stringify(user));
      return user;
    }
    throw new Error('User not found');
  }

  logout() {
    this.currentUser = null;
    localStorage.removeItem('forge_user');
  }

  getCurrentUser(): User | null {
    if (!this.currentUser) {
      const stored = localStorage.getItem('forge_user');
      if (stored) this.currentUser = JSON.parse(stored);
    }
    return this.currentUser;
  }

  async getTickets(): Promise<Ticket[]> {
    const user = this.getCurrentUser();
    if (!user) return [];
    if (user.role === UserRole.CLIENT_USER) {
      return this.tickets.filter(t => t.clientId === user.clientId);
    }
    return this.tickets;
  }

  async getTicketById(id: string): Promise<Ticket | undefined> {
    return this.tickets.find(t => t.id === id);
  }

  async createTicket(data: Partial<Ticket>): Promise<Ticket> {
    const user = this.getCurrentUser()!;
    const newTicket: Ticket = {
      id: `T-${Math.floor(1000 + Math.random() * 9000)}`,
      clientId: user.clientId,
      clientName: user.clientName || 'Unknown Client',
      userId: user.uid,
      userName: user.name,
      category: data.category as TicketCategory,
      status: TicketStatus.NEW,
      subject: data.subject || '',
      description: data.description || '',
      attachments: [],
      createdAt: Date.now(),
      updatedAt: Date.now(),
    };
    this.tickets = [newTicket, ...this.tickets];
    
    // Add initial system comment
    await this.addComment(newTicket.id, 'Ticket created.', true);
    
    return newTicket;
  }

  async updateTicketStatus(ticketId: string, newStatus: TicketStatus): Promise<void> {
    const ticket = this.tickets.find(t => t.id === ticketId);
    if (!ticket) return;

    // Validation rules
    const user = this.getCurrentUser()!;
    const isManufacturer = [UserRole.SUPPORT_AGENT, UserRole.SUPERVISOR, UserRole.ADMIN].includes(user.role);

    if (newStatus === TicketStatus.RESOLVED && !isManufacturer) {
      throw new Error("Only manufacturer support can resolve tickets.");
    }
    if (newStatus === TicketStatus.CLOSED && user.role !== UserRole.CLIENT_USER) {
      throw new Error("Only clients can close tickets.");
    }

    ticket.status = newStatus;
    ticket.updatedAt = Date.now();
    
    if (newStatus === TicketStatus.RESOLVED) ticket.resolvedAt = Date.now();
    if (newStatus === TicketStatus.CLOSED) ticket.closedAt = Date.now();

    // System comment
    await this.addComment(ticketId, `Status updated to ${newStatus}`, true);
  }

  async getComments(ticketId: string): Promise<Comment[]> {
    return this.comments.filter(c => c.ticketId === ticketId).sort((a, b) => a.timestamp - b.timestamp);
  }

  async addComment(ticketId: string, text: string, isSystem: boolean = false, overrideUserId?: string): Promise<Comment> {
    const user = this.getCurrentUser()!;
    const commenterId = overrideUserId || (isSystem ? 'system' : user.uid);
    
    // Find the user details for the commenter
    const commenter = MOCK_USERS.find(u => u.uid === commenterId) || (isSystem ? { name: 'System', role: UserRole.ADMIN } : user);

    const newComment: Comment = {
      id: `C-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      ticketId,
      userId: commenterId,
      userName: commenter.name,
      userRole: commenter.role as UserRole,
      text,
      timestamp: Date.now(),
      isSystemMessage: isSystem
    };
    this.comments.push(newComment);

    // Notification Logic: If manufacturer staff or system adds a comment, notify the client user
    const manufacturerRoles = [UserRole.SUPPORT_AGENT, UserRole.SUPERVISOR, UserRole.ADMIN];
    if (isSystem || manufacturerRoles.includes(commenter.role as UserRole)) {
      const ticket = this.tickets.find(t => t.id === ticketId);
      if (ticket) {
        this.notifications.push({
          id: `N-${Date.now()}`,
          userId: ticket.userId,
          ticketId: ticket.id,
          text: isSystem ? `System: ${text} for ${ticket.id}` : `${commenter.name} messaged about ${ticket.id}`,
          timestamp: Date.now(),
          read: false,
          type: isSystem ? 'STATUS' : 'COMMENT'
        });
      }
    }

    return newComment;
  }

  async simulateStaffReply(ticketId: string): Promise<void> {
    // This is for demonstration purposes
    await this.addComment(ticketId, "Demo: This is a simulated response from the manufacturing team to show the notification flow.", false, 'user_2');
  }

  async getNotifications(): Promise<Notification[]> {
    const user = this.getCurrentUser();
    if (!user) return [];
    return this.notifications
      .filter(n => n.userId === user.uid)
      .sort((a, b) => b.timestamp - a.timestamp);
  }

  async markNotificationsRead(): Promise<void> {
    const user = this.getCurrentUser();
    if (!user) return;
    this.notifications = this.notifications.map(n => 
      n.userId === user.uid ? { ...n, read: true } : n
    );
  }

  async deleteNotification(id: string): Promise<void> {
    this.notifications = this.notifications.filter(n => n.id !== id);
  }
}

export const firebase = new MockFirebase();
