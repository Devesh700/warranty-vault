import 'enums.dart';

class WarrantyItem {
  const WarrantyItem({
    required this.id,
    required this.name,
    this.brand,
    this.model,
    this.serialNumber,
    required this.category,
    required this.purchaseDate,
    this.price,
    required this.currency,
    this.storeName,
    required this.warrantyMonths,
    required this.warrantyEndDate,
    this.extendedWarrantyEndDate,
    this.isLifetime = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final ItemCategory category;
  final DateTime purchaseDate;
  final double? price;
  final String currency;
  final String? storeName;
  final int warrantyMonths;
  final DateTime warrantyEndDate;
  final DateTime? extendedWarrantyEndDate;
  final bool isLifetime;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get effectiveEndDate {
    final extended = extendedWarrantyEndDate;
    if (extended != null && extended.isAfter(warrantyEndDate)) {
      return extended;
    }
    return warrantyEndDate;
  }

  WarrantyItem copyWith({
    String? id,
    String? name,
    String? brand,
    bool clearBrand = false,
    String? model,
    bool clearModel = false,
    String? serialNumber,
    bool clearSerialNumber = false,
    ItemCategory? category,
    DateTime? purchaseDate,
    double? price,
    bool clearPrice = false,
    String? currency,
    String? storeName,
    bool clearStoreName = false,
    int? warrantyMonths,
    DateTime? warrantyEndDate,
    DateTime? extendedWarrantyEndDate,
    bool clearExtendedWarrantyEndDate = false,
    bool? isLifetime,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WarrantyItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: clearBrand ? null : (brand ?? this.brand),
      model: clearModel ? null : (model ?? this.model),
      serialNumber:
          clearSerialNumber ? null : (serialNumber ?? this.serialNumber),
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      price: clearPrice ? null : (price ?? this.price),
      currency: currency ?? this.currency,
      storeName: clearStoreName ? null : (storeName ?? this.storeName),
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      warrantyEndDate: warrantyEndDate ?? this.warrantyEndDate,
      extendedWarrantyEndDate: clearExtendedWarrantyEndDate
          ? null
          : (extendedWarrantyEndDate ?? this.extendedWarrantyEndDate),
      isLifetime: isLifetime ?? this.isLifetime,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ItemAttachment {
  const ItemAttachment({
    required this.id,
    required this.itemId,
    required this.type,
    required this.localPath,
    required this.createdAt,
  });

  final String id;
  final String itemId;
  final AttachmentType type;
  final String localPath;
  final DateTime createdAt;
}

class ItemReminder {
  const ItemReminder({
    required this.id,
    required this.itemId,
    required this.fireAt,
    required this.kind,
    required this.notificationId,
  });

  final String id;
  final String itemId;
  final DateTime fireAt;
  final ReminderKind kind;
  final int notificationId;
}

class BrandContact {
  const BrandContact({
    required this.brand,
    required this.serviceNumber,
    required this.website,
    required this.claimTips,
  });

  final String brand;
  final String serviceNumber;
  final String website;
  final String claimTips;

  factory BrandContact.fromJson(Map<String, dynamic> json) {
    return BrandContact(
      brand: json['brand'] as String? ?? '',
      serviceNumber: json['serviceNumber'] as String? ?? '',
      website: json['website'] as String? ?? '',
      claimTips: json['claimTips'] as String? ?? '',
    );
  }
}

class UserSettings {
  const UserSettings({
    this.theme = AppThemePreference.system,
    this.language = AppLanguagePreference.system,
    this.reminderHour = 10,
    this.reminderMinute = 0,
    this.remindD30 = true,
    this.remindD7 = true,
    this.remindD1 = true,
    this.appLockEnabled = false,
    this.onboardingDone = false,
    this.keepUnmodifiedCopy = false,
    this.isProCached = false,
  });

  final AppThemePreference theme;
  final AppLanguagePreference language;
  final int reminderHour;
  final int reminderMinute;
  final bool remindD30;
  final bool remindD7;
  final bool remindD1;
  final bool appLockEnabled;
  final bool onboardingDone;
  final bool keepUnmodifiedCopy;
  final bool isProCached;

  UserSettings copyWith({
    AppThemePreference? theme,
    AppLanguagePreference? language,
    int? reminderHour,
    int? reminderMinute,
    bool? remindD30,
    bool? remindD7,
    bool? remindD1,
    bool? appLockEnabled,
    bool? onboardingDone,
    bool? keepUnmodifiedCopy,
    bool? isProCached,
  }) {
    return UserSettings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      remindD30: remindD30 ?? this.remindD30,
      remindD7: remindD7 ?? this.remindD7,
      remindD1: remindD1 ?? this.remindD1,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      keepUnmodifiedCopy: keepUnmodifiedCopy ?? this.keepUnmodifiedCopy,
      isProCached: isProCached ?? this.isProCached,
    );
  }
}
