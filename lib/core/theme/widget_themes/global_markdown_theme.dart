import 'package:flutter/material.dart';

import '../../../shared/module/markdown/markdown_style.dart';
import '../../../shared/module/markdown/theme/markdown_theme_extension.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for `GlobalMarkdown`.
///
/// The block rhythm comes from the TOKENS, so a document breathes with
/// the window like the rest of the app. Every one of these numbers
/// used to be written into a static style-sheet builder that no house
/// could reach.
class MyGlobalMarkdownTheme {
  MyGlobalMarkdownTheme._();

  static GlobalMarkdownTheme build({required AppTokens tokens}) {
    return GlobalMarkdownTheme(
      style: MarkdownStyle(
        blockSpacing: tokens.spacing.sm,
        codeRadius: tokens.radii.sm,
        loadingPadding: EdgeInsets.all(tokens.spacing.lg),
      ),
    );
  }
}
