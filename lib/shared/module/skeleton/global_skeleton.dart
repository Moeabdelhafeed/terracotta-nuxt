import 'package:flutter/material.dart';

import '../shimmer/global_shimmer.dart';
import 'skeleton_models.dart';
import 'theme/skeleton_theme.dart';

export 'skeleton_models.dart';
export 'theme/skeleton_theme.dart';

// ---------------------------------------------------------------------------
// GlobalSkeleton
// ---------------------------------------------------------------------------

/// A skeleton loading wrapper that shows shimmer placeholders while content
/// loads, then fades to the real content when [loading] is false.
///
/// Uses the existing [GlobalShimmer] system for consistent shimmer colors.
class GlobalSkeleton extends StatelessWidget {
  const GlobalSkeleton({
    super.key,
    required this.loading,
    required this.skeleton,
    required this.child,
    this.style = const SkeletonStyle(),
  });

  /// Whether to show the skeleton (true) or the real content (false).
  final bool loading;

  /// The skeleton placeholder widget.
  final Widget skeleton;

  /// The real content widget.
  final Widget child;

  /// Styling configuration.
  final SkeletonStyle style;

  // ─── Factory: List Tile ────────────────────────────────────

  /// Skeleton for a standard list tile (avatar + two lines).
  factory GlobalSkeleton.listTile({
    Key? key,
    required bool loading,
    required Widget child,
    double avatarSize = kSkeletonAvatarSize,
    SkeletonStyle style = const SkeletonStyle(),
  }) {
    return GlobalSkeleton(
      key: key,
      loading: loading,
      style: style,
      skeleton: Row(
        children: [
          GlobalShimmer.circle(size: avatarSize),
          const SizedBox(width: kSkeletonSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlobalShimmer.text(
                  width: double.infinity,
                  height: kSkeletonTitleHeight,
                ),
                const SizedBox(height: 8),
                GlobalShimmer.text(width: 160, height: kSkeletonBodyHeight),
              ],
            ),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Skeleton for a card (image + title + body lines).
  factory GlobalSkeleton.card({
    Key? key,
    required bool loading,
    required Widget child,
    double imageHeight = kSkeletonImageHeight,
    SkeletonStyle style = const SkeletonStyle(),
  }) {
    return GlobalSkeleton(
      key: key,
      loading: loading,
      style: style,
      skeleton: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlobalShimmer.placeholder(
            width: double.infinity,
            height: imageHeight,
            borderRadius: BorderRadius.circular(kSkeletonDefaultRadius),
          ),
          const SizedBox(height: kSkeletonSpacing),
          GlobalShimmer.text(width: 200, height: kSkeletonTitleHeight),
          const SizedBox(height: 8),
          GlobalShimmer.text(
            width: double.infinity,
            height: kSkeletonBodyHeight,
          ),
          const SizedBox(height: 6),
          GlobalShimmer.text(width: 240, height: kSkeletonBodyHeight),
        ],
      ),
      child: child,
    );
  }

  /// Skeleton for a profile header (large avatar + name + subtitle).
  factory GlobalSkeleton.profile({
    Key? key,
    required bool loading,
    required Widget child,
    double avatarSize = 72,
    SkeletonStyle style = const SkeletonStyle(),
  }) {
    return GlobalSkeleton(
      key: key,
      loading: loading,
      style: style,
      skeleton: Column(
        children: [
          GlobalShimmer.circle(size: avatarSize),
          const SizedBox(height: kSkeletonSpacing),
          GlobalShimmer.text(width: 140, height: kSkeletonTitleHeight),
          const SizedBox(height: 8),
          GlobalShimmer.text(width: 100, height: kSkeletonBodyHeight),
        ],
      ),
      child: child,
    );
  }

  /// Skeleton for an article (title + multiple body lines).
  factory GlobalSkeleton.article({
    Key? key,
    required bool loading,
    required Widget child,
    int lineCount = 5,
    SkeletonStyle style = const SkeletonStyle(),
  }) {
    return GlobalSkeleton(
      key: key,
      loading: loading,
      style: style,
      skeleton: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlobalShimmer.text(
            width: double.infinity,
            height: kSkeletonTitleHeight + 4,
          ),
          const SizedBox(height: 6),
          GlobalShimmer.text(width: 200, height: kSkeletonTitleHeight),
          const SizedBox(height: 16),
          for (var i = 0; i < lineCount; i++) ...[
            GlobalShimmer.text(
              width: i == lineCount - 1 ? 180 : double.infinity,
              height: kSkeletonBodyHeight,
            ),
            if (i < lineCount - 1) const SizedBox(height: 8),
          ],
        ],
      ),
      child: child,
    );
  }

  /// Skeleton for a grid of items.
  factory GlobalSkeleton.grid({
    Key? key,
    required bool loading,
    required Widget child,
    int crossAxisCount = 2,
    int itemCount = 4,
    double itemHeight = kSkeletonCardHeight,
    double spacing = kSkeletonSpacing,
    SkeletonStyle style = const SkeletonStyle(),
  }) {
    return GlobalSkeleton(
      key: key,
      loading: loading,
      style: style,
      skeleton: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(
          itemCount,
          (_) => LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth =
                  (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                  crossAxisCount;
              return GlobalShimmer.placeholder(
                width: itemWidth,
                height: itemWidth, // 1:1 aspect ratio
                borderRadius: BorderRadius.circular(kSkeletonDefaultRadius),
              );
            },
          ),
        ),
      ),
      child: child,
    );
  }

  /// Skeleton for a list of items.
  factory GlobalSkeleton.list({
    Key? key,
    required bool loading,
    required Widget child,
    int itemCount = 3,
    double spacing = kSkeletonSpacing,
    SkeletonStyle style = const SkeletonStyle(),
  }) {
    return GlobalSkeleton(
      key: key,
      loading: loading,
      style: style,
      skeleton: Column(
        children: List.generate(itemCount, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < itemCount - 1 ? spacing : 0),
            child: Row(
              children: [
                GlobalShimmer.circle(size: kSkeletonAvatarSize),
                const SizedBox(width: kSkeletonSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlobalShimmer.text(
                        width: double.infinity,
                        height: kSkeletonTitleHeight,
                      ),
                      const SizedBox(height: 8),
                      GlobalShimmer.text(
                        width: 120,
                        height: kSkeletonBodyHeight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = style.resolve(context);
    return AnimatedCrossFade(
      duration: rs.fadeDuration,
      firstCurve: rs.fadeCurve,
      secondCurve: rs.fadeCurve,
      crossFadeState: loading
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: skeleton,
      secondChild: child,
    );
  }
}
