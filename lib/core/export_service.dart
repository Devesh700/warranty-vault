import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../data/providers.dart';
import '../data/repositories/warranty_repository.dart';
import 'local_file_store.dart';

class ExportService {
  ExportService(this._repo);

  final WarrantyRepository _repo;

  static String _csvCell(Object? value) {
    final s = value?.toString() ?? '';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  Future<Uint8List> buildExportZipBytes() async {
    final items = await _repo.getAllItems();
    final attachments = await _repo.getAllAttachments();

    final csvBuffer = StringBuffer();
    csvBuffer.writeln(
      [
        'id',
        'name',
        'brand',
        'model',
        'serialNumber',
        'category',
        'purchaseDate',
        'warrantyMonths',
        'warrantyEndDate',
        'extendedWarrantyEndDate',
        'isLifetime',
        'price',
        'currency',
        'storeName',
        'notes',
        'attachments',
      ].map(_csvCell).join(','),
    );

    final archive = Archive();

    for (final item in items) {
      final itemAtts =
          attachments.where((a) => a.itemId == item.id).toList();
      final exportedPaths = <String>[];

      for (final att in itemAtts) {
        final bytes = await LocalFileStore.readBytes(att.localPath);
        if (bytes == null || bytes.isEmpty) continue;
        final fileName = att.localPath.startsWith('data:')
            ? '${att.id}.jpg'
            : p.basename(att.localPath);
        final zipPath = 'images/${item.id}/$fileName';
        archive.addFile(ArchiveFile(zipPath, bytes.length, bytes));
        exportedPaths.add(zipPath);
      }

      csvBuffer.writeln(
        [
          item.id,
          item.name,
          item.brand,
          item.model,
          item.serialNumber,
          item.category.name,
          item.purchaseDate.toIso8601String(),
          item.warrantyMonths,
          item.warrantyEndDate.toIso8601String(),
          item.extendedWarrantyEndDate?.toIso8601String(),
          item.isLifetime,
          item.price,
          item.currency,
          item.storeName,
          item.notes,
          exportedPaths.join('; '),
        ].map(_csvCell).join(','),
      );
    }

    final csvBytes = utf8.encode(csvBuffer.toString());
    archive.addFile(ArchiveFile('items.csv', csvBytes.length, csvBytes));

    final zipBytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipBytes);
  }

  Future<void> exportAndShare() async {
    final zipBytes = await buildExportZipBytes();
    await LocalFileStore.shareBytes(
      bytes: zipBytes,
      fileName: 'warranty_vault_export.zip',
      mimeType: 'application/zip',
      subject: 'WarrantyVault Export',
    );
  }
}

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref.watch(warrantyRepositoryProvider));
});
