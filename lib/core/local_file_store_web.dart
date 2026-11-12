import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class LocalFileStore {
  LocalFileStore._();

  static Future<String> saveAttachmentBytes(
    Uint8List bytes, {
    String extension = 'jpg',
    String? originalPathForCopy,
    bool keepUnmodifiedCopy = false,
  }) async {
    final mime = extension.toLowerCase() == 'png' ? 'image/png' : 'image/jpeg';
    final b64 = base64Encode(bytes);
    return 'data:$mime;base64,$b64';
  }

  static Future<Uint8List?> readBytes(String pathOrUri) async {
    if (pathOrUri.startsWith('data:')) {
      return UriData.parse(pathOrUri).contentAsBytes();
    }
    if (pathOrUri.startsWith('http') || pathOrUri.startsWith('blob:')) {
      try {
        final res = await http.get(Uri.parse(pathOrUri));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          return res.bodyBytes;
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<bool> exists(String pathOrUri) async {
    return pathOrUri.startsWith('data:') ||
        pathOrUri.startsWith('http') ||
        pathOrUri.startsWith('blob:');
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
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, name: fileName, mimeType: mimeType),
        ],
        subject: subject,
      ),
    );
  }

  static Future<void> shareStoredPath(String pathOrUri) async {
    final bytes = await readBytes(pathOrUri);
    if (bytes == null) return;
    await shareBytes(
      bytes: bytes,
      fileName: 'attachment.jpg',
      mimeType: 'image/jpeg',
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
    if (pathOrUri.startsWith('http') || pathOrUri.startsWith('blob:')) {
      return Image.network(pathOrUri, fit: fit, width: width, height: height);
    }
    return SizedBox(
      width: width,
      height: height,
      child: const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
