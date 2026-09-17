import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/strings/module_strings.dart';
import '../badge/global_badge.dart';
import '../buttons/global_icon_button.dart';
import 'tab_bar_models.dart';
import 'tab_indicators.dart';
import 'theme/tab_bar_theme.dart';

export 'global_tab_view.dart';
export 'tab_bar_models.dart';
export 'tab_indicators.dart';
export 'theme/tab_bar_theme.dart';

/// A tab bar over Material's [TabBar], with six indicator styles,
/// badges, dots, counts, closeable and disabled tabs, gradient borders,
/// scrollable + adaptive modes, leading/trailing slots and a custom tab
/// builder.
///
/// Implements [PreferredSizeWidget], so it drops straight into
/// `AppBar.bottom` as well as standing alone.
///
/// Visuals come from [TabBarStyle], resolved once per build:
/// `caller > GlobalTabBarTheme.style > TabBarStyle.defaults > tokens`.
class GlobalTabBar extends StatefulWidget implements PreferredSizeWidget {
  const GlobalTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.onTap,
    this.style = const TabBarStyle(),
    this.leading,
    this.trailing,
    this.tabBuilder,
  });

  final List<GlobalTabItem> tabs;

  /// Null falls back to the enclosing `DefaultTabController`.
  final TabController? controller;

  /// Fired for ENABLED tabs only.
  final ValueChanged<int>? onTap;

  final TabBarStyle style;

  /// Widget before the tabs row (filter icon, avatar, …).
  final Widget? leading;

  /// Widget after it (an "add tab" button, an overflow menu, …).
  final Widget? trailing;

  /// Replaces the built-in tab rendering entirely.
  ///
  /// `selectionProgress` is 0 when fully unselected and 1 when fully
  /// selected, interpolating smoothly while a swipe is in flight.
  final Widget Function(
    BuildContext context,
    GlobalTabItem item,
    int index,
    bool isSelected,
    double selectionProgress,
  )?
  tabBuilder;

  @override
  Size get preferredSize => Size.fromHeight(style.preferredHeightFor(tabs));

  @override
  State<GlobalTabBar> createState() => _GlobalTabBarState();
}

