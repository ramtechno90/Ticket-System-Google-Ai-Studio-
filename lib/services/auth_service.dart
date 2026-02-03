import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/enums.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

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
      } else {
        // Create the user document if it doesn't exist
        // This ensures subsequent writes (like token saving) succeed
        final newUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          role: UserRole.client_user, // Default role
          name: firebaseUser.displayName ?? 'User',
          clientId: 'unknown',
        );
        await firestoreService.createUser(newUser);
        _currentUser = newUser;
      }

      // Save Token via NotificationService
      // We rely on the fact that the user document now exists (or will shortly)
      NotificationService().saveToken(firebaseUser.uid);
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
