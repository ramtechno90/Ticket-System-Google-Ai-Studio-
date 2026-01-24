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
      if (user.clientId.isNotEmpty) {
         query = query.where('clientId', isEqualTo: user.clientId);
      }
    } else {
      // No filter for other roles
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

  Stream<Ticket?> getTicketStream(String id) {
    return _db.collection('tickets').doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return Ticket.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // --- Comments ---
  Future<Map<String, dynamic>> getComments(String ticketId, {DocumentSnapshot? lastDoc}) async {
    const int _limit = 10;
    var query = _db
        .collection('tickets')
        .doc(ticketId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .limit(_limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    final comments = snapshot.docs
        .map((doc) => Comment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    
    final newLastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    return {
      'comments': comments,
      'lastDoc': newLastDoc,
    };
  }

  Stream<List<Comment>> getNewComments(String ticketId, DateTime after) {
    return _db
        .collection('tickets')
        .doc(ticketId)
        .collection('comments')
        .where('timestamp', isGreaterThan: after)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Comment.fromMap(doc.data() as Map<String, dynamic>, doc.id);
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
