// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'WarrantyVault';

  @override
  String get tabItems => 'सामान';

  @override
  String get tabExpiring => 'जल्द समाप्त';

  @override
  String get tabSettings => 'सेटिंग्स';

  @override
  String get addItem => 'नया जोड़ें';

  @override
  String get editItem => 'सामान संपादित करें';

  @override
  String get searchHint => 'सामान, ब्रांड, दुकान खोजें...';

  @override
  String itemsSummary(int count, int expiringCount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सामान',
      one: '1 सामान',
      zero: 'कोई सामान नहीं',
    );
    return '$_temp0, $expiringCount जल्द समाप्त होने वाले';
  }

  @override
  String get filterAll => 'सभी';

  @override
  String get statusActive => 'सक्रिय';

  @override
  String get statusExpiringSoon => 'जल्द समाप्त';

  @override
  String get statusExpired => 'समाप्त';

  @override
  String get statusNoWarranty => 'कोई वारंटी नहीं';

  @override
  String get statusLifetime => 'आजीवन';

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन बाकी',
      one: '1 दिन बाकी',
      zero: 'आज समाप्त',
    );
    return '$_temp0';
  }

  @override
  String expiredDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन पहले समाप्त',
      one: '1 दिन पहले समाप्त',
    );
    return '$_temp0';
  }

  @override
  String get emptyItemsHeadline =>
      'अभी कोई सामान नहीं है। 20 सेकंड में पहला बिल जोड़ें।';

  @override
  String get emptyItemsHelp =>
      'बिल सुरक्षित रखें, वारंटी ट्रैक करें और समय पर रिमाइंडर पाएं।';

  @override
  String get emptyFilteredHeadline => 'कोई मिलता हुआ सामान नहीं मिला';

  @override
  String get emptyFilteredHelp => 'खोज साफ़ करें या फ़िल्टर बदलकर देखें।';

  @override
  String get emptyExpiringHeadline =>
      'जल्द कुछ समाप्त नहीं हो रहा। आप सुरक्षित हैं।';

  @override
  String get emptyExpiringHelp =>
      'अगले 90 दिनों में समाप्त होने वाले सामान यहाँ दिखेंगे।';

  @override
  String get clearFilters => 'फ़िल्टर हटाएं';

  @override
  String get loadingLabel => 'लोड हो रहा है...';

  @override
  String get genericErrorHeadline => 'कुछ गलत हो गया';

  @override
  String get genericErrorHelp => 'कृपया थोड़ी देर बाद फिर प्रयास करें।';

  @override
  String get retry => 'फिर से कोशिश करें';

  @override
  String get categoryPhone => 'फ़ोन';

  @override
  String get categoryLaptop => 'लैपटॉप';

  @override
  String get categoryTv => 'टीवी';

  @override
  String get categoryAc => 'एसी';

  @override
  String get categoryFridge => 'फ्रिज';

  @override
  String get categoryWashingMachine => 'वॉशिंग मशीन';

  @override
  String get categoryKitchenAppliance => 'रसोई उपकरण';

  @override
  String get categoryAudio => 'ऑडियो';

  @override
  String get categoryVehicle => 'वाहन';

  @override
  String get categoryFurniture => 'फ़र्नीचर';

  @override
  String get categoryOther => 'अन्य';

  @override
  String get thisWeek => 'इस सप्ताह';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get next3Months => 'अगले 3 महीने';

  @override
  String get extendWarranty => 'वारंटी बढ़ाएं';

  @override
  String extendYourWarranty(String product) {
    return 'अपने $product की वारंटी बढ़ाएं';
  }

  @override
  String get sponsoredLabel => 'प्रायोजित';

  @override
  String get affiliatePlaceholderNote =>
      'पार्टनर एक्सटेंडेड वारंटी ऑफ़र जल्द आ रहे हैं। सक्रिय होने पर लिंक यहाँ दिखेंगे।';

  @override
  String get comingSoon => 'जल्द आ रहा है';

  @override
  String get settingsSectionReminders => 'रिमाइंडर';

  @override
  String get settingsSectionAppearance => 'दिखावट';

  @override
  String get settingsSectionLanguage => 'भाषा';

  @override
  String get settingsSectionSecurity => 'सुरक्षा';

  @override
  String get settingsSectionData => 'डेटा';

  @override
  String get settingsSectionSubscription => 'सब्सक्रिप्शन';

  @override
  String get settingsSectionAbout => 'ऐप के बारे में';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get languageSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी (Hindi)';

  @override
  String get reminderTimeLabel => 'रिमाइंडर का समय';

  @override
  String get appLockLabel => 'ऐप लॉक (पिन / बायोमेट्रिक)';

  @override
  String get exportAllData => 'सभी डेटा एक्सपोर्ट करें (ZIP)';

  @override
  String get deleteAllData => 'सभी डेटा हटाएं';

  @override
  String get subscriptionStatusFree => 'फ्री प्लान (5 सामान तक)';

  @override
  String get subscriptionStatusPro => 'WarrantyVault प्रो';

  @override
  String get manageSubscription => 'सब्सक्रिप्शन प्रबंधित करें';

  @override
  String get restorePurchases => 'खरीदारी रीस्टोर करें';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get termsOfService => 'सेवा की शर्तें';

  @override
  String get appVersion => 'वर्ज़न';

  @override
  String get contactSupport => 'सहायता से संपर्क करें';

  @override
  String get rateApp => 'ऐप को रेट करें';

  @override
  String deleteItemUndo(String name) {
    return '\"$name\" हटाया गया';
  }

  @override
  String get undo => 'वापस लाएं';

  @override
  String get save => 'सेव करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get close => 'बंद करें';

  @override
  String get somethingBroke => 'कुछ खराब हो गया?';

  @override
  String get verifyContactDisclaimer =>
      'कॉल करने से पहले ब्रांड के संपर्क विवरण सत्यापित करें।';

  @override
  String get fieldProductName => 'सामान का नाम';

  @override
  String get fieldProductNameHint => 'जैसे Samsung Split AC 1.5T';

  @override
  String get fieldProductNameRequired => 'कृपया सामान का नाम लिखें';

  @override
  String get fieldBrand => 'ब्रांड';

  @override
  String get fieldBrandHint => 'जैसे Samsung, LG, Apple';

  @override
  String get fieldCategory => 'श्रेणी';

  @override
  String get fieldPurchaseDate => 'खरीदने की तारीख';

  @override
  String get futureDateError => 'खरीदने की तारीख भविष्य की नहीं हो सकती';

  @override
  String get fieldWarrantyPeriod => 'वारंटी अवधि';

  @override
  String monthsCount(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months महीने',
      one: '1 महीना',
      zero: '0 महीने (कोई वारंटी नहीं)',
    );
    return '$_temp0';
  }

  @override
  String get lifetimeWarranty => 'आजीवन वारंटी';

  @override
  String get fieldPrice => 'कीमत (वैकल्पिक)';

  @override
  String get fieldPriceHint => 'जैसे 42999';

  @override
  String get invalidPriceError => 'सही राशि दर्ज करें';

  @override
  String get fieldStore => 'दुकान / विक्रेता';

  @override
  String get fieldStoreHint => 'जैसे Croma, Amazon';

  @override
  String get moreDetails => 'अधिक विवरण';

  @override
  String get fieldModel => 'मॉडल नंबर';

  @override
  String get fieldSerialNumber => 'सीरियल / IMEI नंबर';

  @override
  String get fieldNotes => 'नोट्स';

  @override
  String get fieldNotesHint => 'कोई अतिरिक्त विवरण या एक्सेसरीज़';

  @override
  String get warrantyPreviewTitle => 'वारंटी प्रीव्यू';

  @override
  String warrantyEndsOn(String date) {
    return 'समाप्ति: $date';
  }

  @override
  String get extendedWarrantyEndLabel => 'बढ़ी हुई वारंटी समाप्ति';

  @override
  String get addExtendedWarranty => 'बढ़ी हुई वारंटी की तारीख जोड़ें';

  @override
  String get itemSavedTitle => 'सामान सेव हो गया!';

  @override
  String remindersSetFor(String date) {
    return '$date से पहले रिमाइंडर सेट किए गए';
  }

  @override
  String get noRemindersNeeded =>
      'इस सामान के लिए समाप्ति रिमाइंडर की आवश्यकता नहीं है।';

  @override
  String get viewItem => 'सामान देखें';

  @override
  String get addAnother => 'एक और जोड़ें';

  @override
  String get addAnotherFromBill => 'इसी बिल से एक और सामान जोड़ें';

  @override
  String get resumeDraftMessage => 'आपके पास एक बिना सेव किया ड्राफ्ट है।';

  @override
  String get resumeDraft => 'ड्राफ्ट खोलें';

  @override
  String get discard => 'हटाएं';

  @override
  String get confirmDeleteTitle => 'सामान हटाएं?';

  @override
  String confirmDeleteBody(String name) {
    return 'यह \"$name\" और इसके रिमाइंडर को इस फ़ोन से हटा देगा।';
  }

  @override
  String get itemNotFound => 'सामान नहीं मिला';

  @override
  String get autoFilledTag => 'ऑटो-फ़िल';

  @override
  String get addAnotherPhoto => 'एक और फ़ोटो जोड़ें';

  @override
  String get notificationChannelName => 'वारंटी रिमाइंडर';

  @override
  String notif30Days(String product) {
    return 'आपके $product की वारंटी 30 दिनों में समाप्त हो रही है। जांच लें कि कुछ ठीक करवाना है या नहीं।';
  }

  @override
  String notif7Days(String product) {
    return '$product की वारंटी 7 दिनों में समाप्त हो रही है। मुफ्त सेवा का आखिरी मौका।';
  }

  @override
  String notif1Day(String product) {
    return '$product की वारंटी कल समाप्त हो रही है।';
  }

  @override
  String get onboardingTitle1 => 'अब कोई बिल कभी न खोएं';

  @override
  String get onboardingBody1 =>
      'फ़ोटो खींचें या PDF चुनें। आपका सारा डेटा आपके फ़ोन पर सुरक्षित रहता है।';

  @override
  String get onboardingTitle2 => 'वारंटी खत्म होने से पहले रिमाइंडर पाएं';

  @override
  String get onboardingBody2 =>
      '30, 7 और 1 दिन पहले अलर्ट पाएं ताकि मुफ्त सर्विस का मौका न छूटे।';

  @override
  String get onboardingTitle3 => 'कुछ खराब हो तो तुरंत तैयार रहें';

  @override
  String get onboardingBody3 =>
      'एक टैप में ब्रांड सर्विस नंबर और शेयर करने के लिए क्लेम PDF बंडल।';

  @override
  String get onboardingNotificationReason =>
      'नोटिफिकेशन की अनुमति दें ताकि वारंटी खत्म होने से पहले आपको समय पर अलर्ट मिल सके।';

  @override
  String get skip => 'छोड़ें';

  @override
  String get next => 'आगे बढ़ें';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get addSourceTitle => 'खरीद जोड़ें';

  @override
  String get sourceScanBill => 'बिल स्कैन करें (कैमरा)';

  @override
  String get sourceChoosePhoto => 'फ़ोटो चुनें';

  @override
  String get sourceImportPdf => 'PDF चुनें';

  @override
  String get sourceEnterManually => 'खुद लिखें';

  @override
  String get reviewBillImage => 'बिल देखें';

  @override
  String get retake => 'फिर से लें';

  @override
  String get useThis => 'इसे उपयोग करें';

  @override
  String get scanningBill => 'बिल पढ़ा जा रहा है...';

  @override
  String get ocrNoTextWarning =>
      'बिल साफ नहीं पढ़ा जा सका। आप विवरण खुद भर सकते हैं।';

  @override
  String get attachmentBill => 'बिल';

  @override
  String get attachmentWarrantyCard => 'वारंटी कार्ड';

  @override
  String get attachmentProductPhoto => 'सामान की फ़ोटो';

  @override
  String get attachmentOther => 'अन्य';

  @override
  String get chooseAttachmentType => 'फ़ोटो का प्रकार';

  @override
  String get share => 'शेयर करें';

  @override
  String get storageError =>
      'फ़ोटो सेव नहीं हो सकी। आपकी जानकारी सुरक्षित है—कृपया फिर प्रयास करें।';

  @override
  String get keepUnmodifiedCopy => 'मूल बिल की बिना बदली कॉपी रखें';

  @override
  String attachmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फ़ाइलें',
      one: '1 फ़ाइल',
    );
    return '$_temp0';
  }

  @override
  String underWarrantyUntil(String date) {
    return '$date तक वारंटी में';
  }

  @override
  String get warrantyExpiredBanner => 'वारंटी समाप्त हो चुकी है';

  @override
  String get goodwillRepairNote =>
      'कुछ ब्रांड गुडविल या सशुल्क मरम्मत की सुविधा देते हैं—बदलने से पहले जांच लें।';

  @override
  String get lifetimeWarrantyBanner => 'आजीवन वारंटी के अंतर्गत';

  @override
  String get noWarrantyBanner => 'कोई वारंटी दर्ज नहीं';

  @override
  String get brandServiceTitle => 'ब्रांड सर्विस सहायता';

  @override
  String callSupport(String number) {
    return 'कॉल करें $number';
  }

  @override
  String get visitWebsite => 'सहायता वेबसाइट खोलें';

  @override
  String get claimTipsLabel => 'क्लेम टिप्स';

  @override
  String get noBrandMatchHelp =>
      'इस ब्रांड का नंबर अभी सेव नहीं है। नीचे अन्य ब्रांड देखें।';

  @override
  String get chooseBrandContact => 'ब्रांड डायरेक्टरी देखें';

  @override
  String get shareClaimBundle => 'क्लेम बंडल शेयर करें (PDF)';

  @override
  String get generatingPdf => 'PDF तैयार हो रहा है...';

  @override
  String get claimChecklistTitle => 'संपर्क करने से पहले';

  @override
  String get checklistBillSerial => 'अपना बिल और सीरियल नंबर तैयार रखें';

  @override
  String get checklistIssuePhoto => 'समस्या लिख लें और फ़ोटो या वीडियो बना लें';

  @override
  String get compareRepairPlans => 'रिपेयर-प्रोटेक्शन प्लान देखें';

  @override
  String get notifPermissionDeniedBanner =>
      'वारंटी रिमाइंडर बंद हैं। समय पर अलर्ट के लिए नोटिफिकेशन चालू करें।';

  @override
  String get enable => 'चालू करें';

  @override
  String get paywallHeadline => 'हर बिल हमेशा सुरक्षित रखें';

  @override
  String get paywallBenefitUnlimited => 'असीमित सामान और बिल';

  @override
  String get paywallBenefitBackup => 'एन्क्रिप्टेड क्लाउड बैकअप';

  @override
  String get paywallBenefitFamily => 'फैमिली वॉल्ट शेयरिंग';

  @override
  String get paywallBenefitSupport => 'प्राथमिकता सहायता';

  @override
  String get planYearly => 'वार्षिक';

  @override
  String get planMonthly => 'मासिक';

  @override
  String get bestValue => 'सर्वोत्तम मूल्य';

  @override
  String get freeTrial7Days => '7-दिन का फ्री ट्रायल शामिल';

  @override
  String get priceUnavailableOffline =>
      'स्टोर कीमत देखने के लिए इंटरनेट से जुड़ें';

  @override
  String get continueButton => 'जारी रखें';

  @override
  String get purchaseRestored => 'सब्सक्रिप्शन रीस्टोर हो गया!';

  @override
  String get noActiveSubscription => 'कोई सक्रिय सब्सक्रिप्शन नहीं मिला।';

  @override
  String get purchaseSuccess => 'WarrantyVault प्रो में आपका स्वागत है!';

  @override
  String get purchaseNotConfigured =>
      'इस बिल्ड में स्टोर बिलिंग कॉन्फ़िगर नहीं है।';

  @override
  String get remind30DaysToggle => 'समाप्ति से 30 दिन पहले';

  @override
  String get remind7DaysToggle => 'समाप्ति से 7 दिन पहले';

  @override
  String get remind1DayToggle => 'समाप्ति से 1 दिन पहले';

  @override
  String get deleteAllConfirmTitle => 'सभी डेटा हटाएं?';

  @override
  String get deleteAllConfirmBody =>
      'यह आपके फ़ोन से सभी सामान, बिल की फ़ोटो, रिमाइंडर और सेटिंग्स स्थायी रूप से मिटा देगा।';

  @override
  String get allDataDeleted => 'सभी डेटा हटा दिया गया।';

  @override
  String get exportingData => 'ZIP एक्सपोर्ट बनाया जा रहा है...';

  @override
  String get exportSuccess => 'एक्सपोर्ट शेयर करने के लिए तैयार है।';

  @override
  String get unlockTitle => 'WarrantyVault लॉक है';

  @override
  String get unlockButton => 'अनलॉक करें';

  @override
  String get unlockReason => 'अपने बिल देखने के लिए प्रमाणित करें';

  @override
  String get cloudBackupTitle => 'क्लाउड बैकअप';

  @override
  String get familyVaultTitle => 'फैमिली वॉल्ट';

  @override
  String get upgradeToPro => 'प्रो में अपग्रेड करें';

  @override
  String get localOnlyBadge => '100% आपके फ़ोन पर • निजी';
}