class _GlobalTabBarState extends State<GlobalTabBar> {
  TabController? _guarded;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachGuard(widget.controller ?? DefaultTabController.of(context));
  }

  @override
  void didUpdateWidget(GlobalTabBar old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) {
      _attachGuard(widget.controller ?? DefaultTabController.of(context));
    }
  }

  @override
  void dispose() {
    _guarded?.removeListener(_refuseDisabled);
    super.dispose();
  }

  void _attachGuard(TabController ctrl) {
    if (identical(ctrl, _guarded)) return;
    _guarded?.removeListener(_refuseDisabled);
    _guarded = ctrl..addListener(_refuseDisabled);
  }

  /// A disabled tab must not become the selection by ANY route.
  ///
  /// Refusing the tap was only half of it: the tab bar is one of two
  /// widgets driving the same controller, and swiping the `TabBarView`,
  /// arrowing across with a keyboard or calling `animateTo` all land on
  /// a disabled tab without going through `onTap` at all. The controller
  /// is the one place every route passes through.
  ///
  /// Waits for the animation to settle — bouncing mid-drag would fight
  /// the finger still on the screen.
  void _refuseDisabled() {
    final ctrl = _guarded;
    if (ctrl == null || ctrl.indexIsChanging) return;

    final index = ctrl.index;
    if (index >= widget.tabs.length || !widget.tabs[index].disabled) return;

    final fallback = _nearestEnabled(index, from: ctrl.previousIndex);
    if (fallback == null || fallback == index) return;

    // Deferred a frame ON PURPOSE. This listener fires from inside
    // `TabBarView`'s own settle, and `TabBarView` ignores controller
    // changes it believes it is already servicing — so an immediate
    // `animateTo` moved the INDICATOR back while the PAGE stayed on the
    // dead tab. That desync is worse than the bug it was fixing: the bar
    // then lies about which page you are looking at.
    if (_correcting) return;
    _correcting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _correcting = false;
      if (!mounted) return;
      final c = _guarded;
      if (c == null || c.indexIsChanging) return;
      if (c.index < widget.tabs.length && widget.tabs[c.index].disabled) {
        c.animateTo(fallback);
      }
    });
  }

  /// Guards against re-entering the deferred correction — `animateTo`
  /// notifies the same listener again.
  bool _correcting = false;

  /// Walks outward from [index], continuing in the direction of TRAVEL.
  ///
  /// Swiping from Posts toward a disabled Premium lands on Archive — the
  /// dead tab is stepped over, as if it were not in the strip. It used
  /// to reverse instead, back the way the user came, which is a
  /// different and worse answer to the same gesture: the swipe appeared
  /// to work and then undo itself. Reversing is still the fallback when
  /// there is nothing enabled further on.
  int? _nearestEnabled(int index, {required int from}) {
    final onward = from <= index ? 1 : -1;
    for (var step = 1; step < widget.tabs.length; step++) {
      for (final dir in [onward, -onward]) {
        final candidate = index + dir * step;
        if (candidate < 0 || candidate >= widget.tabs.length) continue;
        if (!widget.tabs[candidate].disabled) return candidate;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final rs = widget.style.resolve(context);
    final ctrl = widget.controller ?? DefaultTabController.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final tabs = widget.tabs;

    Widget tabBar = TabBar(
      controller: widget.controller,
      isScrollable: _isScrollable(context, rs),
      indicator: _indicatorFor(rs),
      indicatorSize: _indicatorSizeFor(rs),
      overlayColor: _overlayColor(rs),
      // TabBar turns these into the ambient DefaultTextStyle and
      // IconTheme, and crossfades them per tab as the selection moves.
      // Colouring the glyphs inside the tab instead was measurably
      // WORSE: driving them from the controller's animation snaps a tab
      // to fully-unselected the moment the animation passes it, roughly
      // a third of the way into a two-tab jump.
      labelColor: rs.selectedLabelColor,
      unselectedLabelColor: rs.unselectedColor,
      labelStyle: TextStyle(
        fontSize: rs.selectedFontSize,
        fontWeight: rs.selectedFontWeight,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: rs.unselectedFontSize,
        fontWeight: rs.unselectedFontWeight,
      ),
      labelPadding: _labelPadding(context, rs),
      dividerColor: rs.showDivider ? rs.dividerColor : Colors.transparent,
      dividerHeight: rs.showDivider ? rs.dividerHeight : 0,
      splashBorderRadius: _splashRadiusFor(rs),
      tabAlignment: _isScrollable(context, rs)
          ? TabAlignment.start
          : TabAlignment.fill,
      onTap: (index) => _handleTap(context, ctrl, index, rs),
      tabs: [
        for (var i = 0; i < tabs.length; i++)
          _TabSlot(
            controller: ctrl,
            index: i,
            item: tabs[i],
            style: rs,
            reduceMotion: reduceMotion,
            builder: widget.tabBuilder,
          ),
      ],
    );

    if (widget.leading != null || widget.trailing != null) {
      tabBar = Row(
        children: [
          if (widget.leading != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: TabBarDefaults.leadingTrailingPad,
              ),
              child: widget.leading,
            ),
          Expanded(child: tabBar),
          if (widget.trailing != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                end: TabBarDefaults.leadingTrailingPad,
              ),
              child: widget.trailing,
            ),
        ],
      );
    }

    return _wrapBackground(tabBar, rs);
  }

  // ─── Tap ──────────────────────────────────────────────────

  /// A disabled tab must not become the selection.
  ///
  /// `TabBar` owns the InkWell over each tab and offers no veto — by the
  /// time `onTap` runs it has already called `animateTo`. So the
  /// selection is put back INSTANTLY (`index =`, not `animateTo`):
  /// animating back flew the indicator over to the dead tab and home
  /// again, which reads as "it worked, then undid itself".
  ///
  /// [_refuseDisabled] is the backstop for every other route in.
  void _handleTap(
    BuildContext context,
    TabController ctrl,
    int index,
    ResolvedTabBarStyle rs,
  ) {
    final item = widget.tabs[index];
    if (item.disabled) {
      ctrl.index = ctrl.previousIndex;
      // No haptic: a refusal must not feel like a selection. The hook is
      // where an app says WHY — a paywall, an upgrade prompt — which is
      // the useful answer to tapping a locked tab.
      item.onDisabledTap?.call();
      return;
    }
    if (rs.enableHaptic) HapticFeedback.lightImpact();
    widget.onTap?.call(index);
  }

  // ─── Style plumbing ───────────────────────────────────────

  /// Padding around each tab's content, with the close button's own
  /// optical inset taken back off the END.
  ///
  /// That button centres a 16dp glyph in a 32dp box, so it already
  /// brings 8dp of empty space; adding the full inset on top of it left
  /// a visibly bigger gap after the ✕ than before the label. Subtracted
  /// by construction rather than by a tuned constant, so it tracks
  /// `closeButtonSize` / `closeIconSize` — the same treatment the toast
  /// gives its own close button, and directional for the same reason.
  ///
  /// It is a per-BAR value because `TabBar.labelPadding` is: a bar that
  /// mixes closeable and plain tabs tightens both. Closeable tabs are a
  /// browser-tab pattern where the whole strip is closeable, so that
  /// costs nothing in practice — and `style.tabPadding` overrides it
  /// outright for a bar that genuinely mixes.
  EdgeInsetsGeometry _labelPadding(
    BuildContext context,
    ResolvedTabBarStyle rs,
  ) {
    if (widget.style.tabPadding != null) return rs.tabPadding;
    if (!widget.tabs.any((t) => t.closeable)) return rs.tabPadding;

    final direction = Directionality.of(context);
    final resolved = rs.tabPadding.resolve(direction);
    final start = direction == TextDirection.rtl
        ? resolved.right
        : resolved.left;
    final closeInset = (rs.closeButtonSize - rs.closeIconSize) / 2;

    return EdgeInsetsDirectional.fromSTEB(
      start,
      resolved.top,
      (start - closeInset).clamp(0.0, double.infinity),
      resolved.bottom,
    );
  }

  /// Ink overlay per interaction state.
  ///
  /// Focus is deliberately the STRONGEST of the three. Material's
  /// default focus tint is ~10% of the ink colour, which on a tab —
  /// a transparent surface with an indicator already competing for the
  /// eye — was invisible in practice. It also has to be one value for
  /// every tab, or focus looks different depending on which tab holds
  /// it, which is the inconsistency being fixed here.
  ///
  /// Not a focus RING, unlike the buttons module: `TabBar` owns the
  /// InkWell ABOVE each tab's child and exposes no focus state to it, so
  /// there is nothing for a child to draw a ring against. The overlay is
  /// the only hook, and `splashBorderRadius` already gives it the tab's
  /// real shape.
  WidgetStateProperty<Color?> _overlayColor(ResolvedTabBarStyle rs) =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return rs.focusColor;
        }
        if (states.contains(WidgetState.pressed)) {
          return rs.indicatorColor.withValues(
            alpha: TabBarDefaults.pressedOverlayOpacity,
          );
        }
        if (states.contains(WidgetState.hovered)) {
          return rs.indicatorColor.withValues(
            alpha: TabBarDefaults.hoverOverlayOpacity,
          );
        }
        return null;
      });

  bool _isScrollable(BuildContext context, ResolvedTabBarStyle rs) =>
      switch (rs.adaptiveMode) {
        TabAdaptiveMode.manual => rs.isScrollable,
        // Read through MediaQuery rather than context.windowSize so the
        // bar still lays out without a BreakpointsProvider above it.
        TabAdaptiveMode.scrollOnNarrow =>
          MediaQuery.sizeOf(context).width < kTabScrollOnNarrowWidth,
      };

  Decoration _indicatorFor(ResolvedTabBarStyle rs) =>
      switch (rs.indicatorStyle) {
        TabIndicatorStyle.underline => UnderlineTabIndicator(
          borderSide: BorderSide(
            color: rs.indicatorColor,
            width: rs.indicatorWeight,
          ),
          borderRadius: BorderRadius.circular(rs.indicatorRadius),
        ),
        TabIndicatorStyle.pill => BoxDecoration(
          color: rs.indicatorColor.withValues(alpha: rs.pillOpacity),
          borderRadius: BorderRadius.circular(rs.pillRadius),
        ),
        TabIndicatorStyle.filled => BoxDecoration(
          color: rs.indicatorColor,
          borderRadius: BorderRadius.circular(TabBarDefaults.filledRadius),
        ),
        TabIndicatorStyle.gradientUnderline => GradientUnderlineTabIndicator(
          // A single-stop gradient of the indicator colour keeps the shape
          // identical to `underline` when no gradient was supplied, instead
          // of painting nothing.
          gradient:
              rs.indicatorGradient ??
              LinearGradient(colors: [rs.indicatorColor, rs.indicatorColor]),
          weight: rs.indicatorWeight,
          radius: rs.indicatorRadius,
        ),
        TabIndicatorStyle.dot => DotTabIndicator(color: rs.indicatorColor),
        TabIndicatorStyle.none => const BoxDecoration(),
      };

  /// Pill and filled indicators are the tab's own surface, so they span
  /// the whole tab; the rest sit under the label and track its width.
  TabBarIndicatorSize _indicatorSizeFor(ResolvedTabBarStyle rs) =>
      rs.indicatorStyle == TabIndicatorStyle.pill ||
          rs.indicatorStyle == TabIndicatorStyle.filled
      ? TabBarIndicatorSize.tab
      : TabBarIndicatorSize.label;

  /// The splash follows the SHAPE the tab actually has. It used to take
  /// `pillRadius` unconditionally, so a square filled tab rippled with
  /// rounded corners that were nowhere on screen.
  BorderRadius _splashRadiusFor(ResolvedTabBarStyle rs) =>
      switch (rs.indicatorStyle) {
        TabIndicatorStyle.pill => BorderRadius.circular(rs.pillRadius),
        TabIndicatorStyle.filled => BorderRadius.circular(
          TabBarDefaults.filledRadius,
        ),
        _ => BorderRadius.zero,
      };

  Widget _wrapBackground(Widget tabBar, ResolvedTabBarStyle rs) {
    if (!rs.paintsOwnBackground) return tabBar;

    // A gradient STROKE is two boxes, not a border: BoxDecoration cannot
    // stroke a gradient, so the outer box IS the stroke and an inset
    // child carries the fill.
    if (rs.borderGradient != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: rs.borderGradient,
          borderRadius: rs.borderRadius,
          boxShadow: rs.shadow,
        ),
        child: Container(
          margin: EdgeInsets.all(rs.borderWidth),
          decoration: BoxDecoration(
            color: rs.backgroundGradient == null ? rs.backgroundColor : null,
            gradient: rs.backgroundGradient,
            borderRadius: rs.borderRadius?.subtract(
              BorderRadius.all(Radius.circular(rs.borderWidth)),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: tabBar,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: rs.backgroundGradient == null ? rs.backgroundColor : null,
        gradient: rs.backgroundGradient,
        borderRadius: rs.borderRadius,
        border: rs.border,
        boxShadow: rs.shadow,
      ),
      clipBehavior: rs.borderRadius != null ? Clip.antiAlias : Clip.none,
      child: tabBar,
    );
  }
}

