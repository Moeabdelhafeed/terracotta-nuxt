import '../../../shared/module/rating/global_rating.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalRating].
///
/// The app-wide rebrand hook: swap the star for another glyph, or
/// resize the row, once here and every rating follows.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.<group>Colors` at build time, so a rating tracks the active
/// palette, role, brightness and saturation.
class MyGlobalRatingTheme {
  MyGlobalRatingTheme._();

  static GlobalRatingTheme build({required AppTokens tokens}) {
    return const GlobalRatingTheme(style: RatingStyle());
  }
}
