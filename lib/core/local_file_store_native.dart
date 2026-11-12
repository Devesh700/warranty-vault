import 'dart:io';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class LocalFileStore {
  LocalFileStore._();

  static const _uuid = Uuid();

  static Future<String> saveAttachmentBytes(
    Uint8List bytes, {
    String extension = 'jpg',
    String? originalPathForCopy,
    bool keepUnmodifiedCopy = false,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final attachDir = Directory(p.join(docsDir.path, 'attachments'));
    if (!await attachDir.exists()) {
      await attachDir.create(recursive: true);
    }

    final id = _uuid.v4();
    if (keepUnmodifiedCopy && originalPathForCopy != null) {
      final origFile = File(originalPathForCopy);
      if (await origFile.exists()) {
        final originalsDir = Directory(p.join(attachDir.path, 'originals'));
        if (!await originalsDir.exists()) {
          await originalsDir.create(recursive: true);
        }
        final ext = p.extension(originalPathForCopy).isEmpty
            ? '.$extension'
            : p.extension(originalPathForCopy);
        await origFile.copy(p.join(originalsDir.path, '${id}_orig$ext'));
      }
    }

    final targetPath = p.join(attachDir.path, '$id.$extension');
    await File(targetPath).writeAsBytes(bytes);
    return targetPath;
  }

  static Future<Uint8List?> readBytes(String pathOrUri) async {
    if (pathOrUri.startsWith('data:')) {
      return UriData.parse(pathOrUri).contentAsBytes();
    }
    final file = File(pathOrUri);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  static Future<bool> exists(String pathOrUri) async {
    if (pathOrUri.startsWith('data:') || pathOrUri.startsWith('http')) {
      return true;
    }
    return File(pathOrUri).exists();
  }

  static Future<void> deleteFile(String pathOrUri) async {
    if (pathOrUri.startsWith('data:') || pathOrUri.startsWith('http')) return;
    final file = File(pathOrUri);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  static Future<String?> writeTempFile(
    Uint8List bytes,
    String fileName, {
    String? customDirPath,
  }) async {
    final dirPath = customDirPath ?? (await getTemporaryDirectory()).path;
    final outFile = File(p.join(dirPath, fileName));
    await outFile.writeAsBytes(bytes);
    return outFile.path;
  }

  static Future<void> shareBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? subject,
  }) async {
    final path = await writeTempFile(bytes, fileName);
    if (path == null) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: mimeType)],
        subject: subject,
      ),
    );
  }

  static Future<void> shareStoredPath(String pathOrUri) async {
    if (pathOrUri.startsWith('data:')) {
      final bytes = UriData.parse(pathOrUri).contentAsBytes();
      await shareBytes(
        bytes: bytes,
        fileName: 'attachment.jpg',
        mimeType: 'image/jpeg',
      );
      return;
    }
    final file = File(pathOrUri);
    if (!await file.exists()) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );
  }

  static Widget buildImage(
    String pathOrUri, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (pathOrUri.startsWith('data:')) {
      final bytes = UriData.parse(pathOrUri).contentAsBytes();
      return Image.memory(bytes, fit: fit, width: width, height: height);
    }
    if (pathOrUri.startsWith('http')) {
      return Image.network(pathOrUri, fit: fit, width: width, height: height);
    }
    final file = File(pathOrUri);
    if (!file.existsSync()) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      );
    }
    return Image.file(file, fit: fit, width: width, height: height);
  }
}
