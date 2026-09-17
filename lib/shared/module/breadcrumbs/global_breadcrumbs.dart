import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/strings/nav_strings.dart';
import '../../../core/responsive/responsive.dart';
import '../marquee/global_marquee.dart';
import '../popup/popup.dart';
import '../scrollable/global_edge_fade.dart';
import '../scrollable/scrollable_style.dart';
import '../tooltip/global_tooltip.dart';
import 'breadcrumbs_models.dart';
import 'theme/breadcrumbs_theme.dart';

export 'breadcrumbs_models.dart';
export 'theme/breadcrumbs_theme.dart';

/// The trail that says where a page sits, and how to get back up it.
///
/// ```dart
/// GlobalBreadcrumbs(items: [
///   BreadcrumbItem('Home', route: 'home'),
///   BreadcrumbItem('Account', route: 'account'),
///   BreadcrumbItem('Privacy'),          // no route — the current page
/// ])
/// ```
///
/// **Not the crash trail.** `UiWatchdog.breadcrumb` and the crash
/// reporter's breadcrumbs are a diagnostic log of where the app has
/// been; this is a control that says where the READER is. The two share
/// a word and nothing else.
class GlobalBreadcrumbs extends StatelessWidget {
  const GlobalBreadcrumbs({
    required this.items,
    super.key,
    this.style = const BreadcrumbsStyle(),
    this.onTap,
    this.semanticLabel,
  });

  /// The trail, root first. The LAST one is the current page.
  final List<BreadcrumbItem> items;

  final BreadcrumbsStyle style;

  /// Wins over an item's own `onTap` and `route`. For a caller that
  /// routes centrally, or one that wants to confirm before leaving.
  final ValueChanged<int>? onTap;

  /// What the landmark is called. Null takes the module's own.
  final String? semanticLabel;

