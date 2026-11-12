import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics_service.dart';
import '../../core/constants.dart';
import '../../core/media_service.dart';
import '../../core/ocr_parser.dart';
import '../../core/subscription_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../data/providers.dart';
import '../../domain/enums.dart';
import '../../l10n/generated/app_localizations.dart';

class AddItemLaunchArgs {
  const AddItemLaunchArgs({
    this.ocrResult,
    this.attachments = const [],
    this.ocrWarning = false,
  });

  final OcrParseResult? ocrResult;
  final List<({AttachmentType type, String path})> attachments;
  final bool ocrWarning;
}

Future<void> showAddItemSourceSheet(BuildContext context) async {
  final container = ProviderScope.containerOf(context);
  final isPro = container.read(isProProvider);
  if (!isPro) {
    final count = await container.read(warrantyRepositoryProvider).getItemCount();
    if (!context.mounted) return;
    if (count >= AppLimits.freeTierItemLimit) {
      await context.push('/paywall?trigger=item_limit');
      return;
    }
  }

  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);

  final selection = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                l10n.addSourceTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(l10n.sourceScanBill),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(l10n.sourceChoosePhoto),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            ListTile(
              leading: Icon(
                Icons.picture_as_pdf_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(l10n.sourceImportPdf),
              onTap: () => Navigator.of(ctx).pop('pdf'),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: theme.colorScheme.onSurface,
              ),
              title: Text(l10n.sourceEnterManually),
              onTap: () => Navigator.of(ctx).pop('manual'),
            ),
          ],
        ),
      ),
    ),
  );

  if (!context.mounted || selection == null) return;

  container.read(analyticsServiceProvider).itemAddStarted(source: selection);

  if (selection == 'manual') {
    context.push('/add');
    return;
  }

  final source = switch (selection) {
    'camera' => CaptureSource.camera,
    'gallery' => CaptureSource.gallery,
    'pdf' => CaptureSource.pdf,
    _ => CaptureSource.gallery,
  };

  final media = ProviderScope.containerOf(context).read(mediaServiceProvider);
  final picked = await media.pickSourceFile(source);
  if (!context.mounted || picked == null) return;

  final cropped = await media.cropImage(
    picked,
    primaryColor: theme.colorScheme.primary,
  );
  if (!context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BillCapturePreviewScreen(
        pickedSource: cropped,
        source: source,
      ),
    ),
  );
}

class BillCapturePreviewScreen extends ConsumerStatefulWidget {
  const BillCapturePreviewScreen({
    super.key,
    required this.pickedSource,
    required this.source,
  });

  final PickedBillSource pickedSource;
  final CaptureSource source;

  @override
  ConsumerState<BillCapturePreviewScreen> createState() =>
      _BillCapturePreviewScreenState();
}

class _BillCapturePreviewScreenState
    extends ConsumerState<BillCapturePreviewScreen> {
  late PickedBillSource _currentSource;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentSource = widget.pickedSource;
  }

  Future<void> _retake() async {
    final media = ref.read(mediaServiceProvider);
    final newPicked = await media.pickSourceFile(widget.source);
    if (!mounted || newPicked == null) return;
    final cropped = await media.cropImage(
      newPicked,
      primaryColor: Theme.of(context).colorScheme.primary,
    );
    if (!mounted) return;
    setState(() => _currentSource = cropped);
  }

  Future<void> _useThis() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isProcessing = true);
    try {
      final settings = await ref.read(warrantyRepositoryProvider).getSettings();
      final media = ref.read(mediaServiceProvider);
      final processed = await media.processAndRecognize(
        _currentSource,
        keepUnmodifiedCopy: settings.keepUnmodifiedCopy,
      );
      ref.read(analyticsServiceProvider).ocrCompleted(
            durationMs: processed.ocrDurationMs,
            fieldsFilled: processed.ocrResult.fieldsFilledCount,
          );
      if (!mounted) return;
      context.pushReplacement(
        '/add',
        extra: AddItemLaunchArgs(
          ocrResult: processed.ocrResult,
          attachments: [
            (type: AttachmentType.bill, path: processed.savedImagePath),
          ],
          ocrWarning: processed.ocrResult.isEmpty,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.storageError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewBillImage)),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.scanningBill, style: theme.textTheme.titleMedium),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      child: InteractiveViewer(
                        child: Image.memory(
                          _currentSource.bytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: l10n.retake,
                            onPressed: _retake,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrimaryButton(
                            label: l10n.useThis,
                            onPressed: _useThis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
