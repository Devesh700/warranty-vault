import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics_service.dart';
import '../../core/constants.dart';
import '../../core/fcm_service.dart';
import '../../core/notification_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/warranty_vault_logo.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool requestNotifications}) async {
    if (requestNotifications) {
      await ref.read(notificationServiceProvider).requestPermission();
      await ref.read(fcmServiceProvider).requestPermissionAndRegister();
    }
    await ref
        .read(warrantyRepositoryProvider)
        .updateSetting('onboardingDone', 'true');
    ref.read(analyticsServiceProvider).onboardingCompleted();
    if (mounted) {
      context.go('/items');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final pages = [
      (
        icon: Icons.document_scanner_rounded,
        title: l10n.onboardingTitle1,
        body: l10n.onboardingBody1,
        extra: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            l10n.localOnlyBadge,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      (
        icon: Icons.notifications_active_rounded,
        title: l10n.onboardingTitle2,
        body: l10n.onboardingBody2,
        extra: Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(
                Icons.shield_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(l10n.appName),
            subtitle: Text(l10n.notif30Days('Samsung TV')),
          ),
        ),
      ),
      (
        icon: Icons.build_circle_rounded,
        title: l10n.onboardingTitle3,
        body: l10n.onboardingBody3,
        extra: Text(
          l10n.onboardingNotificationReason,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_page < 2)
            TextButton(
              onPressed: () => _finish(requestNotifications: false),
              child: Text(l10n.skip),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (ctx, i) {
                  final p = pages[i];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        if (i == 0)
                          const WarrantyVaultLogo(size: 104)
                        else
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              p.icon,
                              size: 56,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          p.body,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        p.extra,
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: _page == 2 ? l10n.getStarted : l10n.next,
                    onPressed: () {
                      if (_page < 2) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      } else {
                        _finish(requestNotifications: true);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
