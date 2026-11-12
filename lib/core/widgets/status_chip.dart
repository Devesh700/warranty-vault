import 'package:flutter/material.dart';

import '../../domain/enums.dart';
import '../../l10n/generated/app_localizations.dart';
import '../constants.dart';
import '../l10n_helpers.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
  });

  final WarrantyStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color color;
    switch (status) {
      case WarrantyStatus.active:
      case WarrantyStatus.lifetime:
        color = isDark ? AppColors.successDarkMode : AppColors.success;
      case WarrantyStatus.expiringSoon:
        color = isDark ? AppColors.warningDarkMode : AppColors.warning;
      case WarrantyStatus.expired:
        color = isDark ? AppColors.dangerDarkMode : AppColors.danger;
      case WarrantyStatus.noWarranty:
        color = isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label(l10n),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
