import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'WarrantyVault'**
  String get appName;

  /// No description provided for @tabItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get tabItems;

  /// No description provided for @tabExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get tabExpiring;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItem;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search items, brands, stores...'**
  String get searchHint;

  /// No description provided for @itemsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item} other{{count} items}}, {expiringCount} expiring soon'**
  String itemsSummary(int count, int expiringCount);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get statusExpiringSoon;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusNoWarranty.
  ///
  /// In en, this message translates to:
  /// **'No warranty'**
  String get statusNoWarranty;

  /// No description provided for @statusLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get statusLifetime;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Expires today} =1{1 day left} other{{days} days left}}'**
  String daysLeft(int days);

  /// No description provided for @expiredDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Expired 1 day ago} other{Expired {days} days ago}}'**
  String expiredDaysAgo(int days);

  /// No description provided for @emptyItemsHeadline.
  ///
  /// In en, this message translates to:
  /// **'No items yet. Add your first bill in 20 seconds.'**
  String get emptyItemsHeadline;

  /// No description provided for @emptyItemsHelp.
  ///
  /// In en, this message translates to:
  /// **'Store bills, track warranties, and get timely reminders.'**
  String get emptyItemsHelp;

  /// No description provided for @emptyFilteredHeadline.
  ///
  /// In en, this message translates to:
  /// **'No matching items'**
  String get emptyFilteredHeadline;

  /// No description provided for @emptyFilteredHelp.
  ///
  /// In en, this message translates to:
  /// **'Try clearing your search or changing the filter.'**
  String get emptyFilteredHelp;

  /// No description provided for @emptyExpiringHeadline.
  ///
  /// In en, this message translates to:
  /// **'Nothing expiring soon. You\'re covered.'**
  String get emptyExpiringHeadline;

  /// No description provided for @emptyExpiringHelp.
  ///
  /// In en, this message translates to:
  /// **'Items expiring in the next 90 days appear here.'**
  String get emptyExpiringHelp;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingLabel;

  /// No description provided for @genericErrorHeadline.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get genericErrorHeadline;

  /// No description provided for @genericErrorHelp.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a moment.'**
  String get genericErrorHelp;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @categoryPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get categoryPhone;

  /// No description provided for @categoryLaptop.
  ///
  /// In en, this message translates to:
  /// **'Laptop'**
  String get categoryLaptop;

  /// No description provided for @categoryTv.
  ///
  /// In en, this message translates to:
  /// **'TV'**
  String get categoryTv;

  /// No description provided for @categoryAc.
  ///
  /// In en, this message translates to:
  /// **'AC'**
  String get categoryAc;

  /// No description provided for @categoryFridge.
  ///
  /// In en, this message translates to:
  /// **'Fridge'**
  String get categoryFridge;

  /// No description provided for @categoryWashingMachine.
  ///
  /// In en, this message translates to:
  /// **'Washing machine'**
  String get categoryWashingMachine;

  /// No description provided for @categoryKitchenAppliance.
  ///
  /// In en, this message translates to:
  /// **'Kitchen appliance'**
  String get categoryKitchenAppliance;

  /// No description provided for @categoryAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get categoryAudio;

  /// No description provided for @categoryVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get categoryVehicle;

  /// No description provided for @categoryFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get categoryFurniture;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @next3Months.
  ///
  /// In en, this message translates to:
  /// **'Next 3 months'**
  String get next3Months;

  /// No description provided for @extendWarranty.
  ///
  /// In en, this message translates to:
  /// **'Extend warranty'**
  String get extendWarranty;

  /// No description provided for @extendYourWarranty.
  ///
  /// In en, this message translates to:
  /// **'Extend your {product} warranty'**
  String extendYourWarranty(String product);

  /// No description provided for @sponsoredLabel.
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get sponsoredLabel;

  /// No description provided for @affiliatePlaceholderNote.
  ///
  /// In en, this message translates to:
  /// **'Partner extended warranty offers are coming soon. Links will appear here once enabled.'**
  String get affiliatePlaceholderNote;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @settingsSectionReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsSectionReminders;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSectionSecurity;

  /// No description provided for @settingsSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsSectionData;

  /// No description provided for @settingsSectionSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSectionSubscription;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी (Hindi)'**
  String get languageHindi;

  /// No description provided for @reminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTimeLabel;

  /// No description provided for @appLockLabel.
  ///
  /// In en, this message translates to:
  /// **'App lock (PIN / Biometrics)'**
  String get appLockLabel;

  /// No description provided for @exportAllData.
  ///
  /// In en, this message translates to:
  /// **'Export all data (ZIP)'**
  String get exportAllData;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAllData;

  /// No description provided for @subscriptionStatusFree.
  ///
  /// In en, this message translates to:
  /// **'Free plan (up to 5 items)'**
  String get subscriptionStatusFree;

  /// No description provided for @subscriptionStatusPro.
  ///
  /// In en, this message translates to:
  /// **'WarrantyVault Pro'**
  String get subscriptionStatusPro;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get manageSubscription;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appVersion;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate app'**
  String get rateApp;

  /// No description provided for @deleteItemUndo.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{name}\"'**
  String deleteItemUndo(String name);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @somethingBroke.
  ///
  /// In en, this message translates to:
  /// **'Something broke?'**
  String get somethingBroke;

  /// No description provided for @verifyContactDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Verify contact details with the brand before calling.'**
  String get verifyContactDisclaimer;

  /// No description provided for @fieldProductName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get fieldProductName;

  /// No description provided for @fieldProductNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Samsung Split AC 1.5T'**
  String get fieldProductNameHint;

  /// No description provided for @fieldProductNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a product name'**
  String get fieldProductNameRequired;

  /// No description provided for @fieldBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get fieldBrand;

  /// No description provided for @fieldBrandHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Samsung, LG, Apple'**
  String get fieldBrandHint;

  /// No description provided for @fieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// No description provided for @fieldPurchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get fieldPurchaseDate;

  /// No description provided for @futureDateError.
  ///
  /// In en, this message translates to:
  /// **'Purchase date cannot be in the future'**
  String get futureDateError;

  /// No description provided for @fieldWarrantyPeriod.
  ///
  /// In en, this message translates to:
  /// **'Warranty period'**
  String get fieldWarrantyPeriod;

  /// No description provided for @monthsCount.
  ///
  /// In en, this message translates to:
  /// **'{months, plural, =0{0 months (No warranty)} =1{1 month} other{{months} months}}'**
  String monthsCount(int months);

  /// No description provided for @lifetimeWarranty.
  ///
  /// In en, this message translates to:
  /// **'Lifetime warranty'**
  String get lifetimeWarranty;

  /// No description provided for @fieldPrice.
  ///
  /// In en, this message translates to:
  /// **'Price (optional)'**
  String get fieldPrice;

  /// No description provided for @fieldPriceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 42999'**
  String get fieldPriceHint;

  /// No description provided for @invalidPriceError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid positive amount'**
  String get invalidPriceError;

  /// No description provided for @fieldStore.
  ///
  /// In en, this message translates to:
  /// **'Store / Seller'**
  String get fieldStore;

  /// No description provided for @fieldStoreHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Croma, Amazon'**
  String get fieldStoreHint;

  /// No description provided for @moreDetails.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get moreDetails;

  /// No description provided for @fieldModel.
  ///
  /// In en, this message translates to:
  /// **'Model number'**
  String get fieldModel;

  /// No description provided for @fieldSerialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial / IMEI number'**
  String get fieldSerialNumber;

  /// No description provided for @fieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get fieldNotes;

  /// No description provided for @fieldNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Any extra details or accessories included'**
  String get fieldNotesHint;

  /// No description provided for @warrantyPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Warranty preview'**
  String get warrantyPreviewTitle;

  /// No description provided for @warrantyEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends on {date}'**
  String warrantyEndsOn(String date);

  /// No description provided for @extendedWarrantyEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Extended warranty end'**
  String get extendedWarrantyEndLabel;

  /// No description provided for @addExtendedWarranty.
  ///
  /// In en, this message translates to:
  /// **'Add extended warranty date'**
  String get addExtendedWarranty;

  /// No description provided for @itemSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Item saved!'**
  String get itemSavedTitle;

  /// No description provided for @remindersSetFor.
  ///
  /// In en, this message translates to:
  /// **'Reminders set before {date}'**
  String remindersSetFor(String date);

  /// No description provided for @noRemindersNeeded.
  ///
  /// In en, this message translates to:
  /// **'No expiry reminders needed for this item.'**
  String get noRemindersNeeded;

  /// No description provided for @viewItem.
  ///
  /// In en, this message translates to:
  /// **'View item'**
  String get viewItem;

  /// No description provided for @addAnother.
  ///
  /// In en, this message translates to:
  /// **'Add another'**
  String get addAnother;

  /// No description provided for @addAnotherFromBill.
  ///
  /// In en, this message translates to:
  /// **'Add another item from this bill'**
  String get addAnotherFromBill;

  /// No description provided for @resumeDraftMessage.
  ///
  /// In en, this message translates to:
  /// **'You have an unsaved item draft.'**
  String get resumeDraftMessage;

  /// No description provided for @resumeDraft.
  ///
  /// In en, this message translates to:
  /// **'Resume draft'**
  String get resumeDraft;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete item?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove \"{name}\" and its reminders from this device.'**
  String confirmDeleteBody(String name);

  /// No description provided for @itemNotFound.
  ///
  /// In en, this message translates to:
  /// **'Item not found'**
  String get itemNotFound;

  /// No description provided for @autoFilledTag.
  ///
  /// In en, this message translates to:
  /// **'auto-filled'**
  String get autoFilledTag;

  /// No description provided for @addAnotherPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add another photo'**
  String get addAnotherPhoto;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Warranty reminders'**
  String get notificationChannelName;

  /// No description provided for @notif30Days.
  ///
  /// In en, this message translates to:
  /// **'Your {product} warranty ends in 30 days. Check if anything needs fixing.'**
  String notif30Days(String product);

  /// No description provided for @notif7Days.
  ///
  /// In en, this message translates to:
  /// **'{product} warranty ends in 7 days. Last chance for free service.'**
  String notif7Days(String product);

  /// No description provided for @notif1Day.
  ///
  /// In en, this message translates to:
  /// **'{product} warranty ends tomorrow.'**
  String notif1Day(String product);

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Never lose a bill again'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Snap a photo or import a PDF. All data stays private on your device.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Get reminded before warranty ends'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Timely alerts at 30, 7, and 1 day before expiry so you never miss free service.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Ready when something breaks'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'One-tap brand service contacts and a ready-to-share claim PDF bundle.'**
  String get onboardingBody3;

  /// No description provided for @onboardingNotificationReason.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications so WarrantyVault can alert you before warranties expire.'**
  String get onboardingNotificationReason;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @addSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a purchase'**
  String get addSourceTitle;

  /// No description provided for @sourceScanBill.
  ///
  /// In en, this message translates to:
  /// **'Scan bill (camera)'**
  String get sourceScanBill;

  /// No description provided for @sourceChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get sourceChoosePhoto;

  /// No description provided for @sourceImportPdf.
  ///
  /// In en, this message translates to:
  /// **'Import PDF'**
  String get sourceImportPdf;

  /// No description provided for @sourceEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get sourceEnterManually;

  /// No description provided for @reviewBillImage.
  ///
  /// In en, this message translates to:
  /// **'Review bill'**
  String get reviewBillImage;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @useThis.
  ///
  /// In en, this message translates to:
  /// **'Use this'**
  String get useThis;

  /// No description provided for @scanningBill.
  ///
  /// In en, this message translates to:
  /// **'Reading bill details...'**
  String get scanningBill;

  /// No description provided for @ocrNoTextWarning.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read text clearly. You can fill in the details manually.'**
  String get ocrNoTextWarning;

  /// No description provided for @attachmentBill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get attachmentBill;

  /// No description provided for @attachmentWarrantyCard.
  ///
  /// In en, this message translates to:
  /// **'Warranty card'**
  String get attachmentWarrantyCard;

  /// No description provided for @attachmentProductPhoto.
  ///
  /// In en, this message translates to:
  /// **'Product photo'**
  String get attachmentProductPhoto;

  /// No description provided for @attachmentOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get attachmentOther;

  /// No description provided for @chooseAttachmentType.
  ///
  /// In en, this message translates to:
  /// **'Photo type'**
  String get chooseAttachmentType;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @storageError.
  ///
  /// In en, this message translates to:
  /// **'Could not save image. Your form details are safe—please try again.'**
  String get storageError;

  /// No description provided for @keepUnmodifiedCopy.
  ///
  /// In en, this message translates to:
  /// **'Keep unmodified original bill copy'**
  String get keepUnmodifiedCopy;

  /// No description provided for @attachmentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attachment} other{{count} attachments}}'**
  String attachmentsCount(int count);

  /// No description provided for @underWarrantyUntil.
  ///
  /// In en, this message translates to:
  /// **'Under warranty until {date}'**
  String underWarrantyUntil(String date);

  /// No description provided for @warrantyExpiredBanner.
  ///
  /// In en, this message translates to:
  /// **'Warranty expired'**
  String get warrantyExpiredBanner;

  /// No description provided for @goodwillRepairNote.
  ///
  /// In en, this message translates to:
  /// **'Some brands still offer goodwill or paid repairs—check before replacing.'**
  String get goodwillRepairNote;

  /// No description provided for @lifetimeWarrantyBanner.
  ///
  /// In en, this message translates to:
  /// **'Covered under lifetime warranty'**
  String get lifetimeWarrantyBanner;

  /// No description provided for @noWarrantyBanner.
  ///
  /// In en, this message translates to:
  /// **'No warranty recorded'**
  String get noWarrantyBanner;

  /// No description provided for @brandServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Brand service support'**
  String get brandServiceTitle;

  /// No description provided for @callSupport.
  ///
  /// In en, this message translates to:
  /// **'Call {number}'**
  String callSupport(String number);

  /// No description provided for @visitWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit support website'**
  String get visitWebsite;

  /// No description provided for @claimTipsLabel.
  ///
  /// In en, this message translates to:
  /// **'Claim tips'**
  String get claimTipsLabel;

  /// No description provided for @noBrandMatchHelp.
  ///
  /// In en, this message translates to:
  /// **'No saved contact for this brand yet. Browse supported brands below.'**
  String get noBrandMatchHelp;

  /// No description provided for @chooseBrandContact.
  ///
  /// In en, this message translates to:
  /// **'Browse brand directory'**
  String get chooseBrandContact;

  /// No description provided for @shareClaimBundle.
  ///
  /// In en, this message translates to:
  /// **'Share claim bundle (PDF)'**
  String get shareClaimBundle;

  /// No description provided for @generatingPdf.
  ///
  /// In en, this message translates to:
  /// **'Preparing PDF...'**
  String get generatingPdf;

  /// No description provided for @claimChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you contact support'**
  String get claimChecklistTitle;

  /// No description provided for @checklistBillSerial.
  ///
  /// In en, this message translates to:
  /// **'Keep your bill and serial number ready'**
  String get checklistBillSerial;

  /// No description provided for @checklistIssuePhoto.
  ///
  /// In en, this message translates to:
  /// **'Note the issue and take a photo or video'**
  String get checklistIssuePhoto;

  /// No description provided for @compareRepairPlans.
  ///
  /// In en, this message translates to:
  /// **'Compare repair-protection plans'**
  String get compareRepairPlans;

  /// No description provided for @notifPermissionDeniedBanner.
  ///
  /// In en, this message translates to:
  /// **'Warranty reminders are paused. Enable notifications so you don\'t miss expiry alerts.'**
  String get notifPermissionDeniedBanner;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @paywallHeadline.
  ///
  /// In en, this message translates to:
  /// **'Keep every bill safe, forever'**
  String get paywallHeadline;

  /// No description provided for @paywallBenefitUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited items & bills'**
  String get paywallBenefitUnlimited;

  /// No description provided for @paywallBenefitBackup.
  ///
  /// In en, this message translates to:
  /// **'Encrypted cloud backup'**
  String get paywallBenefitBackup;

  /// No description provided for @paywallBenefitFamily.
  ///
  /// In en, this message translates to:
  /// **'Family vault sharing'**
  String get paywallBenefitFamily;

  /// No description provided for @paywallBenefitSupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get paywallBenefitSupport;

  /// No description provided for @planYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get planYearly;

  /// No description provided for @planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthly;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get bestValue;

  /// No description provided for @freeTrial7Days.
  ///
  /// In en, this message translates to:
  /// **'7-day free trial included'**
  String get freeTrial7Days;

  /// No description provided for @priceUnavailableOffline.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to load store pricing'**
  String get priceUnavailableOffline;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @purchaseRestored.
  ///
  /// In en, this message translates to:
  /// **'Subscription restored!'**
  String get purchaseRestored;

  /// No description provided for @noActiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'No active subscription found.'**
  String get noActiveSubscription;

  /// No description provided for @purchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome to WarrantyVault Pro!'**
  String get purchaseSuccess;

  /// No description provided for @purchaseNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Store billing is not configured in this build.'**
  String get purchaseNotConfigured;

  /// No description provided for @remind30DaysToggle.
  ///
  /// In en, this message translates to:
  /// **'30 days before expiry'**
  String get remind30DaysToggle;

  /// No description provided for @remind7DaysToggle.
  ///
  /// In en, this message translates to:
  /// **'7 days before expiry'**
  String get remind7DaysToggle;

  /// No description provided for @remind1DayToggle.
  ///
  /// In en, this message translates to:
  /// **'1 day before expiry'**
  String get remind1DayToggle;

  /// No description provided for @deleteAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteAllConfirmTitle;

  /// No description provided for @deleteAllConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently erases all items, bill photos, reminders, and settings from this device.'**
  String get deleteAllConfirmBody;

  /// No description provided for @allDataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data deleted.'**
  String get allDataDeleted;

  /// No description provided for @exportingData.
  ///
  /// In en, this message translates to:
  /// **'Creating ZIP export...'**
  String get exportingData;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export ready to share.'**
  String get exportSuccess;

  /// No description provided for @unlockTitle.
  ///
  /// In en, this message translates to:
  /// **'WarrantyVault is locked'**
  String get unlockTitle;

  /// No description provided for @unlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockButton;

  /// No description provided for @unlockReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to access your WarrantyVault bills'**
  String get unlockReason;

  /// No description provided for @cloudBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup'**
  String get cloudBackupTitle;

  /// No description provided for @familyVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Family vault'**
  String get familyVaultTitle;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @localOnlyBadge.
  ///
  /// In en, this message translates to:
  /// **'100% on-device • Private'**
  String get localOnlyBadge;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
