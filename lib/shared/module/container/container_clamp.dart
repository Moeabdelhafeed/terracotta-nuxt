part of 'global_container.dart';

// The bucket-aware width clamp behind `GlobalContainer.shell` / `.prose`
// / `.form`. Layout only — it draws nothing.

class _BucketClamp extends StatelessWidget {
  const _BucketClamp({
    super.key,
    required this.child,
    this.maxWidth,
    this.maxWidthByBucket,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final double? maxWidth;
  final ResponsiveValue<double>? maxWidthByBucket;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;
  final Widget child;

  double _resolveMaxWidth(BuildContext context) {
    if (maxWidthByBucket != null) return maxWidthByBucket!.resolve(context);
    if (maxWidth != null) return maxWidth!;
    return _kShellWidths.resolve(context);
  }

  @override
  Widget build(BuildContext context) {
    final clamp = _resolveMaxWidth(context);
    var content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    // HORIZONTAL system insets, and only those.
    //
    // Landscape puts the notch or the dynamic island down one SIDE of
    // the screen, and nothing in the app was reading `padding.left` /
    // `padding.right` — so on every page wide enough to reach the edge,
    // the first characters of every line sat under it. This is the one
    // wrapper every top-level page already goes through.
    //
    // Vertical is deliberately left alone: `Scaffold` already hands the
    // body its top inset when there is an app bar, and the bottom one
    // belongs to whatever chrome is down there.
    //
    // `SafeArea` REMOVES what it consumed, so a page that wraps its own
    // is not inset twice and a nested shell adds nothing.
    return SafeArea(
      top: false,
      bottom: false,
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: clamp),
          child: content,
        ),
      ),
    );
  }
}
