import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/date_logic.dart';
import '../../core/fcm_service.dart';
import '../../core/firebase_sync_service.dart';
import '../../core/l10n_helpers.dart';
import '../../core/notification_service.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/item_card.dart';
import '../../core/widgets/state_views.dart';
import '../../data/providers.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/generated/app_localizations.dart';

enum StatusFilter { all, active, expiringSoon, expired }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.onAddPressed,
  });

  final VoidCallback onAddPressed;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;
  String _query = '';
  StatusFilter _statusFilter = StatusFilter.all;
  ItemCategory? _categoryFilter;
  bool _hasDraft = false;
  bool _notificationsDenied = false;
  bool _notifBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _checkDraft();
    _checkNotificationPermission();
  }

  Future<void> _checkDraft() async {
    final draft = await ref
        .read(warrantyRepositoryProvider)
        .getValidDraft(AppLimits.draftRetention);
    if (mounted) {
      setState(() => _hasDraft = draft != null);
    }
  }

  Future<void> _checkNotificationPermission() async {
    if (kIsWeb) {
      final fcmStatus = ref.read(fcmServiceProvider).statusNotifier.value;
      if (mounted) {
        setState(() {
          _notificationsDenied =
              fcmStatus.isSupported && !fcmStatus.isAuthorized;
        });
      }
      return;
    }
    final enabled =
        await ref.read(notificationServiceProvider).areNotificationsEnabled();
    if (mounted) {
      setState(() => _notificationsDenied = !enabled);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<WarrantyItem> _filterAndSort(List<WarrantyItem> items) {
    final q = _query.trim().toLowerCase();
    final filtered = items.where((item) {
      if (q.isNotEmpty) {
        final matches = item.name.toLowerCase().contains(q) ||
            (item.brand?.toLowerCase().contains(q) ?? false) ||
            (item.storeName?.toLowerCase().contains(q) ?? false) ||
            (item.model?.toLowerCase().contains(q) ?? false);
        if (!matches) return false;
      }

      if (_categoryFilter != null && item.category != _categoryFilter) {
        return false;
      }

      final status = computeWarrantyStatus(item);
      switch (_statusFilter) {
        case StatusFilter.all:
          return true;
        case StatusFilter.active:
          return status == WarrantyStatus.active ||
              status == WarrantyStatus.lifetime;
        case StatusFilter.expiringSoon:
          return status == WarrantyStatus.expiringSoon;
        case StatusFilter.expired:
          return status == WarrantyStatus.expired;
      }
    }).toList();

    filtered.sort((a, b) {
      final sa = computeWarrantyStatus(a);
      final sb = computeWarrantyStatus(b);

      int bucket(WarrantyStatus s) {
        switch (s) {
          case WarrantyStatus.expiringSoon:
          case WarrantyStatus.active:
            return 0;
          case WarrantyStatus.lifetime:
            return 1;
          case WarrantyStatus.noWarranty:
            return 2;
          case WarrantyStatus.expired:
            return 3;
        }
      }

      final ba = bucket(sa);
      final bb = bucket(sb);
      if (ba != bb) return ba.compareTo(bb);

      if (ba == 0) {
        return a.effectiveEndDate.compareTo(b.effectiveEndDate);
      }
      if (ba == 3) {
        // Most recently expired first
        return b.effectiveEndDate.compareTo(a.effectiveEndDate);
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filtered;
  }

  Future<void> _deleteWithUndo(WarrantyItem item) async {
    final repo = ref.read(warrantyRepositoryProvider);
    final notifs = ref.read(notificationServiceProvider);
    final fbSync = ref.read(firebaseSyncServiceProvider);
    final l10n = AppLocalizations.of(context);
    final attachments = await repo.getAttachmentsForItem(item.id);
    await notifs.cancelRemindersForItem(item.id);
    await repo.deleteItem(item.id);
    await fbSync.deleteItemRemote(item.id);

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.deleteItemUndo(item.name)),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () async {
            await repo.restoreItemWithRelations(
              item: item,
              attachments: attachments,
            );
            final settings = await repo.getSettings();
            await notifs.syncRemindersForItem(item, settings, l10n);
            await fbSync.syncItem(item);
            for (final att in attachments) {
              await fbSync.syncAttachment(att);
            }
            final rems = await repo.getRemindersForItem(item.id);
            await fbSync.syncRemindersForItem(item.id, rems);
          },
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _searchCtrl.clear();
      _statusFilter = StatusFilter.all;
      _categoryFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(itemsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            tooltip: l10n.searchHint,
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _query = '';
                  _searchCtrl.clear();
                }
              });
            },
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const AppLoadingView(),
        error: (err, _) => AppErrorView(
          onRetry: () => ref.invalidate(itemsStreamProvider),
        ),
        data: (items) {
          final expiringCount = items
              .where((i) => computeWarrantyStatus(i) == WarrantyStatus.expiringSoon)
              .length;
          final filtered = _filterAndSort(items);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),

              if (_notificationsDenied && !_notifBannerDismissed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Card(
                    color: AppColors.warning.withValues(alpha: 0.14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications_off_outlined,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.notifPermissionDeniedBanner,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              bool granted;
                              if (kIsWeb) {
                                granted = await ref
                                    .read(fcmServiceProvider)
                                    .requestPermissionAndRegister();
                              } else {
                                final notifs =
                                    ref.read(notificationServiceProvider);
                                granted = await notifs.requestPermission();
                                if (granted && context.mounted) {
                                  await notifs.rescheduleAll(l10n);
                                }
                              }
                              if (mounted) {
                                setState(() => _notificationsDenied = !granted);
                              }
                            },
                            child: Text(l10n.enable),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () =>
                                setState(() => _notifBannerDismissed = true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (_hasDraft)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.resumeDraftMessage,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await ref
                                  .read(warrantyRepositoryProvider)
                                  .clearDraft();
                              if (mounted) setState(() => _hasDraft = false);
                            },
                            child: Text(l10n.discard),
                          ),
                          TextButton(
                            onPressed: () async {
                              await context.push('/add?draft=1');
                              _checkDraft();
                            },
                            child: Text(l10n.resumeDraft),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (items.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    l10n.itemsSummary(items.length, expiringCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FilterChipItem(
                        label: l10n.filterAll,
                        selected: _statusFilter == StatusFilter.all &&
                            _categoryFilter == null,
                        onSelected: _clearFilters,
                      ),
                      const SizedBox(width: 8),
                      _FilterChipItem(
                        label: l10n.statusActive,
                        selected: _statusFilter == StatusFilter.active,
                        onSelected: () => setState(() {
                          _statusFilter = _statusFilter == StatusFilter.active
                              ? StatusFilter.all
                              : StatusFilter.active;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipItem(
                        label: l10n.statusExpiringSoon,
                        selected: _statusFilter == StatusFilter.expiringSoon,
                        onSelected: () => setState(() {
                          _statusFilter =
                              _statusFilter == StatusFilter.expiringSoon
                                  ? StatusFilter.all
                                  : StatusFilter.expiringSoon;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipItem(
                        label: l10n.statusExpired,
                        selected: _statusFilter == StatusFilter.expired,
                        onSelected: () => setState(() {
                          _statusFilter = _statusFilter == StatusFilter.expired
                              ? StatusFilter.all
                              : StatusFilter.expired;
                        }),
                      ),
                      ...ItemCategory.values.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChipItem(
                            label: cat.label(l10n),
                            selected: _categoryFilter == cat,
                            onSelected: () => setState(() {
                              _categoryFilter =
                                  _categoryFilter == cat ? null : cat;
                            }),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              Expanded(
                child: items.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_rounded,
                        headline: l10n.emptyItemsHeadline,
                        helpText: l10n.emptyItemsHelp,
                        buttonLabel: l10n.addItem,
                        onAction: widget.onAddPressed,
                      )
                    : filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.filter_list_off_rounded,
                            headline: l10n.emptyFilteredHeadline,
                            helpText: l10n.emptyFilteredHelp,
                            buttonLabel: l10n.clearFilters,
                            onAction: _clearFilters,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return Dismissible(
                                key: ValueKey(item.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.cardRadius,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (_) => _deleteWithUndo(item),
                                child: ItemCard(
                                  item: item,
                                  onTap: () =>
                                      context.push('/item/${item.id}'),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
