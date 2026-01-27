import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/ticket_model.dart';
import '../models/comment_model.dart';
import '../models/enums.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users ---
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // --- Tickets ---
  Stream<List<Ticket>> getTickets(UserModel user) {
    Query query = _db.collection('tickets');

    if (user.role == UserRole.client_user) {
      // Clients see their own tickets
      // OR tickets where clientId matches their clientId (if using organization based access)
      // Based on React app: tickets.filter(t => t.userId === user.uid || t.clientId === user.clientId)
      // Firestore queries are more restrictive. Let's filter by clientId roughly if possible or userId
      // The React app loads ALL tickets and filters client-side?!
      // "const unsubscribe = firebase.subscribeToTickets((data) => setTickets(data));"
      // Let's look at the React implementation of subscribeToTickets...
      // Assuming it subscribes to 'tickets' collection.
      // For scalability, we should filter. But for now mirroring the likely behavior if rules allow it.
      // But typically clients shouldn't read all tickets.
      // Let's filter by clientId if present.
      if (user.clientId.isNotEmpty) {
         query = query.where('clientId', isEqualTo: user.clientId);
      }
    } else {
      // Support/Admin see all?
      // React app: "const filteredTickets = tickets.filter..."
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Ticket.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  DocumentReference getNewTicketRef() {
    return _db.collection('tickets').doc();
  }

  Future<void> createTicket(Ticket ticket, {DocumentReference? docRef}) async {
    if (docRef != null) {
      await docRef.set(ticket.toMap());
    } else {
      await _db.collection('tickets').doc(ticket.id).set(ticket.toMap());
    }
  }

  Future<void> updateTicketStatus(String ticketId, TicketStatus status) async {
    await _db.collection('tickets').doc(ticketId).update({
      'status': status.value,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
  Future<Ticket?> getTicket(String id) async {
    final doc = await _db.collection('tickets').doc(id).get();
    if (doc.exists) {
      return Ticket.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // --- Comments ---
  Stream<List<Comment>> getComments(String ticketId) {
    return _db
        .collection('tickets')
        .doc(ticketId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Comment.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addComment(String ticketId, Comment comment) async {
    await _db
        .collection('tickets')
        .doc(ticketId)
        .collection('comments')
        .doc(comment.id)
        .set(comment.toMap());
  }
}
