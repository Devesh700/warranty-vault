import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/date_logic.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/item_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/state_views.dart';
import '../../data/providers.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/generated/app_localizations.dart';

class ExpiringScreen extends ConsumerWidget {
  const ExpiringScreen({super.key});

  void _showExtendWarrantySheet(BuildContext context, WarrantyItem item) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.sponsoredLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.extendYourWarranty(item.name),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.affiliatePlaceholderNote,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 20),
            SecondaryButton(
              label: '${l10n.extendWarranty} (${l10n.comingSoon})',
              onPressed: null,
            ),
            const SizedBox(height: 8),
            Center(
              child: TextLinkButton(
                label: l10n.close,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final itemsAsync = ref.watch(itemsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabExpiring),
      ),
      body: itemsAsync.when(
        loading: () => const AppLoadingView(),
        error: (err, _) => AppErrorView(
          onRetry: () => ref.invalidate(itemsStreamProvider),
        ),
        data: (items) {
          final thisWeek = <WarrantyItem>[];
          final thisMonth = <WarrantyItem>[];
          final next3Months = <WarrantyItem>[];

          for (final item in items) {
            final status = computeWarrantyStatus(item);
            if (status == WarrantyStatus.lifetime ||
                status == WarrantyStatus.noWarranty ||
                status == WarrantyStatus.expired) {
              continue;
            }
            final days = daysRemainingForItem(item);
            if (days < 0 || days > AppLimits.expiringTabDays) continue;

            if (days <= 7) {
              thisWeek.add(item);
            } else if (days <= 30) {
              thisMonth.add(item);
            } else {
              next3Months.add(item);
            }
          }

          if (thisWeek.isEmpty && thisMonth.isEmpty && next3Months.isEmpty) {
            return EmptyState(
              icon: Icons.verified_user_outlined,
              headline: l10n.emptyExpiringHeadline,
              helpText: l10n.emptyExpiringHelp,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (thisWeek.isNotEmpty) ...[
                SectionHeader(title: l10n.thisWeek),
                ...thisWeek.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ExpiringCard(
                        item: item,
                        onTap: () => context.push('/item/${item.id}'),
                        onExtend: () => _showExtendWarrantySheet(context, item),
                      ),
                    )),
              ],
              if (thisMonth.isNotEmpty) ...[
                SectionHeader(title: l10n.thisMonth),
                ...thisMonth.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ExpiringCard(
                        item: item,
                        onTap: () => context.push('/item/${item.id}'),
                        onExtend: () => _showExtendWarrantySheet(context, item),
                      ),
                    )),
              ],
              if (next3Months.isNotEmpty) ...[
                SectionHeader(title: l10n.next3Months),
                ...next3Months.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ExpiringCard(
                        item: item,
                        onTap: () => context.push('/item/${item.id}'),
                        onExtend: () => _showExtendWarrantySheet(context, item),
                      ),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ExpiringCard extends StatelessWidget {
  const _ExpiringCard({
    required this.item,
    required this.onTap,
    required this.onExtend,
  });

  final WarrantyItem item;
  final VoidCallback onTap;
  final VoidCallback onExtend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ItemCard(
      item: item,
      onTap: onTap,
      trailingAction: TextButton(
        onPressed: onExtend,
        child: Text(l10n.extendWarranty),
      ),
    );
  }
}
