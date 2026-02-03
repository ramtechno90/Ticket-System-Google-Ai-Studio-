import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added
import 'package:firebase_messaging/firebase_messaging.dart'; // Added
import '../models/user_model.dart';
import '../models/enums.dart';
import 'firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _currentUser;
  bool _isLoading = true;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _isLoading = true;
    notifyListeners();

    if (firebaseUser == null) {
      _currentUser = null;
    } else {
      final firestoreService = FirestoreService();
      final userProfile = await firestoreService.getUser(firebaseUser.uid);
      
      if (userProfile != null) {
        _currentUser = userProfile;
        _saveTokenToDatabase(firebaseUser.uid); // Save FCM token
      } else {
        // Fallback if no profile found (or create one?)
        _currentUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email!,
          role: UserRole.client_user,
          name: firebaseUser.displayName ?? 'User',
          clientId: 'unknown',
        );
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveTokenToDatabase(String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final tokensRef = FirebaseFirestore.instance.collection('users').doc(userId);
        await tokensRef.update({
          'fcmTokens': FieldValue.arrayUnion([fcmToken]),
        });
      }
    } catch (e) {
      // Could not save token
      print("Error saving FCM token: $e");
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    // Consider removing the token on sign out if appropriate
    await _auth.signOut();
  }
}
