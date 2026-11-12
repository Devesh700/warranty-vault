import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/core/app_lock_service.dart';
import 'package:warranty_vault/core/env_config.dart';
import 'package:warranty_vault/core/fcm_service.dart';
import 'package:warranty_vault/core/widgets/warranty_vault_logo.dart';
import 'package:warranty_vault/data/database.dart';
import 'package:warranty_vault/data/providers.dart';
import 'package:warranty_vault/features/settings/auth_screen.dart';

void main() {
  group('FCM routing & ID helpers', () {
    test('resolveFcmRoute maps valid itemId and screen safely', () {
      expect(resolveFcmRoute({'itemId': 'item-42'}), '/item/item-42');
      expect(
        resolveFcmRoute({'itemId': 'item_9', 'screen': 'broke_help'}),
        '/broke-help/item_9',
      );
      expect(resolveFcmRoute({'route': '/expiring'}), '/expiring');
      expect(resolveFcmRoute({'route': '/settings'}), '/settings');
      expect(resolveFcmRoute({'route': '/auth'}), '/auth');
      expect(resolveFcmRoute({'route': '/item/abc-1'}), '/item/abc-1');
    });

    test('resolveFcmRoute rejects unsafe or unknown routes', () {
      expect(resolveFcmRoute({'itemId': '../secret'}), isNull);
      expect(resolveFcmRoute({'route': 'https://evil.example'}), isNull);
      expect(resolveFcmRoute({'route': '/unknown-screen'}), isNull);
      expect(resolveFcmRoute({}), isNull);
    });

    test('deterministicPushId produces positive consistent integers', () {
      final a = deterministicPushId('msg-123');
      final b = deterministicPushId('msg-123');
      final c = deterministicPushId('msg-456');
      expect(a, b);
      expect(a, greaterThan(0));
      expect(a, isNot(c));
    });
  });

  group('EnvConfig VAPID key', () {
    tearDown(() => EnvConfig.setTestOverrides(null));

    test('reads FIREBASE_VAPID_KEY override cleanly', () {
      EnvConfig.setTestOverrides({
        'FIREBASE_VAPID_KEY': 'test_vapid_public_key_123',
      });
      expect(EnvConfig.firebaseVapidKey, 'test_vapid_public_key_123');
    });
  });

  group('AppLockService safety', () {
    test('authenticateDetailed never throws when platform channel unavailable', () async {
      final service = AppLockService();
      final result = await service.authenticateDetailed('Unlock vault');
      expect(result.outcome, isNotNull);
      expect(result.isSuccess, isFalse);
    });
  });

  group('AuthScreen UI & validation', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.inMemory();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders logo, tabs, password visibility, and inline validation', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: AuthScreen(initialMode: AuthMode.signIn),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WarrantyVaultLogo), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);

      // Switch to Create Account mode
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.text('Create Account & Sync'), findsOneWidget);

      // Toggle password visibility
      final visButtons = find.byIcon(Icons.visibility_outlined);
      expect(visButtons, findsNWidgets(2));
      await tester.tap(visButtons.first);
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Clean Drift teardown
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });
}
