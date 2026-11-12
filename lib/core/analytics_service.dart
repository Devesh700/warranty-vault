import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsEvent {
  const AnalyticsEvent(this.name, [this.properties = const {}]);

  final String name;
  final Map<String, Object> properties;
}

abstract class AnalyticsSink {
  void record(AnalyticsEvent event);
}

class InMemoryAnalyticsSink implements AnalyticsSink {
  final List<AnalyticsEvent> events = [];

  @override
  void record(AnalyticsEvent event) {
    events.add(event);
  }
}

/// Logs Section 11 funnel & product events with minimal non-PII properties.
/// Swap or attach a Firebase Analytics / PostHog sink once project keys are added.
class AnalyticsService {
  AnalyticsService({this.sink});

  final AnalyticsSink? sink;

  void _log(String name, [Map<String, Object> props = const {}]) {
    final event = AnalyticsEvent(name, props);
    sink?.record(event);
    if (kDebugMode && sink == null) {
      debugPrint('[Analytics] $name $props');
    }
  }

  void onboardingCompleted() => _log('onboarding_completed');

  void itemAddStarted({required String source}) =>
      _log('item_add_started', {'source': source});

  void ocrCompleted({required int durationMs, required int fieldsFilled}) =>
      _log('ocr_completed', {
        'duration_ms': durationMs,
        'fields_filled': fieldsFilled,
      });

  void itemSaved({required String category, required bool usedOcr}) =>
      _log('item_saved', {
        'category': category,
        'used_ocr': usedOcr,
      });

  void reminderScheduled({required int count}) =>
      _log('reminder_scheduled', {'count': count});

  void brokeHelpOpened({required bool inWarranty}) =>
      _log('broke_help_opened', {'in_warranty': inWarranty});

  void claimBundleShared() => _log('claim_bundle_shared');

  void paywallViewed({required String trigger}) =>
      _log('paywall_viewed', {'trigger': trigger});

  void purchaseStarted({required String plan}) =>
      _log('purchase_started', {'plan': plan});

  void purchaseCompleted({required String plan}) =>
      _log('purchase_completed', {'plan': plan});

  void restoreTapped() => _log('restore_tapped');

  void exportUsed() => _log('export_used');
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
