// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'WarrantyVault';

  @override
  String get tabItems => 'Items';

  @override
  String get tabExpiring => 'Expiring';

  @override
  String get tabSettings => 'Settings';

  @override
  String get addItem => 'Add item';

  @override
  String get editItem => 'Edit item';

  @override
  String get searchHint => 'Search items, brands, stores...';

  @override
  String itemsSummary(int count, int expiringCount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0, $expiringCount expiring soon';
  }

  @override
  String get filterAll => 'All';

  @override
  String get statusActive => 'Active';

  @override
  String get statusExpiringSoon => 'Expiring Soon';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusNoWarranty => 'No warranty';

  @override
  String get statusLifetime => 'Lifetime';

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
      zero: 'Expires today',
    );
    return '$_temp0';
  }

  @override
  String expiredDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Expired $days days ago',
      one: 'Expired 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get emptyItemsHeadline =>
      'No items yet. Add your first bill in 20 seconds.';

  @override
  String get emptyItemsHelp =>
      'Store bills, track warranties, and get timely reminders.';

  @override
  String get emptyFilteredHeadline => 'No matching items';

  @override
  String get emptyFilteredHelp =>
      'Try clearing your search or changing the filter.';

  @override
  String get emptyExpiringHeadline => 'Nothing expiring soon. You\'re covered.';

  @override
  String get emptyExpiringHelp =>
      'Items expiring in the next 90 days appear here.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get loadingLabel => 'Loading...';

  @override
  String get genericErrorHeadline => 'Something went wrong';

  @override
  String get genericErrorHelp => 'Please try again in a moment.';

  @override
  String get retry => 'Retry';

  @override
  String get categoryPhone => 'Phone';

  @override
  String get categoryLaptop => 'Laptop';

  @override
  String get categoryTv => 'TV';

  @override
  String get categoryAc => 'AC';

  @override
  String get categoryFridge => 'Fridge';

  @override
  String get categoryWashingMachine => 'Washing machine';

  @override
  String get categoryKitchenAppliance => 'Kitchen appliance';

  @override
  String get categoryAudio => 'Audio';

  @override
  String get categoryVehicle => 'Vehicle';

  @override
  String get categoryFurniture => 'Furniture';

  @override
  String get categoryOther => 'Other';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get next3Months => 'Next 3 months';

  @override
  String get extendWarranty => 'Extend warranty';

  @override
  String extendYourWarranty(String product) {
    return 'Extend your $product warranty';
  }

  @override
  String get sponsoredLabel => 'Sponsored';

  @override
  String get affiliatePlaceholderNote =>
      'Partner extended warranty offers are coming soon. Links will appear here once enabled.';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get settingsSectionReminders => 'Reminders';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsSectionSecurity => 'Security';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsSectionSubscription => 'Subscription';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी (Hindi)';

  @override
  String get reminderTimeLabel => 'Reminder time';

  @override
  String get appLockLabel => 'App lock (PIN / Biometrics)';

  @override
  String get exportAllData => 'Export all data (ZIP)';

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get subscriptionStatusFree => 'Free plan (up to 5 items)';

  @override
  String get subscriptionStatusPro => 'WarrantyVault Pro';

  @override
  String get manageSubscription => 'Manage subscription';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfService => 'Terms of service';

  @override
  String get appVersion => 'Version';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get rateApp => 'Rate app';

  @override
  String deleteItemUndo(String name) {
    return 'Deleted \"$name\"';
  }

  @override
  String get undo => 'Undo';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get somethingBroke => 'Something broke?';

  @override
  String get verifyContactDisclaimer =>
      'Verify contact details with the brand before calling.';

  @override
  String get fieldProductName => 'Product name';

  @override
  String get fieldProductNameHint => 'e.g. Samsung Split AC 1.5T';

  @override
  String get fieldProductNameRequired => 'Please enter a product name';

  @override
  String get fieldBrand => 'Brand';

  @override
  String get fieldBrandHint => 'e.g. Samsung, LG, Apple';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldPurchaseDate => 'Purchase date';

  @override
  String get futureDateError => 'Purchase date cannot be in the future';

  @override
  String get fieldWarrantyPeriod => 'Warranty period';

  @override
  String monthsCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
      zero: '0 months (No warranty)',
    );
    return '$_temp0';
  }

  @override
  String get lifetimeWarranty => 'Lifetime warranty';

  @override
  String get fieldPrice => 'Price (optional)';

  @override
  String get fieldPriceHint => 'e.g. 42999';

  @override
  String get invalidPriceError => 'Enter a valid positive amount';

  @override
  String get fieldStore => 'Store / Seller';

  @override
  String get fieldStoreHint => 'e.g. Croma, Amazon';

  @override
  String get moreDetails => 'More details';

  @override
  String get fieldModel => 'Model number';

  @override
  String get fieldSerialNumber => 'Serial / IMEI number';

  @override
  String get fieldNotes => 'Notes';

  @override
  String get fieldNotesHint => 'Any extra details or accessories included';

  @override
  String get warrantyPreviewTitle => 'Warranty preview';

  @override
  String warrantyEndsOn(String date) {
    return 'Ends on $date';
  }

  @override
  String get extendedWarrantyEndLabel => 'Extended warranty end';

  @override
  String get addExtendedWarranty => 'Add extended warranty date';

  @override
  String get itemSavedTitle => 'Item saved!';

  @override
  String remindersSetFor(String date) {
    return 'Reminders set before $date';
  }

  @override
  String get noRemindersNeeded => 'No expiry reminders needed for this item.';

  @override
  String get viewItem => 'View item';

  @override
  String get addAnother => 'Add another';

  @override
  String get addAnotherFromBill => 'Add another item from this bill';

  @override
  String get resumeDraftMessage => 'You have an unsaved item draft.';

  @override
  String get resumeDraft => 'Resume draft';

  @override
  String get discard => 'Discard';

  @override
  String get confirmDeleteTitle => 'Delete item?';

  @override
  String confirmDeleteBody(String name) {
    return 'This will remove \"$name\" and its reminders from this device.';
  }

  @override
  String get itemNotFound => 'Item not found';

  @override
  String get autoFilledTag => 'auto-filled';

  @override
  String get addAnotherPhoto => 'Add another photo';

  @override
  String get notificationChannelName => 'Warranty reminders';

  @override
  String notif30Days(String product) {
    return 'Your $product warranty ends in 30 days. Check if anything needs fixing.';
  }

  @override
  String notif7Days(String product) {
    return '$product warranty ends in 7 days. Last chance for free service.';
  }

  @override
  String notif1Day(String product) {
    return '$product warranty ends tomorrow.';
  }

  @override
  String get onboardingTitle1 => 'Never lose a bill again';

  @override
  String get onboardingBody1 =>
      'Snap a photo or import a PDF. All data stays private on your device.';

  @override
  String get onboardingTitle2 => 'Get reminded before warranty ends';

  @override
  String get onboardingBody2 =>
      'Timely alerts at 30, 7, and 1 day before expiry so you never miss free service.';

  @override
  String get onboardingTitle3 => 'Ready when something breaks';

  @override
  String get onboardingBody3 =>
      'One-tap brand service contacts and a ready-to-share claim PDF bundle.';

  @override
  String get onboardingNotificationReason =>
      'Allow notifications so WarrantyVault can alert you before warranties expire.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get addSourceTitle => 'Add a purchase';

  @override
  String get sourceScanBill => 'Scan bill (camera)';

  @override
  String get sourceChoosePhoto => 'Choose photo';

  @override
  String get sourceImportPdf => 'Import PDF';

  @override
  String get sourceEnterManually => 'Enter manually';

  @override
  String get reviewBillImage => 'Review bill';

  @override
  String get retake => 'Retake';

  @override
  String get useThis => 'Use this';

  @override
  String get scanningBill => 'Reading bill details...';

  @override
  String get ocrNoTextWarning =>
      'Couldn\'t read text clearly. You can fill in the details manually.';

  @override
  String get attachmentBill => 'Bill';

  @override
  String get attachmentWarrantyCard => 'Warranty card';

  @override
  String get attachmentProductPhoto => 'Product photo';

  @override
  String get attachmentOther => 'Other';

  @override
  String get chooseAttachmentType => 'Photo type';

  @override
  String get share => 'Share';

  @override
  String get storageError =>
      'Could not save image. Your form details are safe—please try again.';

  @override
  String get keepUnmodifiedCopy => 'Keep unmodified original bill copy';

  @override
  String attachmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments',
      one: '1 attachment',
    );
    return '$_temp0';
  }

  @override
  String underWarrantyUntil(String date) {
    return 'Under warranty until $date';
  }

  @override
  String get warrantyExpiredBanner => 'Warranty expired';

  @override
  String get goodwillRepairNote =>
      'Some brands still offer goodwill or paid repairs—check before replacing.';

  @override
  String get lifetimeWarrantyBanner => 'Covered under lifetime warranty';

  @override
  String get noWarrantyBanner => 'No warranty recorded';

  @override
  String get brandServiceTitle => 'Brand service support';

  @override
  String callSupport(String number) {
    return 'Call $number';
  }

  @override
  String get visitWebsite => 'Visit support website';

  @override
  String get claimTipsLabel => 'Claim tips';

  @override
  String get noBrandMatchHelp =>
      'No saved contact for this brand yet. Browse supported brands below.';

  @override
  String get chooseBrandContact => 'Browse brand directory';

  @override
  String get shareClaimBundle => 'Share claim bundle (PDF)';

  @override
  String get generatingPdf => 'Preparing PDF...';

  @override
  String get claimChecklistTitle => 'Before you contact support';

  @override
  String get checklistBillSerial => 'Keep your bill and serial number ready';

  @override
  String get checklistIssuePhoto => 'Note the issue and take a photo or video';

  @override
  String get compareRepairPlans => 'Compare repair-protection plans';

  @override
  String get notifPermissionDeniedBanner =>
      'Warranty reminders are paused. Enable notifications so you don\'t miss expiry alerts.';

  @override
  String get enable => 'Enable';

  @override
  String get paywallHeadline => 'Keep every bill safe, forever';

  @override
  String get paywallBenefitUnlimited => 'Unlimited items & bills';

  @override
  String get paywallBenefitBackup => 'Encrypted cloud backup';

  @override
  String get paywallBenefitFamily => 'Family vault sharing';

  @override
  String get paywallBenefitSupport => 'Priority support';

  @override
  String get planYearly => 'Yearly';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get bestValue => 'Best value';

  @override
  String get freeTrial7Days => '7-day free trial included';

  @override
  String get priceUnavailableOffline =>
      'Connect to the internet to load store pricing';

  @override
  String get continueButton => 'Continue';

  @override
  String get purchaseRestored => 'Subscription restored!';

  @override
  String get noActiveSubscription => 'No active subscription found.';

  @override
  String get purchaseSuccess => 'Welcome to WarrantyVault Pro!';

  @override
  String get purchaseNotConfigured =>
      'Store billing is not configured in this build.';

  @override
  String get remind30DaysToggle => '30 days before expiry';

  @override
  String get remind7DaysToggle => '7 days before expiry';

  @override
  String get remind1DayToggle => '1 day before expiry';

  @override
  String get deleteAllConfirmTitle => 'Delete all data?';

  @override
  String get deleteAllConfirmBody =>
      'This permanently erases all items, bill photos, reminders, and settings from this device.';

  @override
  String get allDataDeleted => 'All data deleted.';

  @override
  String get exportingData => 'Creating ZIP export...';

  @override
  String get exportSuccess => 'Export ready to share.';

  @override
  String get unlockTitle => 'WarrantyVault is locked';

  @override
  String get unlockButton => 'Unlock';

  @override
  String get unlockReason => 'Authenticate to access your WarrantyVault bills';

  @override
  String get cloudBackupTitle => 'Cloud backup';

  @override
  String get familyVaultTitle => 'Family vault';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get localOnlyBadge => '100% on-device • Private';
}
