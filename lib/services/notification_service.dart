import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init(String userId) async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveToken(userId, token);
      }

      // Handle token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _saveToken(userId, newToken);
      });
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    // We use arrayUnion to add the token without overwriting others (e.g. multiple devices)
    // Note: In a production app, you might want to remove old tokens.
    await _db.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<int> getUnreadCount(String userId) {
      return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<void> markAllAsRead(String userId) async {
     final batch = _db.batch();
     final query = await _db.collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

     for (var doc in query.docs) {
       batch.update(doc.reference, {'isRead': true});
     }
     await batch.commit();
  }
}
