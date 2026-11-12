import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crash_reporter.dart';
import 'env_config.dart';
import 'firebase_sync_service.dart';
import 'notification_service.dart';

/// Top-level background handler required by Firebase Messaging on Android/iOS.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await EnvConfig.load();
    final options = EnvConfig.toFirebaseOptions();
    if (options != null && Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options);
    }
  } catch (e, st) {
    CrashReporter.recordNonFatal(e, st);
  }
}

final RegExp _safeIdPattern = RegExp(r'^[a-zA-Z0-9_-]{1,128}$');

/// Resolves an allowlisted deep-link route from an FCM data payload.
String? resolveFcmRoute(Map<String, dynamic> data) {
  final itemId = data['itemId']?.toString().trim();
  if (itemId != null && _safeIdPattern.hasMatch(itemId)) {
    final screen = data['screen']?.toString().trim();
    if (screen == 'broke_help') {
      return '/broke-help/$itemId';
    }
    return '/item/$itemId';
  }

  final route = data['route']?.toString().trim();
  if (route == null || route.isEmpty) return null;

  const allowedStaticRoutes = {
    '/items',
    '/expiring',
    '/settings',
    '/paywall',
    '/auth',
  };
  if (allowedStaticRoutes.contains(route)) {
    return route;
  }

  if (route.startsWith('/item/')) {
    final id = route.substring('/item/'.length);
    if (_safeIdPattern.hasMatch(id)) return route;
  }
  if (route.startsWith('/broke-help/')) {
    final id = route.substring('/broke-help/'.length);
    if (_safeIdPattern.hasMatch(id)) return route;
  }

  return null;
}

