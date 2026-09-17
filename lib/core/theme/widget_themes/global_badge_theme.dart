import '../../../shared/module/badge/global_badge.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalBadge].
///
/// The app-wide rebrand hook: set the unread marker's shape and weight
/// once here and every navigation surface follows.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.<group>Colors` at build time, so a badge tracks the active
/// palette, role, brightness and saturation.
class MyGlobalBadgeTheme {
  MyGlobalBadgeTheme._();

  static GlobalBadgeTheme build({required AppTokens tokens}) {
    return const GlobalBadgeTheme(style: BadgeStyle());
  }
}
