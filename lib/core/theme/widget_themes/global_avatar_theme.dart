import '../../../shared/module/avatar/global_avatar.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalAvatar].
///
/// The app-wide rebrand hook: set the avatar's shape and ring once here
/// and every face follows.
///
/// Colors are deliberately NOT set — and `backgroundColor` especially
/// not: a named avatar generates its colour FROM the name, and a themed
/// default would make every face in a list the same colour.
class MyGlobalAvatarTheme {
  MyGlobalAvatarTheme._();

  static GlobalAvatarTheme build({required AppTokens tokens}) {
    return const GlobalAvatarTheme(style: AvatarStyle());
  }
}
