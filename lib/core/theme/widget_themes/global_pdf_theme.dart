import 'package:flutter/material.dart';

import '../../../shared/module/pdf/global_pdf.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalPdfViewer].
///
/// The app-wide rebrand hook: set the corner and the inset of every
/// document viewer in the app once here, and decide which controls a
/// reader gets.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.<group>Colors` at build time, so a viewer tracks the active
/// palette, role, brightness and saturation.
class MyGlobalPdfTheme {
  MyGlobalPdfTheme._();

  static GlobalPdfTheme build({required AppTokens tokens}) {
    return GlobalPdfTheme(
      style: PdfStyle(borderRadius: BorderRadius.circular(tokens.radii.md)),
    );
  }
}
