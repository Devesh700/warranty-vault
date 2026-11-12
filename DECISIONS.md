# WarrantyVault — Architectural & Implementation Decisions

This file records choices made where the build spec left implementation details unspecified, as well as deferred items.

## Milestone 1: Foundation
1. **Localization output directory**: Configured `l10n.yaml` with `output-dir: lib/l10n/generated` and `nullable-getter: false` so generated `AppLocalizations` is cleanly importable from `package:warranty_vault/l10n/generated/app_localizations.dart` without relying on synthetic packages.
2. **Typography & Offline Font Loading**: Used `google_fonts` for `Inter` (English/Latin) and `Noto Sans Devanagari` (Hindi). In tests, `GoogleFonts.config.allowRuntimeFetching = false` is set to ensure offline determinism with system font fallback.
3. **Drift Database & Riverpod**: Used `drift` with `sqlite3_flutter_libs` (and `NativeDatabase.memory()` in unit/widget tests). Riverpod (`flutter_riverpod` v3) manages reactive streams from Drift DAOs (`watchAllItems`, `watchSettings`).
4. **GoRouter Shell Navigation**: Used `StatefulShellRoute.indexedStack` for the 3 bottom tabs (`Items`, `Expiring`, `Settings`) with a central floating `+` Add button on Items and Expiring tabs.
5. **Settings Storage**: Stored settings in a Drift key-value `AppSettings` table so all app data lives in a single transactional SQLite database that is easy to export and wipe cleanly.
6. **Item Drafts**: Stored draft JSON in `AppSettings` under `itemDraft` with a 24-hour retention timestamp to satisfy Section 13 ("App killed mid-add: keep a draft for 24 hours and offer 'Resume draft'").

## Milestone 2: Core Vertical Slice
7. **Form Keep-Alive**: Used `SingleChildScrollView` + `Column` in `AddItemScreen` rather than a lazy `ListView` so every `FormField` remains mounted during validation regardless of scroll position.

## Milestone 3: Capture and OCR
8. **Desktop / Platform Fallback for Crop & Compression**: `ImageCropper` and `FlutterImageCompress` gracefully fall back to copying/using the source image when running on platforms without native crop/compress channels (e.g. unit/widget tests or desktop).
9. **On-Device OCR**: `google_mlkit_text_recognition` runs locally on device, and `OcrParser` parses dates (`dd/mm/yyyy`, `dd-mm-yyyy`, `dd MMM yyyy`, ISO), totals, store names, brands, and categories with explicit `high`/`low` confidence flags.

## Milestone 4: Reminders and Help
10. **Inexact Scheduled Alarms on Android**: Used `AndroidScheduleMode.inexactAllowWhileIdle` with `RECEIVE_BOOT_COMPLETED` and `ScheduledNotificationBootReceiver` so warranty reminders reschedule cleanly on device reboot and app resume without requiring Google Play special `SCHEDULE_EXACT_ALARM` permission declarations.
11. **Bundled Brand Directory**: Seeded `assets/data/brand_contacts.json` with 30 major electronics, appliance, audio, and two-wheeler brands, always displaying the "Verify contact details with the brand before calling" disclaimer.

## Milestone 5: Monetization and Polish
12. **RevenueCat Offline Resilience**: `SubscriptionService` initializes `purchases_flutter` using `--dart-define=RC_ANDROID_KEY=...` and `--dart-define=RC_IOS_KEY=...`. If keys are absent in local/dev builds or the device is offline, it safely falls back to the locally cached `isProCached` entitlement flag in Drift and never crashes.
13. **CSV Export Serializer**: Implemented an RFC-4180 CSV serializer directly inside `ExportService` alongside `archive` (`ZipEncoder`) to avoid unnecessary extra package dependencies.
14. **Affiliate Links (v1)**: Extended warranty offers on the Expiring tab and Broke Help screen are labeled "Sponsored" with disabled buttons until partner links are configured in remote config (Section 10).

## Milestone 6: Release Prep
15. **Analytics & Crash Reporting Facades**: Implemented `AnalyticsService` (all 12 Section 11 events with zero PII) and `CrashReporter` (`FlutterError.onError` + `PlatformDispatcher.instance.onError`) as clean facades without hard-requiring `google-services.json` / `GoogleService-Info.plist` so local/offline builds and CI pass out of the box. Connect Firebase Analytics & Firebase Crashlytics sinks when provisioning store release credentials.
16. **Milestone 7 Deferred**: Cloud sync and family vault are explicitly deferred until post-launch per Sections 3 and 12.

## Web (Chrome) & Firebase + `.env` Additions
17. **Web Drift SQLite (`wasm`)**: Split `lib/data/database.dart` via conditional imports (`connection_native.dart` vs `connection_web.dart` using `WasmDatabase.open`) and added `web/sqlite3.wasm` and `web/drift_worker.js` so Drift persists in browser IndexedDB/OPFS without pulling `dart:ffi`.
18. **Cross-Platform Media & File Abstraction**: Replaced direct `dart:io` `File` / `Image.file` calls with `LocalFileStore` and `LocalImage` (data URIs / network URLs on Web, documents directory files on IO).
19. **Environment Secrets via `.env`**: Added `flutter_dotenv` with `.env.example` (tracked) and `.env` (gitignored) supplying Firebase (`FIREBASE_*`) and RevenueCat (`RC_*`) keys via `EnvConfig`.
20. **Firebase Storage & Sync**: Added `FirebaseSyncService` (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`) syncing items, attachments/images, reminders, and settings under `users/{uid}/` with `latest updatedAt wins` conflict resolution, while continuing to work offline when keys are absent.
