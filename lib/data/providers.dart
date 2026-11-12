import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import 'database.dart';
import 'repositories/warranty_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final warrantyRepositoryProvider = Provider<WarrantyRepository>((ref) {
  return WarrantyRepository(ref.watch(databaseProvider));
});

final itemsStreamProvider = StreamProvider<List<WarrantyItem>>((ref) {
  return ref.watch(warrantyRepositoryProvider).watchAllItems();
});

final itemDetailStreamProvider =
    StreamProvider.family<WarrantyItem?, String>((ref, id) {
  return ref.watch(warrantyRepositoryProvider).watchItem(id);
});

final itemAttachmentsStreamProvider =
    StreamProvider.family<List<ItemAttachment>, String>((ref, itemId) {
  return ref.watch(warrantyRepositoryProvider).watchAttachmentsForItem(itemId);
});

final settingsStreamProvider = StreamProvider<UserSettings>((ref) {
  return ref.watch(warrantyRepositoryProvider).watchSettings();
});
