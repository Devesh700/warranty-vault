import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/analytics_service.dart';
import '../../core/constants.dart';
import '../../core/date_logic.dart';
import '../../core/firebase_sync_service.dart';
import '../../core/l10n_helpers.dart';
import '../../core/media_service.dart';
import '../../core/notification_service.dart';
import '../../core/ocr_parser.dart';
import '../../core/subscription_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/local_image.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/providers.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/generated/app_localizations.dart';
import 'add_source_sheet.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({
    super.key,
    this.editItemId,
    this.resumeDraft = false,
    this.launchArgs,
  });

  final String? editItemId;
  final bool resumeDraft;
  final AddItemLaunchArgs? launchArgs;

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  ItemCategory _category = ItemCategory.other;
  DateTime _purchaseDate = dateOnly(DateTime.now());
  int _warrantyMonths = 12;
  bool _isLifetime = false;
  DateTime? _extendedEndDate;

  final List<({AttachmentType type, String path})> _pendingAttachments = [];
  OcrParseResult? _ocrResult;
  bool _showOcrWarning = false;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadError;
  WarrantyItem? _existingItem;
  WarrantyItem? _savedItem;

  bool get _isEditMode => widget.editItemId != null;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final repo = ref.read(warrantyRepositoryProvider);
    if (_isEditMode) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
      try {
        final item = await repo.getItem(widget.editItemId!);
        if (!mounted) return;
        if (item == null) {
          setState(() {
            _isLoading = false;
            _loadError = 'Item not found';
          });
          return;
        }
        _existingItem = item;
        _nameCtrl.text = item.name;
        _brandCtrl.text = item.brand ?? '';
        _priceCtrl.text = item.price != null ? item.price.toString() : '';
        _storeCtrl.text = item.storeName ?? '';
        _modelCtrl.text = item.model ?? '';
        _serialCtrl.text = item.serialNumber ?? '';
        _notesCtrl.text = item.notes ?? '';
        _category = item.category;
        _purchaseDate = dateOnly(item.purchaseDate);
        _warrantyMonths = item.warrantyMonths;
        _isLifetime = item.isLifetime;
        _extendedEndDate = item.extendedWarrantyEndDate;
        setState(() => _isLoading = false);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _loadError = e.toString();
        });
      }
      return;
    }

    if (widget.launchArgs != null) {
      final args = widget.launchArgs!;
      _pendingAttachments.addAll(args.attachments);
      _ocrResult = args.ocrResult;
      _showOcrWarning = args.ocrWarning;
      final ocr = args.ocrResult;
      if (ocr != null) {
        if (ocr.productName != null) {
          _nameCtrl.text = ocr.productName!.value;
        }
        if (ocr.brand != null) {
          _brandCtrl.text = ocr.brand!.value;
        }
        if (ocr.category != null) {
          _category = ocr.category!.value;
        }
        if (ocr.purchaseDate != null) {
          _purchaseDate = dateOnly(ocr.purchaseDate!.value);
        }
        if (ocr.totalAmount != null) {
          final amt = ocr.totalAmount!.value;
          _priceCtrl.text =
              amt % 1 == 0 ? amt.toStringAsFixed(0) : amt.toStringAsFixed(2);
        }
        if (ocr.storeName != null) {
          _storeCtrl.text = ocr.storeName!.value;
        }
      }
      setState(() {});
      return;
    }

    if (widget.resumeDraft) {
      final draft = await repo.getValidDraft(AppLimits.draftRetention);
      if (draft != null && mounted) {
        _nameCtrl.text = draft['name'] as String? ?? '';
        _brandCtrl.text = draft['brand'] as String? ?? '';
        _priceCtrl.text = draft['price'] as String? ?? '';
        _storeCtrl.text = draft['store'] as String? ?? '';
        _modelCtrl.text = draft['model'] as String? ?? '';
        _serialCtrl.text = draft['serial'] as String? ?? '';
        _notesCtrl.text = draft['notes'] as String? ?? '';
        final catName = draft['category'] as String?;
        if (catName != null) {
          _category = ItemCategory.values.firstWhere(
            (c) => c.name == catName,
            orElse: () => ItemCategory.other,
          );
        }
        final dateStr = draft['purchaseDate'] as String?;
        if (dateStr != null) {
          final parsed = DateTime.tryParse(dateStr);
          if (parsed != null) _purchaseDate = dateOnly(parsed);
        }
        _warrantyMonths = draft['warrantyMonths'] as int? ?? 12;
        _isLifetime = draft['isLifetime'] as bool? ?? false;
        setState(() {});
      }
    }
  }

  void _saveDraftIfNeeded() {
    if (_isEditMode || _savedItem != null) return;
    final hasAnyInput = _nameCtrl.text.trim().isNotEmpty ||
        _brandCtrl.text.trim().isNotEmpty ||
        _storeCtrl.text.trim().isNotEmpty ||
        _priceCtrl.text.trim().isNotEmpty;
    if (!hasAnyInput) return;

    ref.read(warrantyRepositoryProvider).saveDraft({
      'name': _nameCtrl.text,
      'brand': _brandCtrl.text,
      'price': _priceCtrl.text,
      'store': _storeCtrl.text,
      'model': _modelCtrl.text,
      'serial': _serialCtrl.text,
      'notes': _notesCtrl.text,
      'category': _category.name,
      'purchaseDate': _purchaseDate.toIso8601String(),
      'warrantyMonths': _warrantyMonths,
      'isLifetime': _isLifetime,
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _priceCtrl.dispose();
    _storeCtrl.dispose();
    _modelCtrl.dispose();
    _serialCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  WarrantyItem _buildPreviewItem(String currency) {
    final now = DateTime.now();
    final endDate = computeWarrantyEndDate(_purchaseDate, _warrantyMonths);
    return WarrantyItem(
      id: _existingItem?.id ?? 'preview',
      name: _nameCtrl.text.trim().isEmpty ? 'Item' : _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      model: _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
      serialNumber:
          _serialCtrl.text.trim().isEmpty ? null : _serialCtrl.text.trim(),
      category: _category,
      purchaseDate: _purchaseDate,
      price: double.tryParse(_priceCtrl.text.trim()),
      currency: _existingItem?.currency ?? currency,
      storeName: _storeCtrl.text.trim().isEmpty ? null : _storeCtrl.text.trim(),
      warrantyMonths: _isLifetime ? 0 : _warrantyMonths,
      warrantyEndDate: endDate,
      extendedWarrantyEndDate: _extendedEndDate,
      isLifetime: _isLifetime,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: _existingItem?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _pickPurchaseDate() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate.isAfter(today) ? today : _purchaseDate,
      firstDate: DateTime(1990),
      lastDate: today,
    );
    if (picked != null && mounted) {
      setState(() {
        _purchaseDate = dateOnly(picked);
      });
      _saveDraftIfNeeded();
    }
  }

  Future<void> _addAnotherPhoto() async {
    final l10n = AppLocalizations.of(context);
    final chosenType = await showModalBottomSheet<AttachmentType>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                l10n.chooseAttachmentType,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: Text(l10n.attachmentWarrantyCard),
              onTap: () => Navigator.of(ctx).pop(AttachmentType.warrantyCard),
            ),
            ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: Text(l10n.attachmentProductPhoto),
              onTap: () => Navigator.of(ctx).pop(AttachmentType.productPhoto),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_outlined),
              title: Text(l10n.attachmentBill),
              onTap: () => Navigator.of(ctx).pop(AttachmentType.bill),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_rounded),
              title: Text(l10n.attachmentOther),
              onTap: () => Navigator.of(ctx).pop(AttachmentType.other),
            ),
          ],
        ),
      ),
    );
    if (!mounted || chosenType == null) return;

    final source = await showModalBottomSheet<CaptureSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.sourceScanBill),
              onTap: () => Navigator.of(ctx).pop(CaptureSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.sourceChoosePhoto),
              onTap: () => Navigator.of(ctx).pop(CaptureSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;

    try {
      final media = ref.read(mediaServiceProvider);
      final rawPicked = await media.pickSourceFile(source);
      if (!mounted || rawPicked == null) return;
      final settings = await ref.read(warrantyRepositoryProvider).getSettings();
      final savedPath = await media.compressAndSaveSource(
        rawPicked,
        keepUnmodifiedCopy: settings.keepUnmodifiedCopy,
      );
      if (!mounted) return;
      setState(() {
        _pendingAttachments.add((type: chosenType, path: savedPath));
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.storageError)),
      );
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final today = dateOnly(DateTime.now());
    if (_purchaseDate.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.futureDateError)),
      );
      return;
    }

    if (!_isEditMode && !ref.read(isProProvider)) {
      final count = await ref.read(warrantyRepositoryProvider).getItemCount();
      if (!mounted) return;
      if (count >= AppLimits.freeTierItemLimit) {
        await context.push('/paywall?trigger=item_limit');
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final locale = Localizations.localeOf(context);
      final currency =
          _existingItem?.currency ?? defaultCurrencyFromLocale(locale);
      final now = DateTime.now();
      final months = _isLifetime ? 0 : _warrantyMonths;
      final endDate = computeWarrantyEndDate(_purchaseDate, months);
      const uuid = Uuid();
      final itemId = _existingItem?.id ?? uuid.v4();

      final item = WarrantyItem(
        id: itemId,
        name: _nameCtrl.text.trim(),
        brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        model: _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
        serialNumber:
            _serialCtrl.text.trim().isEmpty ? null : _serialCtrl.text.trim(),
        category: _category,
        purchaseDate: _purchaseDate,
        price: _priceCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_priceCtrl.text.trim()),
        currency: currency,
        storeName:
            _storeCtrl.text.trim().isEmpty ? null : _storeCtrl.text.trim(),
        warrantyMonths: months,
        warrantyEndDate: endDate,
        extendedWarrantyEndDate: _extendedEndDate,
        isLifetime: _isLifetime,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: _existingItem?.createdAt ?? now,
        updatedAt: now,
      );

      final repo = ref.read(warrantyRepositoryProvider);
      final fbSync = ref.read(firebaseSyncServiceProvider);
      await repo.upsertItem(item);
      final savedAttachments = <ItemAttachment>[];
      for (final att in _pendingAttachments) {
        final itemAtt = ItemAttachment(
          id: uuid.v4(),
          itemId: itemId,
          type: att.type,
          localPath: att.path,
          createdAt: now,
        );
        await repo.addAttachment(itemAtt);
        savedAttachments.add(itemAtt);
      }

      final settings = await repo.getSettings();
      await ref
          .read(notificationServiceProvider)
          .syncRemindersForItem(item, settings, l10n);
      final plans = computeReminderPlansForItem(item, settings);

      if (fbSync.isReady) {
        await fbSync.syncItem(item);
        for (final att in savedAttachments) {
          await fbSync.syncAttachment(att);
        }
        final rems = await repo.getRemindersForItem(item.id);
        await fbSync.syncRemindersForItem(item.id, rems);
      }

      final analytics = ref.read(analyticsServiceProvider);
      analytics.itemSaved(
        category: item.category.name,
        usedOcr: _ocrResult != null,
      );
      if (plans.isNotEmpty) {
        analytics.reminderScheduled(count: plans.length);
      }

      if (!_isEditMode) {
        await repo.clearDraft();
      }

      if (!mounted) return;
      if (_isEditMode) {
        context.pop();
      } else {
        setState(() {
          _isSaving = false;
          _savedItem = item;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.genericErrorHeadline}: $e')),
      );
    }
  }

  void _resetForAnother({required bool reuseBill}) {
    _nameCtrl.clear();
    _modelCtrl.clear();
    _serialCtrl.clear();
    _notesCtrl.clear();
    if (!reuseBill) {
      _brandCtrl.clear();
      _priceCtrl.clear();
      _storeCtrl.clear();
      _pendingAttachments.clear();
      _purchaseDate = dateOnly(DateTime.now());
    } else {
      // Keep bill image, purchase date, and store for another item on the same bill
      _brandCtrl.clear();
      _priceCtrl.clear();
      final billOnly = _pendingAttachments
          .where((a) => a.type == AttachmentType.bill)
          .toList();
      _pendingAttachments
        ..clear()
        ..addAll(billOnly);
    }
    setState(() {
      _category = ItemCategory.other;
      _warrantyMonths = 12;
      _isLifetime = false;
      _extendedEndDate = null;
      _ocrResult = null;
      _showOcrWarning = false;
      _savedItem = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? l10n.editItem : l10n.addItem),
        ),
        body: const AppLoadingView(),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? l10n.editItem : l10n.addItem),
        ),
        body: AppErrorView(
          headline: l10n.itemNotFound,
          details: _loadError,
          onRetry: _initData,
        ),
      );
    }

    if (_savedItem != null) {
      final hasBillAttachment =
          _pendingAttachments.any((a) => a.type == AttachmentType.bill);
      return _SavedSuccessView(
        item: _savedItem!,
        hasBillAttachment: hasBillAttachment,
        onViewItem: () => context.pushReplacement('/item/${_savedItem!.id}'),
        onAddAnother: () => _resetForAnother(reuseBill: false),
        onAddAnotherFromBill: hasBillAttachment
            ? () => _resetForAnother(reuseBill: true)
            : null,
        onDone: () => context.pop(),
      );
    }

    final currency = defaultCurrencyFromLocale(Localizations.localeOf(context));
    final previewItem = _buildPreviewItem(currency);
    final previewStatus = computeWarrantyStatus(previewItem);
    final hasExpandedDetails =
        _modelCtrl.text.isNotEmpty || _serialCtrl.text.isNotEmpty;
    final isDark = theme.brightness == Brightness.dark;
    final warningColor = isDark ? AppColors.warningDarkMode : AppColors.warning;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.editItem : l10n.addItem),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            if (_showOcrWarning) ...[
              Card(
                color: warningColor.withValues(alpha: 0.14),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: warningColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.ocrNoTextWarning,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Live warranty preview card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CategoryIconBadge(category: _category),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.warrantyPreviewTitle,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            previewStatus == WarrantyStatus.lifetime
                                ? l10n.statusLifetime
                                : previewStatus == WarrantyStatus.noWarranty
                                    ? l10n.statusNoWarranty
                                    : l10n.warrantyEndsOn(
                                        formatShortDate(
                                          context,
                                          previewItem.effectiveEndDate,
                                        ),
                                      ),
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    StatusChip(status: previewStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Attached thumbnails strip
            if (_pendingAttachments.isNotEmpty) ...[
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pendingAttachments.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) {
                    final att = _pendingAttachments[i];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LocalImage(
                            pathOrUri: att.path,
                            width: 84,
                            height: 92,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () {
                              setState(() => _pendingAttachments.removeAt(i));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // 1. Product name
            AppTextField(
              controller: _nameCtrl,
              label: '${l10n.fieldProductName} *',
              hint: l10n.fieldProductNameHint,
              textInputAction: TextInputAction.next,
              isAutoFilled: _ocrResult?.productName != null,
              isLowConfidence:
                  _ocrResult?.productName?.isLowConfidence ?? false,
              autoFilledLabel: l10n.autoFilledTag,
              onChanged: (_) {
                setState(() {});
                _saveDraftIfNeeded();
              },
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.fieldProductNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. Brand
            AppTextField(
              controller: _brandCtrl,
              label: l10n.fieldBrand,
              hint: l10n.fieldBrandHint,
              textInputAction: TextInputAction.next,
              isAutoFilled: _ocrResult?.brand != null,
              isLowConfidence: _ocrResult?.brand?.isLowConfidence ?? false,
              autoFilledLabel: l10n.autoFilledTag,
              onChanged: (_) => _saveDraftIfNeeded(),
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Category icon picker
            Text(
              l10n.fieldCategory,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ItemCategory.values.map((cat) {
                final selected = cat == _category;
                return ChoiceChip(
                  avatar: Icon(
                    categoryIconData(cat),
                    size: 18,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodySmall?.color,
                  ),
                  label: Text(cat.label(l10n)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _category = cat);
                    _saveDraftIfNeeded();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            // 4. Purchase date
            _DateSelectorTile(
              label: '${l10n.fieldPurchaseDate} *',
              dateText: formatShortDate(context, _purchaseDate),
              isAutoFilled: _ocrResult?.purchaseDate != null,
              isLowConfidence:
                  _ocrResult?.purchaseDate?.isLowConfidence ?? false,
              autoFilledLabel: l10n.autoFilledTag,
              onTap: _pickPurchaseDate,
            ),
            const SizedBox(height: AppSpacing.md),

            // 5. Warranty period + Lifetime switch
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.fieldWarrantyPeriod,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (!_isLifetime)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Decrease warranty months',
                                onPressed: _warrantyMonths > 0
                                    ? () {
                                        setState(() => _warrantyMonths--);
                                        _saveDraftIfNeeded();
                                      }
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                '$_warrantyMonths',
                                style: theme.textTheme.titleMedium,
                              ),
                              IconButton(
                                tooltip: 'Increase warranty months',
                                onPressed: () {
                                  setState(() => _warrantyMonths++);
                                  _saveDraftIfNeeded();
                                },
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (!_isLifetime) ...[
                      Text(
                        l10n.monthsCount(_warrantyMonths),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [0, 6, 12, 24, 36].map((m) {
                          return ChoiceChip(
                            label: Text(m == 0 ? '0m' : '${m}m'),
                            selected: _warrantyMonths == m,
                            onSelected: (_) {
                              setState(() => _warrantyMonths = m);
                              _saveDraftIfNeeded();
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const Divider(height: 20),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.lifetimeWarranty),
                      value: _isLifetime,
                      onChanged: (v) {
                        setState(() => _isLifetime = v);
                        _saveDraftIfNeeded();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 6. Price
            AppTextField(
              controller: _priceCtrl,
              label: l10n.fieldPrice,
              hint: l10n.fieldPriceHint,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              prefixText: '$currency ',
              isAutoFilled: _ocrResult?.totalAmount != null,
              isLowConfidence:
                  _ocrResult?.totalAmount?.isLowConfidence ?? false,
              autoFilledLabel: l10n.autoFilledTag,
              onChanged: (_) => _saveDraftIfNeeded(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final parsed = double.tryParse(v.trim());
                if (parsed == null || parsed < 0) {
                  return l10n.invalidPriceError;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // 7. Store
            AppTextField(
              controller: _storeCtrl,
              label: l10n.fieldStore,
              hint: l10n.fieldStoreHint,
              textInputAction: TextInputAction.next,
              isAutoFilled: _ocrResult?.storeName != null,
              isLowConfidence: _ocrResult?.storeName?.isLowConfidence ?? false,
              autoFilledLabel: l10n.autoFilledTag,
              onChanged: (_) => _saveDraftIfNeeded(),
            ),
            const SizedBox(height: AppSpacing.md),

            // 8. Model and serial number (collapsed under "More details")
            Card(
              child: ExpansionTile(
                title: Text(
                  l10n.moreDetails,
                  style: theme.textTheme.titleMedium,
                ),
                initiallyExpanded: hasExpandedDetails,
                childrenPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                children: [
                  AppTextField(
                    controller: _modelCtrl,
                    label: l10n.fieldModel,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _saveDraftIfNeeded(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _serialCtrl,
                    label: l10n.fieldSerialNumber,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _saveDraftIfNeeded(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 9. Notes
            AppTextField(
              controller: _notesCtrl,
              label: l10n.fieldNotes,
              hint: l10n.fieldNotesHint,
              maxLines: 3,
              onChanged: (_) => _saveDraftIfNeeded(),
            ),
            const SizedBox(height: AppSpacing.lg),

            PrimaryButton(
              label: l10n.save,
              isLoading: _isSaving,
              onPressed: _save,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: l10n.addAnotherPhoto,
              icon: Icons.add_a_photo_outlined,
              onPressed: _addAnotherPhoto,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          ),
        ),
      ),
    );
  }
}

class _DateSelectorTile extends StatelessWidget {
  const _DateSelectorTile({
    required this.label,
    required this.dateText,
    required this.onTap,
    this.isAutoFilled = false,
    this.isLowConfidence = false,
    this.autoFilledLabel,
  });

  final String label;
  final String dateText;
  final VoidCallback onTap;
  final bool isAutoFilled;
  final bool isLowConfidence;
  final String? autoFilledLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final warningColor = isDark ? AppColors.warningDarkMode : AppColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isAutoFilled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isLowConfidence
                          ? warningColor
                          : theme.colorScheme.primary)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  autoFilledLabel ?? 'auto-filled',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isLowConfidence
                        ? warningColor
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              border: Border.all(
                color:
                    isLowConfidence ? warningColor : theme.colorScheme.outline,
                width: isLowConfidence ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dateText,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedSuccessView extends StatelessWidget {
  const _SavedSuccessView({
    required this.item,
    required this.hasBillAttachment,
    required this.onViewItem,
    required this.onAddAnother,
    this.onAddAnotherFromBill,
    required this.onDone,
  });

  final WarrantyItem item;
  final bool hasBillAttachment;
  final VoidCallback onViewItem;
  final VoidCallback onAddAnother;
  final VoidCallback? onAddAnotherFromBill;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = computeWarrantyStatus(item);
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? AppColors.successDarkMode : AppColors.success;

    final reminderSubtitle =
        (status == WarrantyStatus.lifetime || status == WarrantyStatus.noWarranty)
            ? l10n.noRemindersNeeded
            : l10n.remindersSetFor(
                formatShortDate(context, item.effectiveEndDate),
              );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onDone,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: successColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 48,
                    color: successColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.itemSavedTitle,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  reminderSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: l10n.viewItem,
                  onPressed: onViewItem,
                ),
                if (hasBillAttachment && onAddAnotherFromBill != null) ...[
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: l10n.addAnotherFromBill,
                    onPressed: onAddAnotherFromBill,
                  ),
                ],
                const SizedBox(height: 12),
                SecondaryButton(
                  label: l10n.addAnother,
                  onPressed: onAddAnother,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
