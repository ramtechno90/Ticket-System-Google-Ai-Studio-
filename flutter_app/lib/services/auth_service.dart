import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/enums.dart'; // Added
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
