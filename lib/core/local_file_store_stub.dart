import 'dart:typed_data';

import 'package:flutter/widgets.dart';

class LocalFileStore {
  LocalFileStore._();

  static Future<String> saveAttachmentBytes(
    Uint8List bytes, {
    String extension = 'jpg',
    String? originalPathForCopy,
    bool keepUnmodifiedCopy = false,
  }) {
    throw UnsupportedError('LocalFileStore is not supported on this platform.');
  }

  static Future<Uint8List?> readBytes(String pathOrUri) {
    throw UnsupportedError('LocalFileStore is not supported on this platform.');
  }

  static Future<bool> exists(String pathOrUri) {
    throw UnsupportedError('LocalFileStore is not supported on this platform.');
  }

  static Future<void> deleteFile(String pathOrUri) async {}

  static Future<String?> writeTempFile(
    Uint8List bytes,
    String fileName, {
    String? customDirPath,
  }) async =>
      null;

  static Future<void> shareBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? subject,
  }) async {}

  static Future<void> shareStoredPath(String pathOrUri) async {}

  static Widget buildImage(
    String pathOrUri, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    return const SizedBox.shrink();
  }
}
