import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/date_logic.dart';
import '../../core/firebase_sync_service.dart';
import '../../core/l10n_helpers.dart';
import '../../core/local_file_store.dart';
import '../../core/notification_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/info_row.dart';
import '../../core/widgets/local_image.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/providers.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/generated/app_localizations.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({
    super.key,
    required this.itemId,
  });

  final String itemId;

  Future<void> _addExtendedWarranty(
    BuildContext context,
    WidgetRef ref,
    WarrantyItem item,
  ) async {
    final l10n = AppLocalizations.of(context);
    final initial = item.extendedWarrantyEndDate ??
        item.warrantyEndDate.add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: item.purchaseDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final updated = item.copyWith(
        extendedWarrantyEndDate: dateOnly(picked),
        updatedAt: DateTime.now(),
      );
      final repo = ref.read(warrantyRepositoryProvider);
      await repo.upsertItem(updated);
      final settings = await repo.getSettings();
      await ref
          .read(notificationServiceProvider)
          .syncRemindersForItem(updated, settings, l10n);
      final fbSync = ref.read(firebaseSyncServiceProvider);
      await fbSync.syncItem(updated);
      final rems = await repo.getRemindersForItem(updated.id);
      await fbSync.syncRemindersForItem(updated.id, rems);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    WarrantyItem item,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteBody(item.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repo = ref.read(warrantyRepositoryProvider);
      final atts = await repo.getAttachmentsForItem(item.id);
      await ref
          .read(notificationServiceProvider)
          .cancelRemindersForItem(item.id);
      await repo.deleteItem(item.id);
      for (final att in atts) {
        if (!att.localPath.startsWith('http')) {
          await LocalFileStore.deleteFile(att.localPath);
        }
      }
      await ref.read(firebaseSyncServiceProvider).deleteItemRemote(item.id);
      if (context.mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final itemAsync = ref.watch(itemDetailStreamProvider(itemId));
    final attachmentsAsync = ref.watch(itemAttachmentsStreamProvider(itemId));

    return itemAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const AppLoadingView(),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: AppErrorView(
          onRetry: () => ref.invalidate(itemDetailStreamProvider(itemId)),
        ),
      ),
      data: (item) {
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: EmptyState(
              icon: Icons.search_off_rounded,
              headline: l10n.itemNotFound,
              helpText: l10n.emptyFilteredHelp,
            ),
          );
        }

        final status = computeWarrantyStatus(item);
        final daysLeft = daysRemainingForItem(item);
        final progress = warrantyProgressUsed(item);
        final isDark = theme.brightness == Brightness.dark;

        final Color ringColor;
        final String centerText;
        switch (status) {
          case WarrantyStatus.active:
            ringColor = isDark ? AppColors.successDarkMode : AppColors.success;
            centerText = l10n.daysLeft(daysLeft);
          case WarrantyStatus.lifetime:
            ringColor = isDark ? AppColors.successDarkMode : AppColors.success;
            centerText = l10n.statusLifetime;
          case WarrantyStatus.expiringSoon:
            ringColor = isDark ? AppColors.warningDarkMode : AppColors.warning;
            centerText = l10n.daysLeft(daysLeft);
          case WarrantyStatus.expired:
            ringColor = isDark ? AppColors.dangerDarkMode : AppColors.danger;
            centerText = l10n.expiredDaysAgo(daysLeft.abs());
          case WarrantyStatus.noWarranty:
            ringColor = isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight;
            centerText = l10n.statusNoWarranty;
        }

        final attachments = attachmentsAsync.value ?? const [];

        return Scaffold(
          appBar: AppBar(
            actions: [
              PopupMenuButton<String>(
                onSelected: (action) {
                  switch (action) {
                    case 'edit':
                      context.push('/edit/${item.id}');
                    case 'extend':
                      _addExtendedWarranty(context, ref, item);
                    case 'delete':
                      _confirmDelete(context, ref, item);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(l10n.edit),
                  ),
                  PopupMenuItem(
                    value: 'extend',
                    child: Text(l10n.addExtendedWarranty),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      l10n.delete,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryIconBadge(category: item.category, size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (item.brand != null &&
                                item.brand!.trim().isNotEmpty)
                              item.brand!.trim(),
                            item.category.label(l10n),
                          ].join(' • '),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: status),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Progress Ring
              Center(
                child: ProgressRing(
                  progress: progress,
                  color: ringColor,
                  centerText: centerText,
                  subtitle: status == WarrantyStatus.lifetime ||
                          status == WarrantyStatus.noWarranty
                      ? null
                      : formatShortDate(context, item.effectiveEndDate),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Bill image carousel (if attachments exist)
              if (attachments.isNotEmpty) ...[
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: attachments.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (ctx, idx) {
                      final att = attachments[idx];
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _AttachmentViewerPage(
                                attachments: attachments,
                                initialIndex: idx,
                              ),
                            ),
                          );
                        },
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          child: Container(
                            width: 140,
                            color: theme.colorScheme.surface,
                            child: LocalImage(
                              pathOrUri: att.localPath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      InfoRow(
                        label: l10n.fieldPurchaseDate,
                        value: formatShortDate(context, item.purchaseDate),
                      ),
                      const Divider(),
                      InfoRow(
                        label: l10n.fieldWarrantyPeriod,
                        value: item.isLifetime
                            ? l10n.statusLifetime
                            : l10n.monthsCount(item.warrantyMonths),
                      ),
                      if (!item.isLifetime && item.warrantyMonths > 0) ...[
                        const Divider(),
                        InfoRow(
                          label: l10n.warrantyEndsOn('').replaceAll(': ', '').trim(),
                          value: formatShortDate(context, item.warrantyEndDate),
                        ),
                      ],
                      if (item.extendedWarrantyEndDate != null) ...[
                        const Divider(),
                        InfoRow(
                          label: l10n.extendedWarrantyEndLabel,
                          value: formatShortDate(
                            context,
                            item.extendedWarrantyEndDate!,
                          ),
                        ),
                      ],
                      if (item.price != null) ...[
                        const Divider(),
                        InfoRow(
                          label: l10n.fieldPrice.replaceAll(' (optional)', ''),
                          value: formatCurrencyAmount(
                            context,
                            item.price!,
                            item.currency,
                          ),
                        ),
                      ],
                      if (item.storeName != null &&
                          item.storeName!.isNotEmpty) ...[
                        const Divider(),
                        InfoRow(
                          label: l10n.fieldStore,
                          value: item.storeName!,
                        ),
                      ],
                      if (item.model != null && item.model!.isNotEmpty) ...[
                        const Divider(),
                        InfoRow(
                          label: l10n.fieldModel,
                          value: item.model!,
                        ),
                      ],
                      if (item.serialNumber != null &&
                          item.serialNumber!.isNotEmpty) ...[
                        const Divider(),
                        InfoRow(
                          label: l10n.fieldSerialNumber,
                          value: item.serialNumber!,
                        ),
                      ],
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const Divider(),
                        InfoRow(
                          label: l10n.fieldNotes,
                          value: item.notes!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Red-outlined "Something broke?" button
              SecondaryButton(
                label: l10n.somethingBroke,
                icon: Icons.build_circle_outlined,
                borderColor:
                    isDark ? AppColors.dangerDarkMode : AppColors.danger,
                foregroundColor:
                    isDark ? AppColors.dangerDarkMode : AppColors.danger,
                onPressed: () => context.push('/broke-help/${item.id}'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }
}

class _AttachmentViewerPage extends StatefulWidget {
  const _AttachmentViewerPage({
    required this.attachments,
    required this.initialIndex,
  });

  final List<ItemAttachment> attachments;
  final int initialIndex;

  @override
  State<_AttachmentViewerPage> createState() => _AttachmentViewerPageState();
}

class _AttachmentViewerPageState extends State<_AttachmentViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareCurrent() async {
    final att = widget.attachments[_currentIndex];
    await LocalFileStore.shareStoredPath(att.localPath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.attachments.length}'),
        actions: [
          IconButton(
            tooltip: l10n.share,
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareCurrent,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.attachments.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (ctx, i) {
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: LocalImage(
                pathOrUri: widget.attachments[i].localPath,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
