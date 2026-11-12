import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/core/env_config.dart';
import 'package:warranty_vault/core/firebase_sync_service.dart';
import 'package:warranty_vault/data/database.dart';
import 'package:warranty_vault/data/repositories/warranty_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => EnvConfig.setTestOverrides(null));

  test('EnvConfig safely reports unconfigured when .env keys are empty',
      () async {
    EnvConfig.setTestOverrides({});
    expect(EnvConfig.hasFirebaseConfig, isFalse);
    expect(EnvConfig.toFirebaseOptions(), isNull);
  });

  test('EnvConfig builds FirebaseOptions when .env keys are populated', () {
    EnvConfig.setTestOverrides({
      'FIREBASE_API_KEY': 'test-api-key',
      'FIREBASE_APP_ID': '1:123456:web:abcdef',
      'FIREBASE_MESSAGING_SENDER_ID': '123456',
      'FIREBASE_PROJECT_ID': 'warranty-vault-test',
      'FIREBASE_STORAGE_BUCKET': 'warranty-vault-test.appspot.com',
    });
    expect(EnvConfig.hasFirebaseConfig, isTrue);
    final opts = EnvConfig.toFirebaseOptions();
    expect(opts, isNotNull);
    expect(opts!.projectId, 'warranty-vault-test');
    expect(opts.apiKey, 'test-api-key');
  });

  test('FirebaseSyncService degrades gracefully offline when unconfigured',
      () async {
    EnvConfig.setTestOverrides({});
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    final repo = WarrantyRepository(db);
    final sync = FirebaseSyncService(repo);

    await sync.initialize();
    expect(sync.isReady, isFalse);
    expect(sync.statusNotifier.value.isConfigured, isFalse);
  });
}