  /// The trail GoRouter already knows about.
  ///
  /// Opt-in, and it needs [labels]: a route's NAME is a slug —
  /// `common-toasts-showcase` — not something to show a reader.
  ///
  /// It is only as deep as the router is NESTED. Most of this app's
  /// routes are declared flat, so this yields a single crumb for them;
  /// that is the router's shape, not a fault here.
  factory GlobalBreadcrumbs.fromRouter(
    BuildContext context, {
    required Map<String, String> labels,
    Key? key,
    BreadcrumbsStyle style = const BreadcrumbsStyle(),
    ValueChanged<int>? onTap,
    String? semanticLabel,
  }) {
    final matches = GoRouterState.of(context).topRoute;
    final location = GoRouterState.of(context).matchedLocation;

    // Walk the path, not the route tree: `/a/b/c` is the trail, and the
    // router hands back the leaf rather than the chain.
    final segments = Uri.parse(location).pathSegments;
    final crumbs = <BreadcrumbItem>[];
    for (var i = 0; i < segments.length; i++) {
      final slug = segments[i];
      final label = labels[slug];
      if (label == null) continue;
      final isLast = i == segments.length - 1;
      crumbs.add(
        BreadcrumbItem(label, route: isLast ? null : slug),
      );
    }
    if (crumbs.isEmpty && matches != null) {
      final name = matches.name;
      if (name != null && labels[name] != null) {
        crumbs.add(BreadcrumbItem(labels[name]!));
      }
    }

    return GlobalBreadcrumbs(
      key: key,
      items: crumbs,
      style: style,
      onTap: onTap,
      semanticLabel: semanticLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Materialized ONCE per build: every helper below reads `rs` rather
    // than re-deriving `style.x ?? palette.y` at each use.
    final rs = style.resolve(context);
    final compact = context.maybeBreakpoints?.windowSize.isCompact ?? false;

    final row = switch (rs.overflow) {
      BreadcrumbsOverflow.lastOnly => _lastOnly(context, rs),
      BreadcrumbsOverflow.wrap => _wrap(context, rs),
      BreadcrumbsOverflow.scroll => _ScrollingTrail(
        rs: rs,
        child: _row(context, rs, items, indexOffset: 0),
      ),
      BreadcrumbsOverflow.collapse => _collapse(context, rs, compact: compact),
    };

    // ONE landmark, and the crumbs inside it are its children. A trail
    // is navigation: a reader jumping by landmark should find it, and
    // find the whole of it rather than eight loose buttons.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel ?? NavStrings.breadcrumbs,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: rs.minHeight),
        child: row,
      ),
    );
  }

  // ─── Layouts ──────────────────────────────────────────────

  Widget _lastOnly(BuildContext context, ResolvedBreadcrumbsStyle rs) {
    // The PARENT, not the current page: "up" is the only thing a
    // one-crumb trail can usefully say, and the page's own title has
    // already said where you are.
    if (items.length < 2) return _row(context, rs, items, indexOffset: 0);
    final parentIndex = items.length - 2;
    return _row(
      context,
      rs,
      [items[parentIndex]],
      indexOffset: parentIndex,
      leadingSeparator: true,
    );
  }

  Widget _wrap(BuildContext context, ResolvedBreadcrumbsStyle rs) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) _separator(rs),
        _crumb(context, rs, items[i], i),
      ],
    ],
  );

  Widget _collapse(
    BuildContext context,
    ResolvedBreadcrumbsStyle rs, {
    required bool compact,
  }) {
    final budget = rs.visibleFor(compact: compact);
    // Below four there is nothing left to collapse: the first, the
    // ellipsis and the current one already come to three.
    if (items.length <= budget || budget < 3) {
      return _row(context, rs, items, indexOffset: 0);
    }

    final tailCount = budget - 2;
    final hidden = items.sublist(1, items.length - tailCount);
    final tail = items.sublist(items.length - tailCount);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _crumb(context, rs, items.first, 0),
        _separator(rs),
        _Ellipsis(
          rs: rs,
          hidden: hidden,
          onSelected: (offset) => _go(context, offset + 1),
        ),
        for (var i = 0; i < tail.length; i++) ...[
          _separator(rs),
          _crumb(context, rs, tail[i], items.length - tailCount + i),
        ],
      ],
    );
  }

  Widget _row(
    BuildContext context,
    ResolvedBreadcrumbsStyle rs,
    List<BreadcrumbItem> shown, {
    required int indexOffset,
    bool leadingSeparator = false,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (leadingSeparator) _separator(rs, flip: true),
      for (var i = 0; i < shown.length; i++) ...[
        if (i > 0) _separator(rs),
        Flexible(child: _crumb(context, rs, shown[i], indexOffset + i)),
      ],
    ],
  );

  // ─── Parts ────────────────────────────────────────────────

  /// The mark between two crumbs.
  ///
  /// Punctuation, so it is excluded from the semantics tree — a reader
  /// hearing "chevron" between every step is being read the furniture.
  Widget _separator(ResolvedBreadcrumbsStyle rs, {bool flip = false}) =>
      ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: rs.separatorGap),
          child: rs.separatorText != null
              ? Text(
                  rs.separatorText!,
                  style: TextStyle(
                    fontSize: rs.fontSize,
                    color: rs.separatorColor,
                  ),
                )
              : Transform.flip(
                  // `lastOnly` shows the mark BEFORE the parent, where
                  // it points back the way you came.
                  flipX: flip,
                  child: Icon(
                    rs.separatorIcon,
                    size: rs.separatorSize,
                    color: rs.separatorColor,
                  ),
                ),
        ),
      );

  Widget _crumb(
    BuildContext context,
    ResolvedBreadcrumbsStyle rs,
    BreadcrumbItem item,
    int index,
  ) {
    final isCurrent = index == items.length - 1;
    final links = !isCurrent && (item.isLink || onTap != null) && item.enabled;

    final color = !item.enabled
        ? rs.disabledColor
        : isCurrent
        ? rs.currentColor
        : rs.linkColor;

    final labelStyle = TextStyle(
      fontSize: rs.fontSize,
      fontWeight: isCurrent ? rs.currentFontWeight : rs.fontWeight,
      color: color,
    );

    // The qualifier earns its room only when it is needed — see
    // `_isAmbiguous`. It is quieter than the label and never bold: it
    // says WHICH one, it is not part of the name.
    final detail = _isAmbiguous(item) ? item.detail : null;
    final spans = TextSpan(
      children: [
        TextSpan(text: item.label),
        if (detail != null)
          TextSpan(
            text: '${BreadcrumbsDefaults.detailSeparator}$detail',
            style: TextStyle(
              color: item.enabled ? rs.disabledColor : color,
              fontWeight: rs.fontWeight,
            ),
          ),
      ],
    );
    final spoken = detail == null
        ? item.label
        : '${item.label}${BreadcrumbsDefaults.detailSeparator}$detail';

    Widget label = Text.rich(
      spans,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: labelStyle,
    );
    if (rs.marqueeLabels) {
      label = GlobalMarquee(
        semanticLabel: spoken,
        style: rs.marqueeStyle,
        child: Text.rich(
          spans,
          maxLines: 1,
          softWrap: false,
          style: labelStyle,
        ),
      );
    }

    final content = Padding(
      padding: rs.itemPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.icon != null) ...[
            Icon(item.icon, size: rs.iconSize, color: color),
            SizedBox(width: rs.iconGap),
          ],
          Flexible(child: label),
        ],
      ),
    );

    var crumb = links
        ? Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(rs.itemRadius),
              hoverColor: rs.hoverColor,
              focusColor: rs.focusColor,
              onTap: () => _go(context, index),
              child: content,
            ),
          )
        : content;

    // A tooltip is an EXTRA, never the disambiguation itself: it needs a
    // pointer or a long press to appear, so it says nothing to a reader
    // skimming the trail or listening to it. That is `detail`'s job.
    final tip = item.tooltip;
    if (tip != null) {
      crumb = GlobalTooltip(message: tip, child: crumb);
    }

    // The CURRENT page is a heading, not a link: it is where the reader
    // already is, so it takes no tap and announces itself as the place
    // rather than as a way to get somewhere.
    return Semantics(
      container: true,
      header: isCurrent,
      button: links,
      enabled: item.enabled,
      label: spoken,
      hint: NavStrings.tabPosition(index + 1, items.length),
      onTap: links ? () => _go(context, index) : null,
      excludeSemantics: true,
      child: crumb,
    );
  }

  /// Whether this crumb needs its qualifier to be told apart.
  ///
  /// A route pushed with its own data can appear twice in one trail — a
  /// product page reached from a related product — and two crumbs both
  /// reading "Product" name the same place as far as anyone can tell, a
  /// screen reader included. When that happens the qualifier shows;
  /// when every label is already distinct it stays out of the way, so
  /// declaring one costs nothing on the trails that do not need it.
  ///
  /// Linear and allocation-free because it EARLY-OUTS at the second
  /// match. A trail is a handful of crumbs, and paying for a Set here
  /// would cost more than the scan it replaces.
  bool _isAmbiguous(BreadcrumbItem item) {
    if (item.detail == null) return false;
    var seen = 0;
    for (final other in items) {
      if (other.label == item.label && ++seen > 1) return true;
    }
    return false;
  }

  /// Where a crumb goes.
  ///
  /// The caller's `onTap` wins over the item's, and the item's wins
  /// over its route — a trail is not a second navigator, it just says
  /// which step was pressed.
  void _go(BuildContext context, int index) {
    final tap = onTap;
    if (tap != null) {
      tap(index);
      return;
    }
    final item = items[index];
    if (item.onTap != null) {
      item.onTap!();
      return;
    }
    final route = item.route;
    if (route != null) context.goNamed(route, extra: item.extra);
  }
}

