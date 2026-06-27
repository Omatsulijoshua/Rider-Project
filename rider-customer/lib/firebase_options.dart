// firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  // Android configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCj81zSUCzBF1wjIct0gUSt4mIjHa9sMGs',
    appId: '1:514833924165:android:7b9d1831a3a71882ad232c',
    messagingSenderId: '514833924165',
    projectId: 'raiderapp-10f77',
    storageBucket: 'raiderapp-10f77.firebasestorage.app',
  );

  // Web configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDrOG052jYSyjPtjoc0z0e6yQJcqLH0Wyg',
    authDomain: 'raiderapp-10f77.firebaseapp.com',
    projectId: 'raiderapp-10f77',
    storageBucket: 'raiderapp-10f77.firebasestorage.app',
    messagingSenderId: '514833924165',
    appId: '1:514833924165:web:336d80ec882b0e08ad232c',
    measurementId: 'G-KXZZF34S9R', // optional
  );
}
