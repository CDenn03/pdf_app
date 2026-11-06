import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

abstract interface class AuxiliaryDocumentLoader {
  Future<sf_pdf.PdfDocument> load({
    required String path,
    required bool isAsset,
    required AssetBundle bundle,
  });
}

class SyncfusionDocumentLoader implements AuxiliaryDocumentLoader {
  const SyncfusionDocumentLoader();

  @override
  Future<sf_pdf.PdfDocument> load({
    required String path,
    required bool isAsset,
    required AssetBundle bundle,
  }) async {
    final bytes = await _readBytes(path, isAsset, bundle);
    return compute(
      (Uint8List data) => sf_pdf.PdfDocument(inputBytes: data),
      bytes,
    );
  }

  Future<Uint8List> _readBytes(
    String path,
    bool isAsset,
    AssetBundle bundle,
  ) async {
    if (isAsset) {
      final data = await bundle.load(path);
      return data.buffer.asUint8List();
    }
    return File(path).readAsBytes();
  }
}
