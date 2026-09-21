import 'package:flutter/material.dart';

/// Which input the scan page's centre camera button captures.
enum ScanMode { barcode, ingredients }

extension ScanModeX on ScanMode {
  String get label => this == ScanMode.barcode ? 'Barcode' : 'Ingredients';

  IconData get icon => this == ScanMode.barcode
      ? Icons.qr_code_scanner_rounded
      : Icons.receipt_long_rounded;

  /// Helper copy shown under the viewfinder for this mode.
  String get instructions => this == ScanMode.barcode
      ? 'Align the barcode within the frame'
      : 'Align the ingredients list within the frame';
}
