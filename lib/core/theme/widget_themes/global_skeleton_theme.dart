import '../../../shared/module/skeleton/global_skeleton.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalSkeleton].
///
/// The app-wide hook for how long a placeholder takes to hand over to
/// real content. Reduced motion collapses it regardless — see
/// `SkeletonStyleResolve.resolve`.
class MyGlobalSkeletonTheme {
  MyGlobalSkeletonTheme._();

  static GlobalSkeletonTheme build({required AppTokens tokens}) {
    return const GlobalSkeletonTheme(style: SkeletonStyle());
  }
}