/// The `…` that stands in for the crumbs a collapse swallowed.
///
/// A button, and it says how many it is holding — an ellipsis that
/// announces itself as "…" tells a reader nothing about what is behind
/// it.
/// The `…` that stands in for the crumbs a collapse swallowed.
///
/// A button, and it says how many it is holding — an ellipsis that
/// announces itself as "…" tells a reader nothing about what is behind
/// it.
class _Ellipsis extends StatelessWidget {
  const _Ellipsis({
    required this.rs,
    required this.hidden,
    required this.onSelected,
  });

  final ResolvedBreadcrumbsStyle rs;
  final List<BreadcrumbItem> hidden;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: NavStrings.breadcrumbsHidden(hidden.length),
    excludeSemantics: true,
    // The POPUP engine places this, and that is the whole point.
    //
    // It used to call `GlobalPopup.showAt` with a `GlobalPopupLayout`
    // built here — `isAbove: false`, `isFlipping: false`,
    // `anchorSize: Size.zero` — which is the engine's job. Doing it by
    // hand meant working in the wrong coordinate space (the menu opened
    // sixty points below the button inside a page that installs its own
    // overlay, and needed a `globalToLocal` correction that is now
    // simply unnecessary), a menu that could never flip above a trail
    // near the foot of the page, and an anchor the surface believed was
    // a zero-sized point.
    child: GlobalPopup.menu<int>(
      anchor: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(rs.itemRadius),
          hoverColor: rs.hoverColor,
          focusColor: rs.focusColor,
          child: Padding(
            padding: rs.itemPadding,
            // The count is what makes the ellipsis mean something. "…"
            // alone says only that SOMETHING was swallowed; the number
            // says how much is behind it, and it is the cheapest thing
            // that does — the semantics already said as much, and this
            // is the same fact for eyes.
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.more_horiz_rounded,
                  size: rs.separatorSize,
                  color: rs.linkColor,
                ),
                if (rs.showHiddenCount) ...[
                  const SizedBox(width: BreadcrumbsDefaults.hiddenCountGap),
                  Text(
                    '${hidden.length}',
                    style: TextStyle(
                      fontSize: rs.fontSize * BreadcrumbsDefaults.detailScale,
                      fontWeight: rs.currentFontWeight,
                      color: rs.linkColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      items: [
        for (var i = 0; i < hidden.length; i++)
          GlobalPopupMenuItem(
            value: i,
            label: hidden[i].label,
            icon: hidden[i].icon,
            enabled: hidden[i].enabled,
          ),
      ],
      onSelected: onSelected,
      // A trail sits at the TOP of a page, so its menu drops from the
      // ellipsis — and `bottomStart` is directional, so it opens from
      // the reading-start edge in Arabic too.
      options: const GlobalPopupOptions(
        placement: GlobalPopupPlacement.bottomStart,
      ),
    ),
  );
}

/// The `scroll` strategy: the whole trail sideways, with a fade at each
/// end.
///
/// The fade is not decoration. A trail that runs off the edge looks
/// exactly like a trail that was cut off unless something says it
/// moves, and the shader mode is `smart` — the end you have reached
/// hides itself, so the fade that remains is also pointing at where
/// there is more to see.
class _ScrollingTrail extends StatefulWidget {
  const _ScrollingTrail({required this.rs, required this.child});

  final ResolvedBreadcrumbsStyle rs;
  final Widget child;

  @override
  State<_ScrollingTrail> createState() => _ScrollingTrailState();
}

class _ScrollingTrailState extends State<_ScrollingTrail> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      child: widget.child,
    );
    if (widget.rs.edgeFade <= 0) return view;
    return GlobalEdgeFade(
      controller: _controller,
      axis: Axis.horizontal,
      style: EdgeFadeStyle(size: widget.rs.edgeFade),
      child: view,
    );
  }
}
