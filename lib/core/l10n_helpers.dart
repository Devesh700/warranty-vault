import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../domain/enums.dart';
import '../l10n/generated/app_localizations.dart';

extension ItemCategoryL10n on ItemCategory {
  String label(AppLocalizations l10n) {
    switch (this) {
      case ItemCategory.phone:
        return l10n.categoryPhone;
      case ItemCategory.laptop:
        return l10n.categoryLaptop;
      case ItemCategory.tv:
        return l10n.categoryTv;
      case ItemCategory.ac:
        return l10n.categoryAc;
      case ItemCategory.fridge:
        return l10n.categoryFridge;
      case ItemCategory.washingMachine:
        return l10n.categoryWashingMachine;
      case ItemCategory.kitchenAppliance:
        return l10n.categoryKitchenAppliance;
      case ItemCategory.audio:
        return l10n.categoryAudio;
      case ItemCategory.vehicle:
        return l10n.categoryVehicle;
      case ItemCategory.furniture:
        return l10n.categoryFurniture;
      case ItemCategory.other:
        return l10n.categoryOther;
    }
  }
}

extension WarrantyStatusL10n on WarrantyStatus {
  String label(AppLocalizations l10n) {
    switch (this) {
      case WarrantyStatus.active:
        return l10n.statusActive;
      case WarrantyStatus.expiringSoon:
        return l10n.statusExpiringSoon;
      case WarrantyStatus.expired:
        return l10n.statusExpired;
      case WarrantyStatus.noWarranty:
        return l10n.statusNoWarranty;
      case WarrantyStatus.lifetime:
        return l10n.statusLifetime;
    }
  }
}

String formatShortDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat('d MMM yyyy', locale).format(date);
}

String formatCurrencyAmount(
  BuildContext context,
  double amount,
  String currencyCode,
) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  try {
    return NumberFormat.simpleCurrency(
      locale: locale,
      name: currencyCode,
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    ).format(amount);
  } catch (_) {
    return '$currencyCode ${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
  }
}

String defaultCurrencyFromLocale(Locale? locale) {
  final country = locale?.countryCode?.toUpperCase();
  switch (country) {
    case 'IN':
      return 'INR';
    case 'US':
      return 'USD';
    case 'GB':
      return 'GBP';
    case 'EU':
    case 'DE':
    case 'FR':
      return 'EUR';
    default:
      return locale?.languageCode == 'hi' ? 'INR' : 'INR';
  }
}