/// Computes a positive 31-bit deterministic notification ID from a message ID.
int deterministicPushId(String? messageId) {
  if (messageId == null || messageId.isEmpty) {
    return DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  }
  var hash = 0x811c9dc5;
  for (final code in messageId.codeUnits) {
    hash ^= code;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}

class FcmStatus {
  const FcmStatus({
    this.isSupported = false,
    this.isInitialized = false,
    this.permissionStatus = AuthorizationStatus.notDetermined,
    this.hasToken = false,
    this.lastError,
  });

  final bool isSupported;
  final bool isInitialized;
  final AuthorizationStatus permissionStatus;
  final bool hasToken;
  final String? lastError;

  bool get isAuthorized =>
      permissionStatus == AuthorizationStatus.authorized ||
      permissionStatus == AuthorizationStatus.provisional;

  FcmStatus copyWith({
    bool? isSupported,
    bool? isInitialized,
    AuthorizationStatus? permissionStatus,
    bool? hasToken,
    String? lastError,
    bool clearError = false,
  }) {
    return FcmStatus(
      isSupported: isSupported ?? this.isSupported,
      isInitialized: isInitialized ?? this.isInitialized,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      hasToken: hasToken ?? this.hasToken,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class ForegroundPushBanner {
  const ForegroundPushBanner({
    required this.title,
    required this.body,
    this.route,
  });

  final String title;
  final String body;
  final String? route;
}

class FcmService {
  FcmService(this._notifications, this._sync);

  final NotificationService _notifications;
  final FirebaseSyncService _sync;

  final ValueNotifier<FcmStatus> statusNotifier =
      ValueNotifier(const FcmStatus());

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;
  StreamSubscription<String>? _tokenRefreshSub;
  VoidCallback? _syncListener;
  String? _currentToken;
  String? _lastSyncedUid;
  bool _initialized = false;
  void Function(String route)? _onNavigate;
  void Function(ForegroundPushBanner banner)? _onForegroundBanner;

  String get _platformName {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  Future<void> initialize({
    required void Function(String route) onNavigate,
    void Function(ForegroundPushBanner banner)? onForegroundBanner,
  }) async {
    _onNavigate = onNavigate;
    _onForegroundBanner = onForegroundBanner;
    if (_initialized) return;

    if (!EnvConfig.hasFirebaseConfig || Firebase.apps.isEmpty) {
      statusNotifier.value = const FcmStatus(
        isSupported: false,
        isInitialized: false,
      );
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      final supported = await messaging.isSupported();
      if (!supported) {
        statusNotifier.value = const FcmStatus(
          isSupported: false,
          isInitialized: true,
        );
        _initialized = true;
        return;
      }

      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final settings = await messaging.getNotificationSettings();
      var authStatus = settings.authorizationStatus;

      // On native mobile we can prompt cleanly at startup if undetermined;
      // on Web browsers require a user gesture so we only prompt on explicit action.
      if (!kIsWeb && authStatus == AuthorizationStatus.notDetermined) {
        final requested = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        authStatus = requested.authorizationStatus;
      }

      statusNotifier.value = FcmStatus(
        isSupported: true,
        isInitialized: true,
        permissionStatus: authStatus,
      );

      await _onMessageSub?.cancel();
      _onMessageSub = FirebaseMessaging.onMessage.listen(_handleForeground);

      await _onOpenedSub?.cancel();
      _onOpenedSub =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpen(initialMessage);
      }

      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((token) async {
        await _persistToken(token);
      });

      _syncListener ??= () {
        final uid = _sync.statusNotifier.value.uid;
        if (uid != null && uid != _lastSyncedUid && _currentToken != null) {
          _persistToken(_currentToken!);
        }
      };
      _sync.statusNotifier.addListener(_syncListener!);

      await _refreshTokenIfAuthorized(authStatus);
      _initialized = true;
    } catch (e, st) {
      CrashReporter.recordNonFatal(e, st);
      statusNotifier.value = statusNotifier.value.copyWith(
        isSupported: true,
        isInitialized: false,
        lastError: e.toString(),
      );
    }
  }

  Future<bool> requestPermissionAndRegister() async {
    if (!EnvConfig.hasFirebaseConfig || Firebase.apps.isEmpty) return false;
    try {
      final messaging = FirebaseMessaging.instance;
      if (!await messaging.isSupported()) return false;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      statusNotifier.value = statusNotifier.value.copyWith(
        isSupported: true,
        isInitialized: true,
        permissionStatus: settings.authorizationStatus,
        clearError: true,
      );
      await _refreshTokenIfAuthorized(settings.authorizationStatus);
      return statusNotifier.value.isAuthorized;
    } catch (e, st) {
      CrashReporter.recordNonFatal(e, st);
      statusNotifier.value = statusNotifier.value.copyWith(
        lastError: e.toString(),
      );
      return false;
    }
  }

  Future<void> _refreshTokenIfAuthorized(AuthorizationStatus authStatus) async {
    final allowed = authStatus == AuthorizationStatus.authorized ||
        authStatus == AuthorizationStatus.provisional;
    if (!allowed) return;
    if (kIsWeb && EnvConfig.firebaseVapidKey.isEmpty) return;

    try {
      final token = kIsWeb
          ? await FirebaseMessaging.instance.getToken(
              vapidKey: EnvConfig.firebaseVapidKey,
            )
          : await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _persistToken(token);
      }
    } catch (e, st) {
      CrashReporter.recordNonFatal(e, st);
      statusNotifier.value = statusNotifier.value.copyWith(
        lastError: e.toString(),
      );
    }
  }

  Future<void> _persistToken(String token) async {
    _currentToken = token;
    _lastSyncedUid = _sync.statusNotifier.value.uid;
    await _sync.saveFcmToken(token, platform: _platformName);
    statusNotifier.value = statusNotifier.value.copyWith(
      hasToken: true,
      clearError: true,
    );
  }

  void _handleForeground(RemoteMessage message) {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'WarrantyVault';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        '';
    final route = resolveFcmRoute(message.data);
    final payload = route != null && route.startsWith('/item/')
        ? route.substring('/item/'.length)
        : null;

    if (!kIsWeb && body.isNotEmpty) {
      _notifications.showImmediateNotification(
        id: deterministicPushId(message.messageId),
        title: title,
        body: body,
        payload: payload,
      );
    }

    if (body.isNotEmpty) {
      _onForegroundBanner?.call(
        ForegroundPushBanner(
          title: title,
          body: body,
          route: route,
        ),
      );
    }
  }

  void _handleMessageOpen(RemoteMessage message) {
    final route = resolveFcmRoute(message.data);
    if (route != null) {
      _onNavigate?.call(route);
    }
  }

  void dispose() {
    _onMessageSub?.cancel();
    _onOpenedSub?.cancel();
    _tokenRefreshSub?.cancel();
    if (_syncListener != null) {
      _sync.statusNotifier.removeListener(_syncListener!);
      _syncListener = null;
    }
    statusNotifier.dispose();
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  final service = FcmService(
    ref.watch(notificationServiceProvider),
    ref.watch(firebaseSyncServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
