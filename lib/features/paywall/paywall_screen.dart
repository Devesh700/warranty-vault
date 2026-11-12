import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics_service.dart';
import '../../core/constants.dart';
import '../../core/subscription_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/warranty_vault_logo.dart';
import '../../l10n/generated/app_localizations.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({
    super.key,
    this.trigger = 'general',
  });

  final String trigger;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  SubscriptionPlan _selectedPlan = SubscriptionPlan.yearly;
  SubscriptionStateInfo? _offerings;
  bool _loadingOfferings = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsServiceProvider).paywallViewed(trigger: widget.trigger);
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final info = await ref.read(subscriptionServiceProvider).loadOfferings();
    if (mounted) {
      setState(() {
        _offerings = info;
        _loadingOfferings = false;
      });
    }
  }

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context);
    final info = _offerings;
    if (info == null) return;
    final selectedInfo =
        _selectedPlan == SubscriptionPlan.yearly ? info.yearly : info.monthly;
    final analytics = ref.read(analyticsServiceProvider);
    analytics.purchaseStarted(plan: _selectedPlan.name);

    setState(() => _busy = true);
    final outcome =
        await ref.read(subscriptionServiceProvider).purchase(selectedInfo);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (outcome) {
      case PurchaseOutcome.success:
        analytics.purchaseCompleted(plan: _selectedPlan.name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.purchaseSuccess)),
        );
        context.pop(true);
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.notConfigured:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.purchaseNotConfigured)),
        );
      case PurchaseOutcome.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.genericErrorHeadline)),
        );
    }
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context);
    ref.read(analyticsServiceProvider).restoreTapped();
    setState(() => _busy = true);
    final restored =
        await ref.read(subscriptionServiceProvider).restorePurchases();
    if (!mounted) return;
    setState(() => _busy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored ? l10n.purchaseRestored : l10n.noActiveSubscription,
        ),
      ),
    );
    if (restored) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final yearly = _offerings?.yearly;
    final monthly = _offerings?.monthly;
    final activeOffering =
        _selectedPlan == SubscriptionPlan.yearly ? yearly : monthly;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.close,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: WarrantyVaultLogo(size: 72),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.paywallHeadline,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4 benefit rows
              _BenefitRow(
                icon: Icons.all_inclusive_rounded,
                text: l10n.paywallBenefitUnlimited,
              ),
              const SizedBox(height: 12),
              _BenefitRow(
                icon: Icons.cloud_done_outlined,
                text: l10n.paywallBenefitBackup,
                badge: l10n.comingSoon,
              ),
              const SizedBox(height: 12),
              _BenefitRow(
                icon: Icons.family_restroom_rounded,
                text: l10n.paywallBenefitFamily,
                badge: l10n.comingSoon,
              ),
              const SizedBox(height: 12),
              _BenefitRow(
                icon: Icons.support_agent_rounded,
                text: l10n.paywallBenefitSupport,
              ),
              const SizedBox(height: AppSpacing.lg),

              if (_loadingOfferings)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                _PlanTile(
                  title: l10n.planYearly,
                  price: yearly?.priceString ?? '—',
                  badge: l10n.bestValue,
                  selected: _selectedPlan == SubscriptionPlan.yearly,
                  onTap: () =>
                      setState(() => _selectedPlan = SubscriptionPlan.yearly),
                ),
                const SizedBox(height: 10),
                _PlanTile(
                  title: l10n.planMonthly,
                  price: monthly?.priceString ?? '—',
                  selected: _selectedPlan == SubscriptionPlan.monthly,
                  onTap: () =>
                      setState(() => _selectedPlan = SubscriptionPlan.monthly),
                ),
                if (activeOffering?.hasFreeTrial == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    l10n.freeTrial7Days,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (activeOffering?.priceString == null) ...[
                  const SizedBox(height: 10),
                  Text(
                    l10n.priceUnavailableOffline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.lg),

              PrimaryButton(
                label: l10n.continueButton,
                isLoading: _busy,
                onPressed: _loadingOfferings ? null : _continue,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextLinkButton(
                  label: l10n.restorePurchases,
                  onPressed: _busy ? null : _restore,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => context.push('/legal/terms'),
                    child: Text(
                      l10n.termsOfService,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const Text('•'),
                  TextButton(
                    onPressed: () => context.push('/legal/privacy'),
                    child: Text(
                      l10n.privacyPolicy,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.text,
    this.badge,
  });

  final IconData icon;
  final String text;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: theme.textTheme.bodyLarge),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(title, style: theme.textTheme.titleMedium),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
