import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  EnvConfig._();

  static bool _loaded = false;
  static Map<String, String>? _testOverrides;

  @visibleForTesting
  static void setTestOverrides(Map<String, String>? overrides) {
    _testOverrides = overrides;
    _loaded = overrides != null;
  }

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Safe fallback in tests or environments without .env bundled
    }
  }

  static String _get(String key, String fallback) {
    if (_testOverrides != null) {
      return _testOverrides![key]?.trim() ?? fallback;
    }
    if (dotenv.isInitialized) {
      final val = dotenv.maybeGet(key)?.trim();
      if (val != null && val.isNotEmpty) return val;
    }
    return fallback;
  }

  static String get firebaseApiKey => _get(
        'FIREBASE_API_KEY',
        const String.fromEnvironment('FIREBASE_API_KEY'),
      );

  static String get firebaseAppId => _get(
        'FIREBASE_APP_ID',
        const String.fromEnvironment('FIREBASE_APP_ID'),
      );

  static String get firebaseAndroidAppId => _get(
        'FIREBASE_ANDROID_APP_ID',
        const String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
      );

  static String get firebaseIosAppId => _get(
        'FIREBASE_IOS_APP_ID',
        const String.fromEnvironment('FIREBASE_IOS_APP_ID'),
      );

  static String get firebaseMessagingSenderId => _get(
        'FIREBASE_MESSAGING_SENDER_ID',
        const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
      );

  static String get firebaseProjectId => _get(
        'FIREBASE_PROJECT_ID',
        const String.fromEnvironment('FIREBASE_PROJECT_ID'),
      );

  static String get firebaseAuthDomain => _get(
        'FIREBASE_AUTH_DOMAIN',
        const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      );

  static String get firebaseStorageBucket => _get(
        'FIREBASE_STORAGE_BUCKET',
        const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      );

  static String get firebaseMeasurementId => _get(
        'FIREBASE_MEASUREMENT_ID',
        const String.fromEnvironment('FIREBASE_MEASUREMENT_ID'),
      );

  static String get firebaseVapidKey => _get(
        'FIREBASE_VAPID_KEY',
        const String.fromEnvironment('FIREBASE_VAPID_KEY'),
      );

  static String get rcAndroidKey => _get(
        'RC_ANDROID_KEY',
        const String.fromEnvironment('RC_ANDROID_KEY'),
      );

  static String get rcIosKey => _get(
        'RC_IOS_KEY',
        const String.fromEnvironment('RC_IOS_KEY'),
      );

  static bool get hasFirebaseConfig =>
      firebaseApiKey.isNotEmpty &&
      _effectiveAppId.isNotEmpty &&
      firebaseProjectId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty;

  static String get _effectiveAppId {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (firebaseAndroidAppId.isNotEmpty) return firebaseAndroidAppId;
    }
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      if (firebaseIosAppId.isNotEmpty) return firebaseIosAppId;
    }
    return firebaseAppId;
  }

  static FirebaseOptions? toFirebaseOptions() {
    if (!hasFirebaseConfig) return null;
    final authDomain = firebaseAuthDomain;
    final storageBucket = firebaseStorageBucket;
    final measurementId = firebaseMeasurementId;

    return FirebaseOptions(
      apiKey: firebaseApiKey,
      appId: _effectiveAppId,
      messagingSenderId: firebaseMessagingSenderId,
      projectId: firebaseProjectId,
      authDomain: authDomain.isEmpty ? null : authDomain,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      measurementId: measurementId.isEmpty ? null : measurementId,
    );
  }
}
