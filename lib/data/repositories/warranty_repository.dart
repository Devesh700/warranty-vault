import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/local_file_store.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../database.dart';

class WarrantyRepository {
  WarrantyRepository(this._db);

  final AppDatabase _db;

  // --- Items ---

  Stream<List<WarrantyItem>> watchAllItems() {
    return (_db.select(_db.items)
          ..orderBy([(t) => OrderingTerm.asc(t.warrantyEndDate)]))
        .watch()
        .map((rows) => rows.map(_mapItem).toList());
  }

  Future<List<WarrantyItem>> getAllItems() async {
    final rows = await (_db.select(_db.items)
          ..orderBy([(t) => OrderingTerm.asc(t.warrantyEndDate)]))
        .get();
    return rows.map(_mapItem).toList();
  }

  Stream<WarrantyItem?> watchItem(String id) {
    return (_db.select(_db.items)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _mapItem(row));
  }

  Future<WarrantyItem?> getItem(String id) async {
    final row = await (_db.select(_db.items)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapItem(row);
  }

  Future<int> getItemCount() async {
    final countExp = _db.items.id.count();
    final query = _db.selectOnly(_db.items)..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<void> upsertItem(WarrantyItem item) async {
    await _db.into(_db.items).insertOnConflictUpdate(
          ItemsCompanion(
            id: Value(item.id),
            name: Value(item.name),
            brand: Value(item.brand),
            model: Value(item.model),
            serialNumber: Value(item.serialNumber),
            category: Value(item.category.name),
            purchaseDate: Value(item.purchaseDate),
            price: Value(item.price),
            currency: Value(item.currency),
            storeName: Value(item.storeName),
            warrantyMonths: Value(item.warrantyMonths),
            warrantyEndDate: Value(item.warrantyEndDate),
            extendedWarrantyEndDate: Value(item.extendedWarrantyEndDate),
            isLifetime: Value(item.isLifetime),
            notes: Value(item.notes),
            createdAt: Value(item.createdAt),
            updatedAt: Value(item.updatedAt),
          ),
        );
  }

  Future<void> restoreItemWithRelations({
    required WarrantyItem item,
    List<ItemAttachment> attachments = const [],
  }) async {
    await _db.transaction(() async {
      await upsertItem(item);
      for (final att in attachments) {
        await addAttachment(att);
      }
    });
  }

  Future<void> deleteItem(String id) async {
    await (_db.delete(_db.items)..where((t) => t.id.equals(id))).go();
  }

  // --- Attachments ---

  Stream<List<ItemAttachment>> watchAttachmentsForItem(String itemId) {
    return (_db.select(_db.attachments)
          ..where((t) => t.itemId.equals(itemId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_mapAttachment).toList());
  }

  Future<List<ItemAttachment>> getAttachmentsForItem(String itemId) async {
    final rows = await (_db.select(_db.attachments)
          ..where((t) => t.itemId.equals(itemId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(_mapAttachment).toList();
  }

  Future<List<ItemAttachment>> getAllAttachments() async {
    final rows = await _db.select(_db.attachments).get();
    return rows.map(_mapAttachment).toList();
  }

  Future<void> addAttachment(ItemAttachment attachment) async {
    await _db.into(_db.attachments).insertOnConflictUpdate(
          AttachmentsCompanion(
            id: Value(attachment.id),
            itemId: Value(attachment.itemId),
            type: Value(attachment.type.name),
            localPath: Value(attachment.localPath),
            createdAt: Value(attachment.createdAt),
          ),
        );
  }

  Future<void> deleteAttachment(String id) async {
    await (_db.delete(_db.attachments)..where((t) => t.id.equals(id))).go();
  }

  // --- Reminders ---

  Future<List<ItemReminder>> getRemindersForItem(String itemId) async {
    final rows = await (_db.select(_db.reminders)
          ..where((t) => t.itemId.equals(itemId)))
        .get();
    return rows.map(_mapReminder).toList();
  }

  Future<List<ItemReminder>> getAllReminders() async {
    final rows = await _db.select(_db.reminders).get();
    return rows.map(_mapReminder).toList();
  }

  Future<void> replaceRemindersForItem(
    String itemId,
    List<ItemReminder> newReminders,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(_db.reminders)..where((t) => t.itemId.equals(itemId)))
          .go();
      for (final r in newReminders) {
        await _db.into(_db.reminders).insert(
              RemindersCompanion(
                id: Value(r.id),
                itemId: Value(r.itemId),
                fireAt: Value(r.fireAt),
                kind: Value(r.kind.name),
                notificationId: Value(r.notificationId),
              ),
            );
      }
    });
  }

  // --- Settings ---

  static const _kTheme = 'theme';
  static const _kLanguage = 'language';
  static const _kReminderHour = 'reminderHour';
  static const _kReminderMinute = 'reminderMinute';
  static const _kRemindD30 = 'remindD30';
  static const _kRemindD7 = 'remindD7';
  static const _kRemindD1 = 'remindD1';
  static const _kAppLockEnabled = 'appLockEnabled';
  static const _kOnboardingDone = 'onboardingDone';
  static const _kKeepUnmodifiedCopy = 'keepUnmodifiedCopy';
  static const _kIsProCached = 'isProCached';
  static const _kItemDraft = 'itemDraft';

  Stream<UserSettings> watchSettings() {
    return _db.select(_db.appSettings).watch().map(_settingsFromRows);
  }

  Future<UserSettings> getSettings() async {
    final rows = await _db.select(_db.appSettings).get();
    return _settingsFromRows(rows);
  }

  Future<void> updateSetting(String key, String value) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion(key: Value(key), value: Value(value)),
        );
  }

  Future<void> saveSettings(UserSettings settings) async {
    await _db.transaction(() async {
      await updateSetting(_kTheme, settings.theme.name);
      await updateSetting(_kLanguage, settings.language.name);
      await updateSetting(_kReminderHour, settings.reminderHour.toString());
      await updateSetting(_kReminderMinute, settings.reminderMinute.toString());
      await updateSetting(_kRemindD30, settings.remindD30.toString());
      await updateSetting(_kRemindD7, settings.remindD7.toString());
      await updateSetting(_kRemindD1, settings.remindD1.toString());
      await updateSetting(_kAppLockEnabled, settings.appLockEnabled.toString());
      await updateSetting(_kOnboardingDone, settings.onboardingDone.toString());
      await updateSetting(
          _kKeepUnmodifiedCopy, settings.keepUnmodifiedCopy.toString());
      await updateSetting(_kIsProCached, settings.isProCached.toString());
    });
  }

  // --- Drafts (24h retention) ---

  Future<void> saveDraft(Map<String, dynamic> draftJson) async {
    final payload = <String, dynamic>{
      ...draftJson,
      '_savedAt': DateTime.now().toIso8601String(),
    };
    await updateSetting(_kItemDraft, jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> getValidDraft(Duration maxAge) async {
    final row = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(_kItemDraft)))
        .getSingleOrNull();
    if (row == null || row.value.isEmpty) return null;
    try {
      final decoded = jsonDecode(row.value) as Map<String, dynamic>;
      final savedAtStr = decoded['_savedAt'] as String?;
      if (savedAtStr == null) return null;
      final savedAt = DateTime.tryParse(savedAtStr);
      if (savedAt == null) return null;
      if (DateTime.now().difference(savedAt) > maxAge) {
        await clearDraft();
        return null;
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearDraft() async {
    await (_db.delete(_db.appSettings)..where((t) => t.key.equals(_kItemDraft)))
        .go();
  }

  // --- Delete all data ---

  Future<void> deleteAllData() async {
    final attachments = await getAllAttachments();
    for (final att in attachments) {
      await LocalFileStore.deleteFile(att.localPath);
    }
    await _db.transaction(() async {
      await _db.delete(_db.reminders).go();
      await _db.delete(_db.attachments).go();
      await _db.delete(_db.items).go();
      await _db.delete(_db.appSettings).go();
    });
  }

  // --- Mappers ---

  WarrantyItem _mapItem(Item row) {
    return WarrantyItem(
      id: row.id,
      name: row.name,
      brand: row.brand,
      model: row.model,
      serialNumber: row.serialNumber,
      category: ItemCategory.values.firstWhere(
        (c) => c.name == row.category,
        orElse: () => ItemCategory.other,
      ),
      purchaseDate: row.purchaseDate,
      price: row.price,
      currency: row.currency,
      storeName: row.storeName,
      warrantyMonths: row.warrantyMonths,
      warrantyEndDate: row.warrantyEndDate,
      extendedWarrantyEndDate: row.extendedWarrantyEndDate,
      isLifetime: row.isLifetime,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  ItemAttachment _mapAttachment(Attachment row) {
    return ItemAttachment(
      id: row.id,
      itemId: row.itemId,
      type: AttachmentType.values.firstWhere(
        (t) => t.name == row.type,
        orElse: () => AttachmentType.other,
      ),
      localPath: row.localPath,
      createdAt: row.createdAt,
    );
  }

  ItemReminder _mapReminder(Reminder row) {
    return ItemReminder(
      id: row.id,
      itemId: row.itemId,
      fireAt: row.fireAt,
      kind: ReminderKind.values.firstWhere(
        (k) => k.name == row.kind,
        orElse: () => ReminderKind.d7,
      ),
      notificationId: row.notificationId,
    );
  }

  UserSettings _settingsFromRows(List<AppSetting> rows) {
    final map = {for (final r in rows) r.key: r.value};
    return UserSettings(
      theme: AppThemePreference.values.firstWhere(
        (e) => e.name == map[_kTheme],
        orElse: () => AppThemePreference.system,
      ),
      language: AppLanguagePreference.values.firstWhere(
        (e) => e.name == map[_kLanguage],
        orElse: () => AppLanguagePreference.system,
      ),
      reminderHour: int.tryParse(map[_kReminderHour] ?? '') ?? 10,
      reminderMinute: int.tryParse(map[_kReminderMinute] ?? '') ?? 0,
      remindD30: map[_kRemindD30] != 'false',
      remindD7: map[_kRemindD7] != 'false',
      remindD1: map[_kRemindD1] != 'false',
      appLockEnabled: map[_kAppLockEnabled] == 'true',
      onboardingDone: map[_kOnboardingDone] == 'true',
      keepUnmodifiedCopy: map[_kKeepUnmodifiedCopy] == 'true',
      isProCached: map[_kIsProCached] == 'true',
    );
  }
}
