import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:uuid/uuid.dart';

import 'constants.dart';
import 'local_file_store.dart';
import 'ocr_parser.dart';

enum CaptureSource { camera, gallery, pdf }

class PickedBillSource {
  const PickedBillSource({
    required this.displayPathOrUri,
    required this.bytes,
    this.extension = 'jpg',
  });

  final String displayPathOrUri;
  final Uint8List bytes;
  final String extension;
}

class ProcessedBillMedia {
  const ProcessedBillMedia({
    required this.savedImagePath,
    required this.ocrResult,
    required this.ocrDurationMs,
    this.recognizedText = '',
  });

  final String savedImagePath;
  final OcrParseResult ocrResult;
  final int ocrDurationMs;
  final String recognizedText;
}

class MediaService {
  final ImagePicker _picker = ImagePicker();
  static const _uuid = Uuid();

  Future<PickedBillSource?> pickSourceFile(CaptureSource source) async {
    try {
      switch (source) {
        case CaptureSource.camera:
          final file = await _picker.pickImage(source: ImageSource.camera);
          if (file == null) return null;
          final bytes = await file.readAsBytes();
          final display = kIsWeb
              ? await LocalFileStore.saveAttachmentBytes(bytes)
              : file.path;
          return PickedBillSource(displayPathOrUri: display, bytes: bytes);

        case CaptureSource.gallery:
          final file = await _picker.pickImage(source: ImageSource.gallery);
          if (file == null) return null;
          final bytes = await file.readAsBytes();
          final display = kIsWeb
              ? await LocalFileStore.saveAttachmentBytes(bytes)
              : file.path;
          return PickedBillSource(displayPathOrUri: display, bytes: bytes);

        case CaptureSource.pdf:
          final files = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['pdf'],
          );
          if (files.isEmpty) return null;
          final pdfBytes = await files.first.readAsBytes();
          return await _renderPdfFirstPage(pdfBytes);
      }
    } catch (_) {
      return null;
    }
  }

  Future<PickedBillSource?> _renderPdfFirstPage(Uint8List pdfBytes) async {
    PdfDocument? doc;
    PdfPage? page;
    try {
      doc = await PdfDocument.openData(pdfBytes);
      if (doc.pagesCount < 1) return null;
      page = await doc.getPage(1);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      if (pageImage == null) return null;
      if (kIsWeb) {
        final uri = await LocalFileStore.saveAttachmentBytes(
          pageImage.bytes,
          extension: 'png',
        );
        return PickedBillSource(
          displayPathOrUri: uri,
          bytes: pageImage.bytes,
          extension: 'png',
        );
      }
      final tempPath = await LocalFileStore.writeTempFile(
        pageImage.bytes,
        'pdf_page_${_uuid.v4()}.png',
      );
      if (tempPath == null) return null;
      return PickedBillSource(
        displayPathOrUri: tempPath,
        bytes: pageImage.bytes,
        extension: 'png',
      );
    } catch (_) {
      return null;
    } finally {
      await page?.close();
      await doc?.close();
    }
  }

  Future<PickedBillSource> cropImage(
    PickedBillSource picked, {
    required Color primaryColor,
  }) async {
    if (kIsWeb) return picked;
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.displayPathOrUri,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop bill',
            toolbarColor: primaryColor,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop bill',
          ),
        ],
      );
      if (cropped == null) return picked;
      final bytes = await LocalFileStore.readBytes(cropped.path);
      if (bytes == null) return picked;
      return PickedBillSource(
        displayPathOrUri: cropped.path,
        bytes: bytes,
        extension: picked.extension,
      );
    } catch (_) {
      return picked;
    }
  }

  Future<String> compressAndSaveSource(
    PickedBillSource source, {
    bool keepUnmodifiedCopy = false,
  }) async {
    if (kIsWeb) {
      return LocalFileStore.saveAttachmentBytes(
        source.bytes,
        extension: source.extension,
      );
    }

    Uint8List finalBytes = source.bytes;
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        source.bytes,
        minWidth: AppLimits.maxImageLongSide,
        minHeight: AppLimits.maxImageLongSide,
        quality: AppLimits.imageQuality,
        format: CompressFormat.jpeg,
      );
      if (compressed.isNotEmpty) {
        finalBytes = compressed;
      }
    } catch (_) {
      // Fallback to original bytes on unsupported platforms
    }

    return LocalFileStore.saveAttachmentBytes(
      finalBytes,
      extension: 'jpg',
      originalPathForCopy: source.displayPathOrUri,
      keepUnmodifiedCopy: keepUnmodifiedCopy,
    );
  }

  Future<ProcessedBillMedia> processAndRecognize(
    PickedBillSource source, {
    bool keepUnmodifiedCopy = false,
  }) async {
    final savedPath = await compressAndSaveSource(
      source,
      keepUnmodifiedCopy: keepUnmodifiedCopy,
    );

    final stopwatch = Stopwatch()..start();
    String recognizedText = '';
    if (!kIsWeb) {
      TextRecognizer? recognizer;
      try {
        recognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final inputImage = InputImage.fromFilePath(savedPath);
        final recognized = await recognizer.processImage(inputImage);
        recognizedText = recognized.text;
      } catch (_) {
        recognizedText = '';
      } finally {
        await recognizer?.close();
      }
    }
    stopwatch.stop();

    final parsed = OcrParser.parse(recognizedText);
    return ProcessedBillMedia(
      savedImagePath: savedPath,
      ocrResult: parsed,
      ocrDurationMs: stopwatch.elapsedMilliseconds,
      recognizedText: recognizedText,
    );
  }
}

final mediaServiceProvider = Provider<MediaService>((ref) => MediaService());