/// Viewport width below which [TabAdaptiveMode.scrollOnNarrow] scrolls.
///
/// The `compact` breakpoint, read from `MediaQuery` rather than
/// `context.windowSize` so a tab bar renders with no `BreakpointsProvider`
/// above it.
const double kTabScrollOnNarrowWidth = 600;

/// Marks the icon wrapper mounted only when [TabBarStyle.bounceOnTap] is
/// on and motion is not reduced. `ScaleTransition` alone is not a usable
/// finder — Material's own `TabBar` mounts one of its own.
const Key kTabBounceKey = Key('tab-bounce');

// ---------------------------------------------------------------------------
// One tab
// ---------------------------------------------------------------------------

/// Rebuilds a tab's content against the controller's animation.
///
/// This exists because a tab used to be built ONCE as a static widget
/// handed to `TabBar`, which knows nothing about which tab is selected.
/// Everything selection-dependent was therefore dead: `activeIcon` never
/// rendered, `activeCustomIcon` was not read at all, and the count and
/// badge were painted in the unselected colour on the selected tab.
class _TabSlot extends StatelessWidget implements PreferredSizeWidget {
  const _TabSlot({
    required this.controller,
    required this.index,
    required this.item,
    required this.style,
    required this.reduceMotion,
    this.builder,
  });

