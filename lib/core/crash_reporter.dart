import 'package:flutter/foundation.dart';

typedef CrashErrorCallback = void Function(Object error, StackTrace? stack);

/// Central crash-reporting hook (ready to forward to Firebase Crashlytics
/// once platform Firebase configuration files are added).
class CrashReporter {
  CrashReporter._();

  static CrashErrorCallback? _onReport;

  static void install({CrashErrorCallback? onReport}) {
    _onReport = onReport;

    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
      _onReport?.call(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _onReport?.call(error, stack);
      return true;
    };
  }

  static void recordNonFatal(Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('Non-fatal error: $error');
    }
    _onReport?.call(error, stack);
  }
}
