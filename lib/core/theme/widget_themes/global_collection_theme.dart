import '../../../shared/module/grid/global_grid.dart';
import '../../../shared/module/list/global_list.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the two collections — every list and
/// every grid in the app.
///
/// The rebrand hook they never had: a hundred and twenty-seven
/// parameters on one widget and a hundred and sixty-one on the other,
/// and not one of them reachable from a theme. A house that wanted a
/// calmer entrance, a different gap, or a taller pagination bar had to
/// say so at every call site.
///
/// No colours: the spinner and the progress strip resolve from
/// `context.primaryColors` at build time, so they track role,
/// brightness and saturation.
class MyGlobalCollectionTheme {
  MyGlobalCollectionTheme._();

  static GlobalCollectionTheme build({required AppTokens tokens}) =>
      GlobalCollectionTheme(
        listStyle: ListStyle(
          // A group header is chrome, and it grows with the window
          // like every other piece.
          groupHeaderHeight: tokens.spacing.xl,
        ),
        gridStyle: GridStyle(
          // ONE gap answers both axes: a grid whose columns and rows
          // are spaced differently reads as a mistake.
          spacing: tokens.spacing.sm,
          groupHeaderHeight: tokens.spacing.xl,
        ),
      );
}
