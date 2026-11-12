import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_vault/core/analytics_service.dart';

void main() {
  test('AnalyticsService logs all 12 Section 11 events without PII', () {
    final sink = InMemoryAnalyticsSink();
    final analytics = AnalyticsService(sink: sink);

    analytics.onboardingCompleted();
    analytics.itemAddStarted(source: 'camera');
    analytics.ocrCompleted(durationMs: 420, fieldsFilled: 4);
    analytics.itemSaved(category: 'phone', usedOcr: true);
    analytics.reminderScheduled(count: 3);
    analytics.brokeHelpOpened(inWarranty: true);
    analytics.claimBundleShared();
    analytics.paywallViewed(trigger: 'item_limit');
    analytics.purchaseStarted(plan: 'yearly');
    analytics.purchaseCompleted(plan: 'yearly');
    analytics.restoreTapped();
    analytics.exportUsed();

    expect(
      sink.events.map((e) => e.name).toList(),
      [
        'onboarding_completed',
        'item_add_started',
        'ocr_completed',
        'item_saved',
        'reminder_scheduled',
        'broke_help_opened',
        'claim_bundle_shared',
        'paywall_viewed',
        'purchase_started',
        'purchase_completed',
        'restore_tapped',
        'export_used',
      ],
    );
    expect(sink.events[1].properties, {'source': 'camera'});
    expect(
      sink.events[2].properties,
      {'duration_ms': 420, 'fields_filled': 4},
    );
  });
}