  /// `TabBar` MEASURES its tabs — it does not take the enclosing
  /// widget's `preferredSize` for its own height, and it reads this to
  /// decide whether the bar holds icon-and-text tabs at all
  /// (`tabHasTextAndIcon`, which drives the uniform vertical padding).
  ///
  /// Reporting nothing is what made a stacked icon+label bar lay out at
  /// the text-only height and paint 20dp past its own bottom edge.
  @override
  Size get preferredSize => Size.fromHeight(
    style.iconPosition == TabIconPosition.top &&
            (item.icon != null || item.customIcon != null)
        ? style.stackedHeight
        : TabBarDefaults.textOnlyHeight,
  );

  final TabController controller;
  final int index;
  final GlobalTabItem item;
  final ResolvedTabBarStyle style;
  final bool reduceMotion;
  final Widget Function(BuildContext, GlobalTabItem, int, bool, double)?
  builder;

  @override
  Widget build(BuildContext context) {
    final animation = controller.animation;
    if (animation == null) return _content(context, selected: false, t: 0);

    return AnimatedBuilder(
      animation: animation,
      builder: (ctx, _) {
        final value = animation.value;
        return _content(
          ctx,
          selected: value.round() == index,
          t: (1.0 - (value - index).abs()).clamp(0.0, 1.0),
        );
      },
    );
  }

