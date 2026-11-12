import '../domain/enums.dart';
import '../domain/models.dart';
import 'constants.dart';

/// Strips time component to midnight UTC/local date for calendar math.
DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Computes warranty end date by adding calendar months to [purchaseDate],
/// clamping the day to the last day of the target month when needed.
DateTime computeWarrantyEndDate(DateTime purchaseDate, int warrantyMonths) {
  final base = dateOnly(purchaseDate);
  if (warrantyMonths <= 0) {
    return base;
  }
  final totalMonths = (base.month - 1) + warrantyMonths;
  final targetYear = base.year + (totalMonths ~/ 12);
  final targetMonth = (totalMonths % 12) + 1;
  final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
  final clampedDay =
      base.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : base.day;
  return DateTime(targetYear, targetMonth, clampedDay);
}

DateTime computeEffectiveEndDate({
  required DateTime purchaseDate,
  required int warrantyMonths,
  DateTime? extendedWarrantyEndDate,
}) {
  final baseEnd = computeWarrantyEndDate(purchaseDate, warrantyMonths);
  if (extendedWarrantyEndDate != null) {
    final ext = dateOnly(extendedWarrantyEndDate);
    if (ext.isAfter(baseEnd)) {
      return ext;
    }
  }
  return baseEnd;
}

int daysBetweenDates(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

WarrantyStatus computeWarrantyStatus(
  WarrantyItem item, {
  DateTime? now,
}) {
  if (item.isLifetime) {
    return WarrantyStatus.lifetime;
  }
  if (item.warrantyMonths <= 0 && item.extendedWarrantyEndDate == null) {
    return WarrantyStatus.noWarranty;
  }
  final today = dateOnly(now ?? DateTime.now());
  final end = dateOnly(item.effectiveEndDate);
  final daysLeft = daysBetweenDates(today, end);

  if (daysLeft < 0) {
    return WarrantyStatus.expired;
  }
  if (daysLeft <= AppLimits.expiringSoonDays) {
    return WarrantyStatus.expiringSoon;
  }
  return WarrantyStatus.active;
}

int daysRemainingForItem(WarrantyItem item, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final end = dateOnly(item.effectiveEndDate);
  return daysBetweenDates(today, end);
}

double warrantyProgressUsed(WarrantyItem item, {DateTime? now}) {
  if (item.isLifetime) return 0.0;
  final start = dateOnly(item.purchaseDate);
  final end = dateOnly(item.effectiveEndDate);
  final today = dateOnly(now ?? DateTime.now());

  final totalDays = daysBetweenDates(start, end);
  if (totalDays <= 0) return 1.0;

  final elapsedDays = daysBetweenDates(start, today);
  return (elapsedDays / totalDays).clamp(0.0, 1.0);
}
