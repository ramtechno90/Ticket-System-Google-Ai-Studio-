
import { auth, db, storage } from './firebaseConfig';
import {
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  User as FirebaseUser
} from 'firebase/auth';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import {
  collection,
  getDocs,
  doc,
  getDoc,
  addDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  limit,
  onSnapshot
} from 'firebase/firestore';
import { User, Ticket, Comment, Notification, TicketStatus, UserRole, TicketCategory } from '../types';

class FirebaseService {
  private currentUser: User | null = null;
  private authStateListeners: ((user: User | null) => void)[] = [];

  constructor() {
    // Sync local storage on init if possible,
    // but onAuthStateChanged will be the source of truth.
    const stored = localStorage.getItem('forge_user');
    if (stored) {
      try {
        this.currentUser = JSON.parse(stored);
      } catch (e) {
        console.error("Failed to parse stored user", e);
      }
    }

    onAuthStateChanged(auth, async (firebaseUser: FirebaseUser | null) => {
      if (firebaseUser) {
        // Fetch user profile from Firestore
        const userDocRef = doc(db, 'users', firebaseUser.uid);
        const userSnap = await getDoc(userDocRef);

        if (userSnap.exists()) {
          const userData = userSnap.data() as Omit<User, 'uid'>;
          this.currentUser = {
            uid: firebaseUser.uid,
            ...userData
          };
          localStorage.setItem('forge_user', JSON.stringify(this.currentUser));
        } else {
          // Handle case where auth exists but no profile?
          // Log out locally to prevent zombie state
          console.warn("User authenticated but no profile found in 'users' collection. Clearing local session.");
          this.currentUser = null;
          localStorage.removeItem('forge_user');
        }
      } else {
        this.currentUser = null;
        localStorage.removeItem('forge_user');
      }

      // Notify listeners
      this.authStateListeners.forEach(listener => listener(this.currentUser));
    });
  }

  // Allow components to subscribe to auth changes if needed
  onAuthChange(listener: (user: User | null) => void) {
    this.authStateListeners.push(listener);
    // Call immediately with current state
    listener(this.currentUser);
    return () => {
      this.authStateListeners = this.authStateListeners.filter(l => l !== listener);
    };
  }

  async login(email: string, password?: string): Promise<User | null> {
    if (!password) {
      throw new Error("Password is required for Firebase Authentication");
    }
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const firebaseUser = userCredential.user;

    // Fetch detailed user profile
    const userDocRef = doc(db, 'users', firebaseUser.uid);
    const userSnap = await getDoc(userDocRef);

    if (userSnap.exists()) {
      const userData = userSnap.data() as any; // Cast to any to avoid strict type issues with matching exact User interface immediately

      const appUser: User = {
        uid: firebaseUser.uid,
        email: firebaseUser.email || email,
        role: userData.role,
        name: userData.name,
        clientId: userData.clientId,
        clientName: userData.clientName
      };

      this.currentUser = appUser;
      localStorage.setItem('forge_user', JSON.stringify(appUser));
      return appUser;
    } else {
      throw new Error('User profile not found.');
    }
  }

  async logout() {
    await signOut(auth);
    this.currentUser = null;
    localStorage.removeItem('forge_user');
  }

  getCurrentUser(): User | null {
    return this.currentUser;
  }

  async getTickets(): Promise<Ticket[]> {
    const user = this.getCurrentUser();
    if (!user) return [];

    const ticketsRef = collection(db, 'tickets');
    let q;

    if (user.role === UserRole.CLIENT_USER) {
      q = query(ticketsRef, where('clientId', '==', user.clientId), orderBy('updatedAt', 'desc'));
    } else {
      q = query(ticketsRef, orderBy('updatedAt', 'desc'));
    }

    const querySnapshot = await getDocs(q);
    const tickets: Ticket[] = [];
    querySnapshot.forEach((doc) => {
      const t = doc.data() as Ticket;
      // Soft Delete Filter
      if (user.role === UserRole.CLIENT_USER) {
        if (!t.deletedByClient) tickets.push(t);
      } else {
        if (!t.deletedByStaff) tickets.push(t);
      }
    });
    return tickets;
  }

  subscribeToTickets(callback: (tickets: Ticket[]) => void): () => void {
    const user = this.getCurrentUser();
    if (!user) {
      callback([]);
      return () => { };
    }

    const ticketsRef = collection(db, 'tickets');
    let q;

    if (user.role === UserRole.CLIENT_USER) {
      q = query(ticketsRef, where('clientId', '==', user.clientId), orderBy('updatedAt', 'desc'));
    } else {
      q = query(ticketsRef, orderBy('updatedAt', 'desc'));
    }

    return onSnapshot(q, (snapshot) => {
      const tickets: Ticket[] = [];
      snapshot.forEach((doc) => {
        const t = doc.data() as Ticket;
        // Soft Delete Filter
        if (user.role === UserRole.CLIENT_USER) {
          if (!t.deletedByClient) tickets.push(t);
        } else {
          if (!t.deletedByStaff) tickets.push(t);
        }
      });
      callback(tickets);
    }, (error) => {
      console.error("Error subscribing to tickets:", error);
    });
  }