  Widget _content(
    BuildContext context, {
    required bool selected,
    required double t,
  }) {
    if (builder != null) {
      return Tab(child: builder!(context, item, index, selected, t));
    }
    return Tab(
      child: _TabContent(
        item: item,
        style: style,
        selected: selected,
        reduceMotion: reduceMotion,
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.item,
    required this.style,
    required this.selected,
    required this.reduceMotion,
  });

  final GlobalTabItem item;
  final ResolvedTabBarStyle style;
  final bool selected;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    var content = _labelWithIcon(context);

    if (item.closeable) content = _withClose(context, content);
    if (item.badge != null || item.showDot) content = _withOverlay(content);
    if (style.indicatorStyle == TabIndicatorStyle.filled) {
      content = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TabBarDefaults.filledHPad,
          vertical: TabBarDefaults.filledVPad,
        ),
        child: content,
      );
    }

    // A disabled tab recolours rather than fading. `Opacity` dimmed the
    // whole subtree including the badge, which made an unread count on a
    // locked tab unreadable — and it ignored `disabledColor`, so the
    // palette had no say. IgnorePointer was there too and did nothing:
    // TabBar's own InkWell sits ABOVE the tab's child, so the tap never
    // reached this subtree in the first place. `_handleTap` and the
    // controller guard are what actually refuse.
    if (item.disabled) {
      content = IconTheme.merge(
        data: IconThemeData(color: style.disabledColor),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: style.disabledColor),
          child: content,
        ),
      );
    }

    return Semantics(
      container: true,
      selected: selected,
      enabled: !item.disabled,
      label: item.semanticLabel ?? _spokenLabel(),
      excludeSemantics: true,
      child: content,
    );
  }

  /// Everything a sighted user can see on the tab, spoken.
  ///
  /// The badge, the count and the disabled state are all information,
  /// and the label alone leaves an unread marker or a dead tab silent.
  String _spokenLabel() {
    final parts = <String>[item.label];
    if (item.count != null) parts.add('${item.count}');
    if (item.badge != null) parts.add(item.badge!);
    if (item.showDot && item.badge == null) {
      parts.add(BadgeStrings.newNotification);
    }
    return parts.join(', ');
  }

  Widget _labelWithIcon(BuildContext context) {
    final label = _label();
    var icon = item.iconFor(selected: selected, size: style.iconSize);
    if (icon == null) return label;

    if (style.bounceOnTap && !reduceMotion) {
      icon = _BounceOnSelect(
        key: kTabBounceKey,
        selected: selected,
        child: icon,
      );
    }

    // Flexible only INSIDE the Flex below. It used to wrap the label
    // unconditionally, so a plain text-only tab handed FlexParentData to
    // a `Semantics` with no Flex ancestor — an "Incorrect use of
    // ParentDataWidget" on every bar without icons.
    return style.iconPosition == TabIconPosition.top
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              SizedBox(height: style.iconSpacing),
              Flexible(child: label),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              SizedBox(width: style.iconSpacing),
              Flexible(child: label),
            ],
          );
  }

  Widget _label() {
    if (item.count == null) {
      return Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: TabBarDefaults.countGap),
        // Opacity, not a fixed colour: the count then rides whatever
        // foreground the tab currently has — including the crossfade
        // TabBar drives during a swipe, and the filled indicator's own
        // foreground. It used to be pinned to the unselected colour, so
        // it stayed grey on the selected tab and vanished on a filled one.
        Opacity(
          opacity: TabBarDefaults.countOpacity,
          child: Text(
            '${item.count}',
            style: const TextStyle(fontSize: TabBarDefaults.countFontSize),
          ),
        ),
      ],
    );
  }

  Widget _withClose(BuildContext context, Widget content) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: content),
      const SizedBox(width: TabBarDefaults.closeGap),
      GlobalIconButton(
        iconData: Icons.close_rounded,
        iconSize: style.closeIconSize,
        onPressed: item.disabled ? null : item.onClose,
        // The button sizes itself; MinTouchTarget's 48dp would BE the
        // tab. See TabBarDefaults.closeButtonSize.
        enforceMinTouchTarget: false,
        style: ButtonStateStyle(
          width: style.closeButtonSize,
          height: style.closeButtonSize,
          backgroundColor: Colors.transparent,
          foregroundColor: item.disabled
              ? style.disabledColor
              : style.unselectedColor,
        ),
        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      ),
    ],
  );

  /// Badge and dot share the tab's trailing corner, so a badge always
  /// wins — two markers in one place is noise, not information.
  Widget _withOverlay(Widget content) => Padding(
    padding: const EdgeInsetsDirectional.only(
      end: TabBarDefaults.badgeGutter,
    ),
    child: Opacity(
      opacity: item.disabled ? TabBarDefaults.disabledOpacity : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          // `GlobalBadge`, not a private pair of containers. Three
          // navigation surfaces carried a copy of this geometry and the
          // drawer's had already drifted from all of them.
          if (item.badge != null)
            PositionedDirectional(
              top: TabBarDefaults.badgeTopOffset,
              end: TabBarDefaults.badgeEndOffset,
              child: GlobalBadge.standalone(
                label: item.badge,
                style: BadgeStyle(backgroundColor: style.badgeColor),
              ),
            )
          else if (item.showDot)
            PositionedDirectional(
              top: TabBarDefaults.dotTopOffset,
              end: TabBarDefaults.dotEndOffset,
              child: GlobalBadge.standalone(
                style: BadgeStyle(
                  backgroundColor: item.dotColor ?? style.indicatorColor,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Bounce
// ---------------------------------------------------------------------------

/// Pulses its child when the tab BECOMES selected.
///
/// `TabBarStyle.bounceOnTap` was a declared knob nothing read. Keyed on
/// selection rather than the raw tap so a swipe and a keyboard move
/// bounce too, and so a tap on the already-current tab does not.
class _BounceOnSelect extends StatefulWidget {
  const _BounceOnSelect({
    super.key,
    required this.selected,
    required this.child,
  });

  final bool selected;
  final Widget child;

  @override
  State<_BounceOnSelect> createState() => _BounceOnSelectState();
}

class _BounceOnSelectState extends State<_BounceOnSelect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: TabBarDefaults.bounceDuration,
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1, end: TabBarDefaults.bounceScale),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween(begin: TabBarDefaults.bounceScale, end: 1),
      weight: 1,
    ),
  ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  @override
  void didUpdateWidget(_BounceOnSelect old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}
