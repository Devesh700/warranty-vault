import 'package:material_ui/material_ui.dart';

import '../../core/constants.dart';
import '../../l10n/generated/app_localizations.dart';

enum LegalDocType { privacy, terms }

class LegalScreen extends StatelessWidget {
  const LegalScreen({
    super.key,
    required this.type,
  });

  final LegalDocType type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isPrivacy = type == LegalDocType.privacy;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPrivacy ? l10n.privacyPolicy : l10n.termsOfService),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          isPrivacy ? _privacyText : _termsText,
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}

const String _privacyText = '''
WarrantyVault Privacy Policy (v1.0)

1. Local-First Storage
All purchase items, warranty dates, notes, and bill images stored in WarrantyVault v1 remain exclusively on your device. No account is required, and no bill image or item content is uploaded to external servers.

2. On-Device OCR
Text recognition runs completely on your device using on-device models. Your receipts never leave your phone for OCR processing.

3. Notifications
Warranty expiry reminders are scheduled locally on your device.

4. Your Control
You can export all your items and bill images at any time as a ZIP archive from Settings -> Export all data, or permanently erase everything using Settings -> Delete all data.

5. Subscriptions & Diagnostics
Subscription purchases and entitlements are handled through Google Play / Apple App Store via RevenueCat. Minimal non-personal diagnostic and event metrics help keep the app reliable.
''';

const String _termsText = '''
WarrantyVault Terms of Service (v1.0)

1. Service Overview
WarrantyVault helps you organize purchase bills, track warranty periods, receive local expiry reminders, and generate claim bundles.

2. Brand Contact Directory
Brand service numbers, websites, and claim tips are provided for convenience. Please verify contact details directly with the manufacturer before calling or visiting a service center.

3. Subscriptions
- Free plan allows storing up to 5 items.
- WarrantyVault Pro (wv_yearly / wv_monthly) unlocks unlimited items.
- Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period via your Google Play or App Store account settings.
- If a subscription lapses, your existing items remain safely accessible on your device; you simply cannot add new items beyond the free limit until you renew.

4. Liability
WarrantyVault is a personal record-keeping assistant and does not guarantee manufacturer warranty coverage.
''';