  async getTicketById(id: string): Promise<Ticket | undefined> {
    const user = this.getCurrentUser();
    if (!user) return undefined;

    const ticketsRef = collection(db, 'tickets');
    let q;

    if (user.role === UserRole.CLIENT_USER) {
      // Must include clientId filter to satisfy Firestore security rules
      q = query(ticketsRef, where('id', '==', id), where('clientId', '==', user.clientId), limit(1));
    } else {
      q = query(ticketsRef, where('id', '==', id), limit(1));
    }

    const querySnapshot = await getDocs(q);

    if (!querySnapshot.empty) {
      return querySnapshot.docs[0].data() as Ticket;
    }
    return undefined;
  }

  async createTicket(data: Partial<Ticket>): Promise<Ticket> {
    const user = this.getCurrentUser()!;
    const ticketId = `T-${Math.floor(1000 + Math.random() * 9000)}`;

    const newTicket: Ticket = {
      id: ticketId,
      clientId: user.clientId,
      clientName: user.clientName || 'Unknown Client',
      userId: user.uid,
      userName: user.name,
      category: data.category as TicketCategory,
      status: TicketStatus.NEW,
      subject: data.subject || '',
      description: data.description || '',
      attachments: data.attachments || [],
      createdAt: Date.now(),
      updatedAt: Date.now(),
    };

    // Use ticketId as doc ID or let Firestore generate one?
    // Using setDoc with specific ID to match the logical ID, which helps with security rules using get().
    await setDoc(doc(db, 'tickets', ticketId), newTicket);

    // Add initial system comment
    await this.addComment(newTicket.id, 'Ticket created.', true);

    return newTicket;
  }

  async updateTicketStatus(ticketId: string, newStatus: TicketStatus): Promise<void> {
    // First find the doc reference
    const ticketsRef = collection(db, 'tickets');
    const q = query(ticketsRef, where('id', '==', ticketId), limit(1));
    const querySnapshot = await getDocs(q);

    if (querySnapshot.empty) return;

    const docRef = querySnapshot.docs[0].ref;
    const ticket = querySnapshot.docs[0].data() as Ticket;

    // Validation rules
    const user = this.getCurrentUser()!;
    const isManufacturer = [UserRole.SUPPORT_AGENT, UserRole.SUPERVISOR, UserRole.ADMIN].includes(user.role);

    if (newStatus === TicketStatus.RESOLVED && !isManufacturer) {
      throw new Error("Only manufacturer support can resolve tickets.");
    }
    if (newStatus === TicketStatus.CLOSED && user.role !== UserRole.CLIENT_USER) {
      throw new Error("Only clients can close tickets.");
    }

    const updates: any = {
      status: newStatus,
      updatedAt: Date.now()
    };

    if (newStatus === TicketStatus.RESOLVED) updates.resolvedAt = Date.now();
    if (newStatus === TicketStatus.CLOSED) updates.closedAt = Date.now();

    await updateDoc(docRef, updates);

    // System comment
    await this.addComment(ticketId, `Status updated to ${newStatus}`, true);
  }

  async deleteTicket(ticketId: string): Promise<void> {
    const user = this.getCurrentUser();
    if (!user) return;

    // We only perform a soft delete based on user role
    const updates: any = {};
    if (user.role === UserRole.CLIENT_USER) {
      updates.deletedByClient = true;
    } else {
      updates.deletedByStaff = true;
    }

    // Need to find the doc first because we store logical ID in 'id' field, but verify if doc ID matches
    // Based on createTicket, we use setDoc(doc(db, 'tickets', ticketId), ...) so doc ID == ticketId
    const docRef = doc(db, 'tickets', ticketId);
    await updateDoc(docRef, updates);
  }

  async getComments(ticketId: string): Promise<Comment[]> {
    const user = this.getCurrentUser();
    // Assuming comments are in a top-level collection 'comments' for now, linked by ticketId
    const commentsRef = collection(db, 'comments');
    let q;

    // For Client Users, we must filter by clientId if available to satisfy security rules,
    // OR we rely on the rule checking the ticket via get().
    // Since we updated rules to allow check by clientId, adding the filter is safer and more efficient.
    if (user && user.role === UserRole.CLIENT_USER) {
      q = query(commentsRef, where('ticketId', '==', ticketId), where('clientId', '==', user.clientId), orderBy('timestamp', 'asc'));
    } else {
      q = query(commentsRef, where('ticketId', '==', ticketId), orderBy('timestamp', 'asc'));
    }

    const querySnapshot = await getDocs(q);
    const comments: Comment[] = [];
    querySnapshot.forEach((doc) => {
      comments.push(doc.data() as Comment);
    });
    return comments;
  }

