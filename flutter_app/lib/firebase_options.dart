// File generated manually based on web_app/.env
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // TODO: Add other platforms if needed
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCCPa6IxwtEFZeRn9KYPQESFyOD2XdcYVk',
    appId: '1:44703752154:web:cc79d8456eab705c24eae3',
    messagingSenderId: '44703752154',
    projectId: 'ticketing-system-3ad55',
    authDomain: 'ticketing-system-3ad55.firebaseapp.com',
    storageBucket: 'ticketing-system-3ad55.firebasestorage.app',
  );
}
