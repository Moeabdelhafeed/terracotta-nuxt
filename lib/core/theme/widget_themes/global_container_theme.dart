import 'package:flutter/material.dart';

import '../../../shared/module/container/global_container.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalContainer].
///
/// The app-wide rebrand hook: set the corner and the inner padding of
/// every styled box in the app once here.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.<group>Colors` at build time, so a container tracks the
/// active palette, role, brightness and saturation — and the bag cannot
/// tell a theme's value from a caller's, so a colour here would win over
/// the palette and a role change would stop moving containers.
class MyGlobalContainerTheme {
  MyGlobalContainerTheme._();

  static GlobalContainerTheme build({required AppTokens tokens}) =>
      GlobalContainerTheme(
        style: ContainerStyle(
          borderRadius: BorderRadius.circular(tokens.radii.lg),
          padding: EdgeInsets.all(tokens.spacing.md),
        ),
      );
}
