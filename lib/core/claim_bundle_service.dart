import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/enums.dart';
import '../domain/models.dart';
import 'date_logic.dart';
import 'local_file_store.dart';

class ClaimBundleService {
  Future<Uint8List> buildClaimPdfBytes({
    required WarrantyItem item,
    required List<ItemAttachment> attachments,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('d MMM yyyy');
    final status = computeWarrantyStatus(item);

    final statusText = switch (status) {
      WarrantyStatus.active => 'Active',
      WarrantyStatus.expiringSoon => 'Expiring Soon',
      WarrantyStatus.expired => 'Expired',
      WarrantyStatus.noWarranty => 'No warranty',
      WarrantyStatus.lifetime => 'Lifetime warranty',
    };

    final rows = <(String, String)>[
      ('Product', item.name),
      if (item.brand != null && item.brand!.isNotEmpty) ('Brand', item.brand!),
      ('Category', item.category.name),
      ('Purchase Date', dateFmt.format(item.purchaseDate)),
      (
        'Warranty End Date',
        item.isLifetime
            ? 'Lifetime'
            : (item.warrantyMonths == 0 && item.extendedWarrantyEndDate == null)
                ? 'No warranty'
                : dateFmt.format(item.effectiveEndDate),
      ),
      ('Status', statusText),
      if (item.price != null)
        ('Price', '${item.currency} ${item.price!.toStringAsFixed(2)}'),
      if (item.storeName != null && item.storeName!.isNotEmpty)
        ('Store', item.storeName!),
      if (item.model != null && item.model!.isNotEmpty) ('Model', item.model!),
      if (item.serialNumber != null && item.serialNumber!.isNotEmpty)
        ('Serial / IMEI', item.serialNumber!),
      if (item.notes != null && item.notes!.isNotEmpty) ('Notes', item.notes!),
    ];

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'WarrantyVault - Warranty Claim Bundle',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Generated on ${dateFmt.format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Divider(height: 24),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(4),
                },
                children: rows.map((row) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          row.$1,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          row.$2,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    for (final att in attachments) {
      try {
        final bytes = await LocalFileStore.readBytes(att.localPath);
        if (bytes == null || bytes.isEmpty) continue;
        final image = pw.MemoryImage(bytes);
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            build: (pw.Context ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Attachment: ${att.type.name}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        );
      } catch (_) {
        // Skip unreadable image gracefully
      }
    }

    return doc.save();
  }

  Future<void> shareClaimBundle({
    required WarrantyItem item,
    required List<ItemAttachment> attachments,
  }) async {
    final pdfBytes = await buildClaimPdfBytes(
      item: item,
      attachments: attachments,
    );
    final safeName =
        item.name.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_').toLowerCase();
    await LocalFileStore.shareBytes(
      bytes: pdfBytes,
      fileName: 'claim_$safeName.pdf',
      mimeType: 'application/pdf',
      subject: 'Warranty Claim - ${item.name}',
    );
  }
}

final claimBundleServiceProvider =
    Provider<ClaimBundleService>((ref) => ClaimBundleService());
