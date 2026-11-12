import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/core/date_logic.dart';
import 'package:warranty_vault/domain/enums.dart';
import 'package:warranty_vault/domain/models.dart';

WarrantyItem _makeItem({
  required DateTime purchaseDate,
  required int warrantyMonths,
  DateTime? extendedWarrantyEndDate,
  bool isLifetime = false,
}) {
  final endDate = computeWarrantyEndDate(purchaseDate, warrantyMonths);
  return WarrantyItem(
    id: 'test-1',
    name: 'Test Device',
    category: ItemCategory.phone,
    purchaseDate: purchaseDate,
    currency: 'INR',
    warrantyMonths: warrantyMonths,
    warrantyEndDate: endDate,
    extendedWarrantyEndDate: extendedWarrantyEndDate,
    isLifetime: isLifetime,
    createdAt: purchaseDate,
    updatedAt: purchaseDate,
  );
}

void main() {
  group('computeWarrantyEndDate', () {
    test('adds calendar months accurately', () {
      expect(
        computeWarrantyEndDate(DateTime(2025, 3, 15), 12),
        DateTime(2026, 3, 15),
      );
      expect(
        computeWarrantyEndDate(DateTime(2025, 11, 10), 6),
        DateTime(2026, 5, 10),
      );
    });

    test('clamps day to last day of shorter month', () {
      expect(
        computeWarrantyEndDate(DateTime(2025, 1, 31), 1),
        DateTime(2025, 2, 28),
      );
      expect(
        computeWarrantyEndDate(DateTime(2024, 1, 31), 1),
        DateTime(2024, 2, 29),
      );
      expect(
        computeWarrantyEndDate(DateTime(2024, 2, 29), 12),
        DateTime(2025, 2, 28),
      );
    });

    test('0 warranty months returns purchase date', () {
      expect(
        computeWarrantyEndDate(DateTime(2025, 5, 20), 0),
        DateTime(2025, 5, 20),
      );
    });
  });

  group('computeWarrantyStatus', () {
    final now = DateTime(2026, 6, 1);

    test('Active when more than 30 days left', () {
      final item = _makeItem(
        purchaseDate: DateTime(2025, 8, 1),
        warrantyMonths: 12, // ends 2026-08-01 -> 61 days left
      );
      expect(computeWarrantyStatus(item, now: now), WarrantyStatus.active);
    });

    test('Expiring Soon when 0 to 30 days left (inclusive)', () {
      final exactly30 = _makeItem(
        purchaseDate: DateTime(2025, 7, 1),
        warrantyMonths: 12, // ends 2026-07-01 -> 30 days left
      );
      expect(
        computeWarrantyStatus(exactly30, now: now),
        WarrantyStatus.expiringSoon,
      );

      final todayEnds = _makeItem(
        purchaseDate: DateTime(2025, 6, 1),
        warrantyMonths: 12, // ends 2026-06-01 -> 0 days left
      );
      expect(
        computeWarrantyStatus(todayEnds, now: now),
        WarrantyStatus.expiringSoon,
      );
    });

    test('Expired when past effective end date', () {
      final item = _makeItem(
        purchaseDate: DateTime(2025, 5, 31),
        warrantyMonths: 12, // ends 2026-05-31 -> -1 day
      );
      expect(computeWarrantyStatus(item, now: now), WarrantyStatus.expired);
    });

    test('Extended warranty date overrides earlier base end date', () {
      final item = _makeItem(
        purchaseDate: DateTime(2025, 5, 31),
        warrantyMonths: 12,
        extendedWarrantyEndDate: DateTime(2027, 5, 31),
      );
      expect(item.effectiveEndDate, DateTime(2027, 5, 31));
      expect(computeWarrantyStatus(item, now: now), WarrantyStatus.active);
    });

    test('No warranty when warrantyMonths is 0 and no extended date', () {
      final item = _makeItem(
        purchaseDate: DateTime(2025, 1, 1),
        warrantyMonths: 0,
      );
      expect(computeWarrantyStatus(item, now: now), WarrantyStatus.noWarranty);
    });

    test('Lifetime never expires', () {
      final item = _makeItem(
        purchaseDate: DateTime(2020, 1, 1),
        warrantyMonths: 0,
        isLifetime: true,
      );
      expect(computeWarrantyStatus(item, now: now), WarrantyStatus.lifetime);
      expect(warrantyProgressUsed(item, now: now), 0.0);
    });
  });
}
