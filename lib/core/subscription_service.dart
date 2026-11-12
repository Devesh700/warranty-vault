import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../data/providers.dart';
import '../data/repositories/warranty_repository.dart';
import 'env_config.dart';

enum SubscriptionPlan { yearly, monthly }

class PlanOfferingInfo {
  const PlanOfferingInfo({
    required this.plan,
    required this.productId,
    required this.priceString,
    required this.hasFreeTrial,
    this.package,
  });

  final SubscriptionPlan plan;
  final String productId;
  final String? priceString;
  final bool hasFreeTrial;
  final Package? package;
}

class SubscriptionStateInfo {
  const SubscriptionStateInfo({
    required this.isConfigured,
    required this.yearly,
    required this.monthly,
  });

  final bool isConfigured;
  final PlanOfferingInfo yearly;
  final PlanOfferingInfo monthly;
}

enum PurchaseOutcome { success, cancelled, notConfigured, failed }

class SubscriptionService {
  SubscriptionService(this._repo);

  final WarrantyRepository _repo;

  static const String entitlementPro = 'pro';
  static const String yearlyProductId = 'wv_yearly';
  static const String monthlyProductId = 'wv_monthly';

  bool _configured = false;

  bool get isConfigured => _configured;

  Future<void> initialize() async {
    if (_configured || kIsWeb) return;
    final apiKey = defaultTargetPlatform == TargetPlatform.android
        ? EnvConfig.rcAndroidKey
        : (defaultTargetPlatform == TargetPlatform.iOS
            ? EnvConfig.rcIosKey
            : '');
    if (apiKey.isEmpty) {
      return;
    }

    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _configured = true;
      await refreshEntitlement();
    } catch (_) {
      // Remain offline-safe with cached entitlement
    }
  }

  Future<bool> refreshEntitlement() async {
    if (!_configured) {
      final settings = await _repo.getSettings();
      return settings.isProCached;
    }
    try {
      final info = await Purchases.getCustomerInfo();
      final active = info.entitlements.active.containsKey(entitlementPro);
      await _repo.updateSetting('isProCached', active.toString());
      return active;
    } catch (_) {
      final settings = await _repo.getSettings();
      return settings.isProCached;
    }
  }

  Future<SubscriptionStateInfo> loadOfferings() async {
    if (!_configured) {
      return const SubscriptionStateInfo(
        isConfigured: false,
        yearly: PlanOfferingInfo(
          plan: SubscriptionPlan.yearly,
          productId: yearlyProductId,
          priceString: null,
          hasFreeTrial: false,
        ),
        monthly: PlanOfferingInfo(
          plan: SubscriptionPlan.monthly,
          productId: monthlyProductId,
          priceString: null,
          hasFreeTrial: false,
        ),
      );
    }

    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      Package? yearlyPkg = current?.annual;
      Package? monthlyPkg = current?.monthly;

      if (current != null) {
        for (final pkg in current.availablePackages) {
          if (pkg.storeProduct.identifier == yearlyProductId) {
            yearlyPkg = pkg;
          } else if (pkg.storeProduct.identifier == monthlyProductId) {
            monthlyPkg = pkg;
          }
        }
      }

      return SubscriptionStateInfo(
        isConfigured: true,
        yearly: PlanOfferingInfo(
          plan: SubscriptionPlan.yearly,
          productId: yearlyProductId,
          priceString: yearlyPkg?.storeProduct.priceString,
          hasFreeTrial: yearlyPkg?.storeProduct.introductoryPrice != null,
          package: yearlyPkg,
        ),
        monthly: PlanOfferingInfo(
          plan: SubscriptionPlan.monthly,
          productId: monthlyProductId,
          priceString: monthlyPkg?.storeProduct.priceString,
          hasFreeTrial: monthlyPkg?.storeProduct.introductoryPrice != null,
          package: monthlyPkg,
        ),
      );
    } catch (_) {
      return const SubscriptionStateInfo(
        isConfigured: true,
        yearly: PlanOfferingInfo(
          plan: SubscriptionPlan.yearly,
          productId: yearlyProductId,
          priceString: null,
          hasFreeTrial: false,
        ),
        monthly: PlanOfferingInfo(
          plan: SubscriptionPlan.monthly,
          productId: monthlyProductId,
          priceString: null,
          hasFreeTrial: false,
        ),
      );
    }
  }

  Future<PurchaseOutcome> purchase(PlanOfferingInfo planInfo) async {
    if (!_configured || planInfo.package == null) {
      return PurchaseOutcome.notConfigured;
    }
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(planInfo.package!),
      );
      final active =
          result.customerInfo.entitlements.active.containsKey(entitlementPro);
      await _repo.updateSetting('isProCached', active.toString());
      return active ? PurchaseOutcome.success : PurchaseOutcome.failed;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      return PurchaseOutcome.failed;
    } catch (_) {
      return PurchaseOutcome.failed;
    }
  }

  Future<bool> restorePurchases() async {
    if (!_configured) {
      final settings = await _repo.getSettings();
      return settings.isProCached;
    }
    try {
      final info = await Purchases.restorePurchases();
      final active = info.entitlements.active.containsKey(entitlementPro);
      await _repo.updateSetting('isProCached', active.toString());
      return active;
    } catch (_) {
      return false;
    }
  }
}

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(ref.watch(warrantyRepositoryProvider));
});

final isProProvider = Provider<bool>((ref) {
  return ref.watch(settingsStreamProvider).value?.isProCached ?? false;
});
