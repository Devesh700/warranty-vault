import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricAuthOutcome {
  authenticated,
  notSupported,
  notEnrolled,
  lockedOut,
  cancelled,
  failed,
}

class BiometricAuthResult {
  const BiometricAuthResult({
    required this.outcome,
    this.message,
  });

  final BiometricAuthOutcome outcome;
  final String? message;

  bool get isSuccess => outcome == BiometricAuthOutcome.authenticated;
}

class AppLockService {
  AppLockService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isSupported() async {
    if (kIsWeb) return false;
    try {
      final deviceSupported = await _auth.isDeviceSupported();
      if (deviceSupported) return true;
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate(String reason) async {
    final result = await authenticateDetailed(reason);
    return result.isSuccess;
  }

  Future<BiometricAuthResult> authenticateDetailed(String reason) async {
    if (kIsWeb) {
      return const BiometricAuthResult(
        outcome: BiometricAuthOutcome.notSupported,
        message:
            'Biometric lock requires a mobile or desktop device with system authentication.',
      );
    }

    try {
      final deviceSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!deviceSupported && !canCheckBiometrics) {
        return const BiometricAuthResult(
          outcome: BiometricAuthOutcome.notSupported,
          message:
              'Device lock or biometrics are not set up on this device. Configure a screen lock in system settings first.',
        );
      }

      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
      if (ok) {
        return const BiometricAuthResult(
          outcome: BiometricAuthOutcome.authenticated,
        );
      }
      return const BiometricAuthResult(
        outcome: BiometricAuthOutcome.cancelled,
        message: 'Authentication was cancelled.',
      );
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet =>
          const BiometricAuthResult(
            outcome: BiometricAuthOutcome.notEnrolled,
            message:
                'No fingerprint, face unlock, or device passcode is enrolled on this device.',
          ),
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
          const BiometricAuthResult(
            outcome: BiometricAuthOutcome.notSupported,
            message: 'Biometric hardware is unavailable on this device.',
          ),
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout =>
          const BiometricAuthResult(
            outcome: BiometricAuthOutcome.lockedOut,
            message:
                'Too many failed attempts. Try again later or use your device passcode.',
          ),
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.userRequestedFallback =>
          const BiometricAuthResult(
            outcome: BiometricAuthOutcome.cancelled,
            message: 'Authentication cancelled.',
          ),
        _ => BiometricAuthResult(
            outcome: BiometricAuthOutcome.failed,
            message: e.description ?? 'Authentication failed (${e.code.name}).',
          ),
      };
    } catch (e) {
      return BiometricAuthResult(
        outcome: BiometricAuthOutcome.failed,
        message: e.toString(),
      );
    }
  }
}

final appLockServiceProvider = Provider<AppLockService>(
  (ref) => AppLockService(),
);
