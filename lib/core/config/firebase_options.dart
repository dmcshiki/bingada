import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase options from `--dart-define` values. Nothing is committed:
/// build with `--dart-define-from-file=config/firebase.json`
/// (see `config/firebase.json`).
abstract final class DefaultFirebaseOptions {
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _bucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const _databaseUrl = String.fromEnvironment('FIREBASE_DATABASE_URL');

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    databaseURL: _databaseUrl,
    storageBucket: _bucket,
    measurementId: String.fromEnvironment('FIREBASE_MEASUREMENT_ID'),
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    databaseURL: _databaseUrl,
    storageBucket: _bucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_IOS_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    databaseURL: _databaseUrl,
    storageBucket: _bucket,
    iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
  );

  /// Options for the platform the app is running on.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => web,
    };
  }

  static bool get isConfigured =>
      currentPlatform.apiKey.isNotEmpty && currentPlatform.projectId.isNotEmpty;
}
