import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../models/ticket_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/enums.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        return null;
      }

      try {
        final doc = await _db.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          _currentUser = UserModel.fromMap(doc.data()!, firebaseUser.uid);
          return _currentUser;
        }
      } catch (e) {
        print("Error fetching user profile: $e");
      }
      return null;
    });
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final doc = await _db.collection('users').doc(credential.user!.uid).get();
        if (doc.exists) {
          _currentUser = UserModel.fromMap(doc.data()!, credential.user!.uid);
          return _currentUser;
        } else {
           throw Exception('User profile not found.');
        }
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
  }

  Stream<List<Ticket>> getTickets() {
    if (_currentUser == null) return Stream.value([]);

    Query query = _db.collection('tickets');

    if (_currentUser!.role == UserRole.client_user) {
      query = query.where('clientId', isEqualTo: _currentUser!.clientId)
                   .orderBy('updatedAt', descending: true);
    } else {
      query = query.orderBy('updatedAt', descending: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Ticket.fromMap(doc.data() as Map<String, dynamic>);
      }).where((t) {
         if (_currentUser!.role == UserRole.client_user) {
           return !(t.deletedByClient ?? false);
         } else {
           return !(t.deletedByStaff ?? false);
         }
      }).toList();
    });
  }

  Stream<Ticket?> getTicketById(String id) {
    if (_currentUser == null) return Stream.value(null);

    Query query = _db.collection('tickets');

    if (_currentUser!.role == UserRole.client_user) {
      query = query.where('id', isEqualTo: id)
                   .where('clientId', isEqualTo: _currentUser!.clientId)
                   .limit(1);
    } else {
      query = query.where('id', isEqualTo: id).limit(1);
    }

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return Ticket.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Stream<List<Comment>> getComments(String ticketId) {
    if (_currentUser == null) return Stream.value([]);

    Query query = _db.collection('comments');

    if (_currentUser!.role == UserRole.client_user) {
      query = query.where('ticketId', isEqualTo: ticketId)
                   .where('clientId', isEqualTo: _currentUser!.clientId)
                   .orderBy('timestamp', descending: false);
    } else {
      query = query.where('ticketId', isEqualTo: ticketId)
                   .orderBy('timestamp', descending: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Comment.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> createTicket(TicketCategory category, String subject, String description, List<String> attachments) async {
    if (_currentUser == null) return;

    final ticketId = 'T-${(1000 + Random().nextInt(9000)).floor()}';
    final now = DateTime.now().millisecondsSinceEpoch;

    final newTicket = Ticket(
      id: ticketId,
      clientId: _currentUser!.clientId,
      clientName: _currentUser!.clientName ?? 'Unknown Client',
      userId: _currentUser!.uid,
      userName: _currentUser!.name,
      category: category,
      status: TicketStatus.newTicket,
      subject: subject,
      description: description,
      attachments: attachments,
      createdAt: now,
      updatedAt: now,
    );

    await _db.collection('tickets').doc(ticketId).set(newTicket.toMap());
    await addComment(ticketId, 'Ticket created.', true);
  }

  Future<void> updateTicketStatus(String ticketId, TicketStatus newStatus) async {
     // Permission check logic mirrors TS
     if (_currentUser == null) return;

     final isManufacturer = [UserRole.support_agent, UserRole.supervisor, UserRole.admin].contains(_currentUser!.role);

     if (newStatus != TicketStatus.newTicket &&
         newStatus != TicketStatus.acknowledged &&
         !isManufacturer) {
       throw Exception("Only manufacturer support can update execution states.");
     }

     final updates = <String, dynamic>{
       'status': newStatus.value,
       'updatedAt': DateTime.now().millisecondsSinceEpoch,
     };

     if (newStatus == TicketStatus.resolved) {
       updates['resolvedAt'] = DateTime.now().millisecondsSinceEpoch;
     }
     if (newStatus == TicketStatus.closed) {
       updates['closedAt'] = DateTime.now().millisecondsSinceEpoch;
     }

     await _db.collection('tickets').doc(ticketId).update(updates);
     await addComment(ticketId, 'Status updated to ${newStatus.value}', true);
  }

  Future<void> addComment(String ticketId, String text, [bool isSystem = false, String? overrideUserId]) async {
    final user = _currentUser;
    // Basic fallback logic
    String commenterId = overrideUserId ?? (isSystem ? 'system' : user?.uid ?? 'unknown');
    String commenterName = 'System';
    UserRole commenterRole = UserRole.admin;

    if (!isSystem && user != null) {
      commenterName = user.name;
      commenterRole = user.role;
    } else if (overrideUserId == 'user_2') {
       commenterName = 'Jane Support';
       commenterRole = UserRole.support_agent;
    }

    // Need to fetch ticket for clientId if not available in context?
    // In TS we fetch ticket. Here we can do the same.
    final ticketSnapshot = await _db.collection('tickets').where('id', isEqualTo: ticketId).limit(1).get();
    if (ticketSnapshot.docs.isEmpty) return;

    final ticketData = ticketSnapshot.docs.first.data();
    final ticketClientId = ticketData['clientId'];
    final ticketUserId = ticketData['userId'];

    final newComment = Comment(
      id: 'C-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}',
      ticketId: ticketId,
      userId: commenterId,
      userName: commenterName,
      userRole: commenterRole,
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isSystemMessage: isSystem,
      clientId: ticketClientId,
    );

    await _db.collection('comments').add(newComment.toMap());

    // Notifications
    final manufacturerRoles = [UserRole.support_agent, UserRole.supervisor, UserRole.admin];
    final isManufacturerAction = isSystem || manufacturerRoles.contains(commenterRole);

    if (isManufacturerAction) {
       final notification = NotificationModel(
         id: 'N-${DateTime.now().millisecondsSinceEpoch}',
         userId: ticketUserId,
         ticketId: ticketId,
         text: isSystem ? 'System: $text' : '$commenterName messaged about $ticketId',
         timestamp: DateTime.now().millisecondsSinceEpoch,
         read: false,
         type: isSystem ? 'STATUS' : 'COMMENT',
       );
       await _db.collection('notifications').add(notification.toMap());
    }
  }

  Stream<List<NotificationModel>> getNotifications() {
    if (_currentUser == null) return Stream.value([]);

    return _db.collection('notifications')
      .where('userId', isEqualTo: _currentUser!.uid)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList());
  }

  Future<void> markNotificationsRead() async {
    if (_currentUser == null) return;

    final snapshot = await _db.collection('notifications')
        .where('userId', isEqualTo: _currentUser!.uid)
        .where('read', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<String> uploadFile(String filePath, String fileName) async {
    final file = File(filePath);
    final storageRef = _storage.ref().child('attachments/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    final snapshot = await storageRef.putFile(file);
    return await snapshot.ref.getDownloadURL();
  }
}
