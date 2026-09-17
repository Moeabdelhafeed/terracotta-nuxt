import '../../../shared/module/card_stack/stack_models.dart';
import '../../../shared/module/card_stack/theme/stack_theme.dart';
import '../../tokens/app_tokens.dart';

/// App-wide defaults for the two stacks — `GlobalCardStack` and
/// `GlobalLayeredStack`.
///
/// The hook here is the GEOMETRY of depth, not a palette: neither
/// stack paints anything, the caller's `itemBuilder` draws every
/// card. Set how deep a deck looks once and both agree.
///
/// Left unanswered on purpose. A deck's depth is a house's decision
/// and the floor is a sensible one; filling it in here would make
/// this file, rather than `StackDefaults`, the place the numbers
/// live.
class MyGlobalStackTheme {
  MyGlobalStackTheme._();

  static GlobalStackTheme build({required AppTokens tokens}) {
    return const GlobalStackTheme(style: StackStyle());
  }
}