  async addComment(ticketId: string, text: string, isSystem: boolean = false, overrideUserId?: string): Promise<Comment> {
    const user = this.getCurrentUser();
    // System messages might be triggered when user is not fully loaded or by system actions?
    // In this app, system actions are triggered by user actions.
    // Fallback for system user if needed.

    const commenterId = overrideUserId || (isSystem ? 'system' : user?.uid);
    let commenterName = 'System';
    let commenterRole = UserRole.ADMIN;

    if (!isSystem && user) {
      commenterName = user.name;
      commenterRole = user.role;
    } else if (overrideUserId) {
      // Fetch overridden user details if needed, but for simplicity assuming we don't need deep fetch here
      // In original mock, it searched MOCK_USERS.
      // We will just use placeholders or need a user cache.
      // For simulated staff reply, we need a name.
      if (overrideUserId === 'user_2') {
        commenterName = 'Jane Support';
        commenterRole = UserRole.SUPPORT_AGENT;
      }
    }

    // Fetch the ticket to get clientId and owner info for notifications
    const ticket = await this.getTicketById(ticketId);

    const newComment: Comment = {
      id: `C-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      ticketId,
      userId: commenterId || 'unknown',
      userName: commenterName,
      userRole: commenterRole,
      text,
      timestamp: Date.now(),
      isSystemMessage: isSystem,
      clientId: ticket?.clientId // Denormalize clientId for security rules
    };

    const commentsRef = collection(db, 'comments');
    await addDoc(commentsRef, newComment);

    // Notification Logic
    if (ticket) {
      const manufacturerRoles = [UserRole.SUPPORT_AGENT, UserRole.SUPERVISOR, UserRole.ADMIN];
      // If current user is manufacturer or system, notify the client user
      // OR if it's an override (simulated staff)

      const isManufacturerAction = isSystem || manufacturerRoles.includes(commenterRole);

      if (isManufacturerAction) {
        const notificationsRef = collection(db, 'notifications');
        const notification: Notification = {
          id: `N-${Date.now()}`,
          userId: ticket.userId, // Notify ticket owner
          ticketId: ticket.id,
          text: isSystem ? `System: ${text} for ${ticket.id}` : `${commenterName} messaged about ${ticket.id}`,
          timestamp: Date.now(),
          read: false,
          type: isSystem ? 'STATUS' : 'COMMENT'
        };
        await addDoc(notificationsRef, notification);
      }
    }

    return newComment;
  }

  async simulateStaffReply(ticketId: string): Promise<void> {
    await this.addComment(ticketId, "Demo: This is a simulated response from the manufacturing team to show the notification flow.", false, 'user_2');
  }

  async getNotifications(): Promise<Notification[]> {
    const user = this.getCurrentUser();
    if (!user) return [];

    const notificationsRef = collection(db, 'notifications');
    const q = query(notificationsRef, where('userId', '==', user.uid), orderBy('timestamp', 'desc'));

    const querySnapshot = await getDocs(q);
    const notifications: Notification[] = [];
    querySnapshot.forEach((doc) => {
      notifications.push(doc.data() as Notification);
    });
    return notifications;
  }

  async markNotificationsRead(): Promise<void> {
    const user = this.getCurrentUser();
    if (!user) return;

    const notificationsRef = collection(db, 'notifications');
    const q = query(notificationsRef, where('userId', '==', user.uid), where('read', '==', false));

    const querySnapshot = await getDocs(q);

    const batchPromises = querySnapshot.docs.map(docSnap =>
      updateDoc(docSnap.ref, { read: true })
    );

    await Promise.all(batchPromises);
  }

  async deleteNotification(id: string): Promise<void> {
    const user = this.getCurrentUser();
    if (!user) {
      console.error("No user logged in, cannot delete notification");
      return;
    }

    try {
      console.log(`Attempting to delete notification with ID field: ${id}`);

      const notificationsRef = collection(db, 'notifications');
      // Fix: Query must filter by userId to match Firestore Security Rule
      // Rule: allow read: if resource.data.userId == request.auth.uid
      const q = query(
        notificationsRef,
        where('id', '==', id),
        where('userId', '==', user.uid)
      );

      const querySnapshot = await getDocs(q);

      if (querySnapshot.empty) {
        console.log(`No notification found (id: ${id}, userId: ${user.uid})`);
        return;
      }

      const deletePromises = querySnapshot.docs.map(docSnap => {
        return deleteDoc(docSnap.ref);
      });
      await Promise.all(deletePromises);
    } catch (err) {
      console.error("Error in deleteNotification service:", err);
      throw err;
    }
  }
  async uploadFile(file: File): Promise<string> {
    const storageRef = ref(storage, `attachments/${Date.now()}_${file.name}`);
    const snapshot = await uploadBytes(storageRef, file);
    return await getDownloadURL(snapshot.ref);
  }
}

export const firebase = new FirebaseService();
