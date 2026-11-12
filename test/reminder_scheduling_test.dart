import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/core/date_logic.dart';
import 'package:warranty_vault/core/notification_service.dart';
import 'package:warranty_vault/domain/enums.dart';
import 'package:warranty_vault/domain/models.dart';

WarrantyItem _item({
  required DateTime purchaseDate,
  required int months,
  bool isLifetime = false,
}) {
  return WarrantyItem(
    id: 'item-rem-1',
    name: 'Samsung TV',
    category: ItemCategory.tv,
    purchaseDate: purchaseDate,
    currency: 'INR',
    warrantyMonths: months,
    warrantyEndDate: computeWarrantyEndDate(purchaseDate, months),
    isLifetime: isLifetime,
    createdAt: purchaseDate,
    updatedAt: purchaseDate,
  );
}

void main() {
  group('computeReminderPlansForItem', () {
    test('schedules 30, 7, 1 day reminders at configured time', () {
      final item = _item(
        purchaseDate: DateTime(2025, 1, 1),
        months: 12, // ends 2026-01-01
      );
      const settings = UserSettings(reminderHour: 10, reminderMinute: 30);
      final now = DateTime(2025, 11, 1, 9, 0);

      final plans = computeReminderPlansForItem(item, settings, now: now);
      expect(plans.length, 3);
      expect(plans[0].kind, ReminderKind.d30);
      expect(plans[0].fireAt, DateTime(2025, 12, 2, 10, 30));
      expect(plans[1].kind, ReminderKind.d7);
      expect(plans[1].fireAt, DateTime(2025, 12, 25, 10, 30));
      expect(plans[2].kind, ReminderKind.d1);
      expect(plans[2].fireAt, DateTime(2025, 12, 31, 10, 30));
      expect(plans.every((p) => p.notificationId > 0), isTrue);
    });

    test('skips past reminders and respects per-kind toggles', () {
      final item = _item(
        purchaseDate: DateTime(2025, 1, 1),
        months: 12, // ends 2026-01-01
      );
      const settings = UserSettings(
        reminderHour: 10,
        reminderMinute: 0,
        remindD7: false,
      );
      // After d30 (2025-12-02) has passed, before d7/d1
      final now = DateTime(2025, 12, 10, 12, 0);

      final plans = computeReminderPlansForItem(item, settings, now: now);
      expect(plans.length, 1);
      expect(plans.single.kind, ReminderKind.d1);
    });

    test('returns empty for lifetime and no-warranty items', () {
      final lifetime = _item(
        purchaseDate: DateTime(2025, 1, 1),
        months: 0,
        isLifetime: true,
      );
      final noWarranty = _item(
        purchaseDate: DateTime(2025, 1, 1),
        months: 0,
      );
      const settings = UserSettings();
      final now = DateTime(2025, 1, 2);

      expect(computeReminderPlansForItem(lifetime, settings, now: now), isEmpty);
      expect(
        computeReminderPlansForItem(noWarranty, settings, now: now),
        isEmpty,
      );
    });
  });
}
