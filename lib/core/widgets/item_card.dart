import 'package:flutter/material.dart';

import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../constants.dart';
import '../date_logic.dart';
import '../l10n_helpers.dart';
import 'category_icon.dart';
import 'status_chip.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.trailingAction,
  });

  final WarrantyItem item;
  final VoidCallback? onTap;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final status = computeWarrantyStatus(item);
    final daysLeft = daysRemainingForItem(item);

    final String subtitleRight;
    switch (status) {
      case WarrantyStatus.lifetime:
        subtitleRight = l10n.statusLifetime;
      case WarrantyStatus.noWarranty:
        subtitleRight = l10n.statusNoWarranty;
      case WarrantyStatus.expired:
        subtitleRight = l10n.expiredDaysAgo(daysLeft.abs());
      case WarrantyStatus.active:
      case WarrantyStatus.expiringSoon:
        subtitleRight = l10n.daysLeft(daysLeft);
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryIconBadge(category: item.category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (item.brand != null &&
                                item.brand!.trim().isNotEmpty)
                              item.brand!.trim(),
                            item.category.label(l10n),
                          ].join(' • '),
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      subtitleRight,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: status == WarrantyStatus.expired
                            ? theme.colorScheme.error
                            : null,
                      ),
                    ),
                  ),
                  ?trailingAction,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
