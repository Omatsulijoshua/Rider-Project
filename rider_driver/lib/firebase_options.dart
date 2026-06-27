// lib/firebase_options.dart
// Generated manually for rider_driver Firebase project

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Web configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyD0QNwcvGDlk5Llciy_prOU6F276phb81U",
    authDomain: "rider-driver-c7796.firebaseapp.com",
    projectId: "rider-driver-c7796",
    storageBucket: "rider-driver-c7796.firebasestorage.app",
    messagingSenderId: "405273378172",
    appId: "1:405273378172:web:5d3dbb1d791549774df8f9",
    measurementId: "G-WKYTT0B4RV",
  );

  /// Android configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyD0QNwcvGDlk5Llciy_prOU6F276phb81U",
    appId: "1:405273378172:android:80b979edc746ac8d4df8f9",
    messagingSenderId: "405273378172",
    projectId: "rider-driver-c7796",
    storageBucket: "rider-driver-c7796.firebasestorage.app",
  );

  /// iOS configuration
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyD0QNwcvGDlk5Llciy_prOU6F276phb81U",
    appId: "1:405273378172:ios:86526d83764b44c24df8f9",
    messagingSenderId: "405273378172",
    projectId: "rider-driver-c7796",
    storageBucket: "rider-driver-c7796.firebasestorage.app",
    iosBundleId: "com.example.riderDriver",
  );

  /// Windows configuration
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: "AIzaSyD0QNwcvGDlk5Llciy_prOU6F276phb81U",
    appId: "1:405273378172:web:e22892edb9e935c15c626d",
    messagingSenderId: "405273378172",
    projectId: "rider-driver-c7796",
    storageBucket: "rider-driver-c7796.firebasestorage.app",
  );
}
