import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics_service.dart';
import '../../core/brand_contacts_service.dart';
import '../../core/claim_bundle_service.dart';
import '../../core/constants.dart';
import '../../core/date_logic.dart';
import '../../core/l10n_helpers.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/state_views.dart';
import '../../data/providers.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/generated/app_localizations.dart';

class BrokeHelpScreen extends ConsumerStatefulWidget {
  const BrokeHelpScreen({
    super.key,
    required this.itemId,
  });

  final String itemId;

  @override
  ConsumerState<BrokeHelpScreen> createState() => _BrokeHelpScreenState();
}

class _BrokeHelpScreenState extends ConsumerState<BrokeHelpScreen> {
  bool _sharingPdf = false;
  bool _openedLogged = false;
  BrandContact? _overrideContact;

  Future<void> _callNumber(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    await launchUrl(uri);
  }

  Future<void> _openWebsite(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareBundle(
    WarrantyItem item,
    List<ItemAttachment> attachments,
  ) async {
    setState(() => _sharingPdf = true);
    try {
      await ref.read(claimBundleServiceProvider).shareClaimBundle(
            item: item,
            attachments: attachments,
          );
      ref.read(analyticsServiceProvider).claimBundleShared();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _sharingPdf = false);
    }
  }

  Future<void> _browseBrands() async {
    final contacts = await ref.read(brandContactsServiceProvider).loadAll();
    if (!mounted) return;

    final chosen = await showModalBottomSheet<BrandContact>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => ListView.separated(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: contacts.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (_, idx) {
            final c = contacts[idx];
            return ListTile(
              title: Text(c.brand),
              subtitle: Text(c.serviceNumber),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(ctx).pop(c),
            );
          },
        ),
      ),
    );

    if (chosen != null && mounted) {
      setState(() => _overrideContact = chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final itemAsync = ref.watch(itemDetailStreamProvider(widget.itemId));
    final attachments =
        ref.watch(itemAttachmentsStreamProvider(widget.itemId)).value ??
            const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.somethingBroke)),
      body: itemAsync.when(
        loading: () => const AppLoadingView(),
        error: (_, _) => AppErrorView(
          onRetry: () => ref.invalidate(itemDetailStreamProvider(widget.itemId)),
        ),
        data: (item) {
          if (item == null) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              headline: l10n.itemNotFound,
              helpText: l10n.emptyFilteredHelp,
            );
          }

          final status = computeWarrantyStatus(item);
          final isDark = theme.brightness == Brightness.dark;
          final isExpired = status == WarrantyStatus.expired;
          final isUnderWarranty = status == WarrantyStatus.active ||
              status == WarrantyStatus.expiringSoon ||
              status == WarrantyStatus.lifetime;

          if (!_openedLogged) {
            _openedLogged = true;
            ref
                .read(analyticsServiceProvider)
                .brokeHelpOpened(inWarranty: isUnderWarranty);
          }

          final Color bannerColor;
          final String bannerTitle;
          final String? bannerSubtitle;
          switch (status) {
            case WarrantyStatus.active:
            case WarrantyStatus.expiringSoon:
              bannerColor =
                  isDark ? AppColors.successDarkMode : AppColors.success;
              bannerTitle = l10n.underWarrantyUntil(
                formatShortDate(context, item.effectiveEndDate),
              );
              bannerSubtitle = null;
            case WarrantyStatus.lifetime:
              bannerColor =
                  isDark ? AppColors.successDarkMode : AppColors.success;
              bannerTitle = l10n.lifetimeWarrantyBanner;
              bannerSubtitle = null;
            case WarrantyStatus.expired:
              bannerColor =
                  isDark ? AppColors.dangerDarkMode : AppColors.danger;
              bannerTitle = l10n.warrantyExpiredBanner;
              bannerSubtitle = l10n.goodwillRepairNote;
            case WarrantyStatus.noWarranty:
              bannerColor = isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight;
              bannerTitle = l10n.noWarrantyBanner;
              bannerSubtitle = l10n.goodwillRepairNote;
          }

          return FutureBuilder<BrandContact?>(
            future: ref.read(brandContactsServiceProvider).findForItem(item),
            builder: (ctx, snap) {
              final contact = _overrideContact ?? snap.data;

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // 1. Status Banner
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: bannerColor.withValues(alpha: isDark ? 0.20 : 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      border: Border.all(
                        color: bannerColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isUnderWarranty
                              ? Icons.verified_user_rounded
                              : Icons.info_outline_rounded,
                          color: bannerColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bannerTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: bannerColor,
                                ),
                              ),
                              if (bannerSubtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  bannerSubtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 2. Brand Service Card
                  SectionHeader(title: l10n.brandServiceTitle),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: contact != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        contact.brand,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _browseBrands,
                                      child: Text(l10n.chooseBrandContact),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                PrimaryButton(
                                  label: l10n.callSupport(contact.serviceNumber),
                                  icon: Icons.call_rounded,
                                  onPressed: () =>
                                      _callNumber(contact.serviceNumber),
                                ),
                                const SizedBox(height: 10),
                                SecondaryButton(
                                  label: l10n.visitWebsite,
                                  icon: Icons.open_in_new_rounded,
                                  onPressed: () =>
                                      _openWebsite(contact.website),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.claimTipsLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  contact.claimTips,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  l10n.verifyContactDisclaimer,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.noBrandMatchHelp,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                SecondaryButton(
                                  label: l10n.chooseBrandContact,
                                  icon: Icons.search_rounded,
                                  onPressed: _browseBrands,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 3. Share claim bundle PDF
                  PrimaryButton(
                    label:
                        _sharingPdf ? l10n.generatingPdf : l10n.shareClaimBundle,
                    icon: Icons.picture_as_pdf_outlined,
                    isLoading: _sharingPdf,
                    onPressed: () => _shareBundle(item, attachments),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 4. Checklist
                  SectionHeader(title: l10n.claimChecklistTitle),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          _ChecklistRow(text: l10n.checklistBillSerial),
                          const SizedBox(height: 10),
                          _ChecklistRow(text: l10n.checklistIssuePhoto),
                        ],
                      ),
                    ),
                  ),

                  // 5. Expired affiliate soft offer (v1 disabled link)
                  if (isExpired) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
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
                            const SizedBox(height: 8),
                            Text(
                              l10n.compareRepairPlans,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.affiliatePlaceholderNote,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            SecondaryButton(
                              label:
                                  '${l10n.compareRepairPlans} (${l10n.comingSoon})',
                              onPressed: null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
