import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/utils/device/info/screen_radius.dart';
import '../badge/global_badge.dart';
import '../text/global_text.dart';
import '../tooltip/global_tooltip.dart';
import 'navigation_rail_models.dart';

export 'navigation_rail_models.dart';

// ─── Constants ──────────────────────────────────────────────
const _kCollapsedWidth = 72.0;
const _kCompactWidth = 56.0;
const _kItemHPad = 12.0;
const _kItemVPad = 10.0;
const _kCompactItemVPad = 6.0;
const _kIconLabelGap = 4.0;
const _kFloatingRadius = 24.0;
const _kFallbackIndicatorRadius = 16.0;
const _kBadgeOffset = -4.0;
const _kDotOffset = -2.0;
const _kUnselectedOpacity = 0.5;
const _kDisabledOpacity = 0.4;
const _kBarIndicatorHeight = 28.0;
const _kDotIndicatorSize = 5.0;
const _kShadowBlur = 8.0;
const _kShadowOffset = Offset(2, 0);
const _kShadowOpacity = 0.1;
const _kLabelSelectedWeight = FontWeight.w600;
const _kLabelUnselectedWeight = FontWeight.w400;
const _kBlurBgOpacity = 0.7;
const _kBounceScale = 1.15;
const _kBounceDuration = AppDurations.fast;
const _kSlidingIndicatorWidth = 3.0;
const _kSlidingIndicatorHeight = 28.0;
const _kProminentSize = 48.0;
const _kProminentBlur = 8.0;
const _kLottieSize = 28.0;
const _kExtendedItemHPad = 16.0;
const _kExtendedLabelGap = 12.0;

/// Vertical sibling of [GlobalBottomNav]. Renders a navigation rail
/// for medium-and-larger window classes, with the same feature set:
/// animated indicators (pill / bar / sliding / dot / custom), icon
/// bounce, haptic, badges + dots, prominent items, gradient icon
/// shader, Lottie icons, GoRouter auto-navigation, extended mode for
/// label-next-to-icon layouts.
///
/// Pair with [GlobalScaffold] for adaptive nav, or drop standalone
/// inside a [Row] for custom side-nav layouts.
class GlobalNavigationRail extends StatefulWidget {
  const GlobalNavigationRail({
    super.key,
    required this.items,
    this.currentIndex,
    this.onTap,
    this.style = const NavigationRailStyle(),
    this.extended = false,
    this.expandOnHover = false,
    this.leading,
    this.trailing,
    this.autoNavigate = true,
    this.itemBuilder,
  });

  /// Items rendered in the rail.
  final List<NavigationRailItem> items;

  /// Selected index. When null, defaults to 0. The widget
  /// internally tracks `currentIndex` to drive the sliding indicator
  /// without forcing the caller to rebuild on every tap.
  final int? currentIndex;

  /// Tap callback. Called *before* any auto-navigation.
  final ValueChanged<int>? onTap;

  /// Visual configuration.
  final NavigationRailStyle style;

  /// When true, labels render next to icons (rail width =
  /// [NavigationRailStyle.extendedWidth]). When false, labels follow
  /// [NavigationRailStyle.labelMode].
  final bool extended;

  /// When true and [extended] is false, the rail starts collapsed
  /// (icon-only) and expands to [NavigationRailStyle.extendedWidth]
  /// while the pointer is hovering anywhere over the rail. Width
  /// + label visibility animate via the style's
  /// `animationDuration` / `animationCurve`. On touch platforms the
  /// rail stays in its initial collapsed state since there is no
  /// hover affordance.
  final bool expandOnHover;

  /// Optional widget pinned above the destinations (e.g. logo, FAB,
  /// expand toggle).
  final Widget? leading;

  /// Optional widget pinned below the destinations (e.g. settings,
  /// avatar, sign-out).
  final Widget? trailing;

  /// When true and an item has a [NavigationRailItem.route], tapping
  /// pushes that route via GoRouter on the root navigator.
  final bool autoNavigate;

  /// Override per-item rendering. Receives `(ctx, item, idx,
  /// isSelected)`. Useful for caller-side custom item shells.
  final Widget Function(
    BuildContext context,
    NavigationRailItem item,
    int index,
    bool isSelected,
  )?
  itemBuilder;

  @override
  State<GlobalNavigationRail> createState() => _GlobalNavigationRailState();
}

class _GlobalNavigationRailState extends State<GlobalNavigationRail>
    with TickerProviderStateMixin {
  late int _selectedIndex;
  AnimationController? _bounceCtrl;
  int _bouncingIndex = -1;
  final Map<int, GlobalKey> _itemKeys = {};
  Rect? _selectedRect;

  /// Hover-expand progress (0 = fully collapsed, 1 = fully extended).
  /// Drives both the rail width and the label fade so the layout
  /// never tries to render a full label inside a too-narrow rail.
  late final AnimationController _hoverCtrl;
  late final Animation<double> _hoverProgress;
  late final Animation<double> _labelOpacity;

  /// Effective extended state — true when the caller forces
  /// `extended` OR the rail is in hover-expand mode. In hover mode
  /// the extended Row layout always renders; the icon slides from
  /// the centre of the rail (collapsed) to the leading edge
  /// (extended) via a lerped leading-pad inside the Row, so there
  /// is never a discrete layout swap.
  bool get _effectiveExtended => widget.extended || widget.expandOnHover;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex ?? 0;
    if (widget.style.bounceOnTap) {
      _bounceCtrl = AnimationController(
        vsync: this,
        duration: _kBounceDuration,
      );
    }
    _hoverCtrl =
        AnimationController(
          vsync: this,
          duration: widget.style.animationDuration,
          value: widget.extended ? 1 : 0,
        )..addListener(() {
          if (mounted) setState(() {});
        });
    _hoverProgress = CurvedAnimation(
      parent: _hoverCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    // Label opacity ramps in only after the rail width has expanded
    // ~halfway, so a too-narrow rail never tries to render a full
    // label at full alpha (visual jank + RenderFlex overflow).
    _labelOpacity = CurvedAnimation(
      parent: _hoverCtrl,
      curve: const Interval(0.5, 1, curve: Curves.easeOutCubic),
      reverseCurve: const Interval(0, 0.5, curve: Curves.easeInCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureSelected());
  }

  @override
  void dispose() {
    _bounceCtrl?.dispose();
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GlobalNavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != null && widget.currentIndex != _selectedIndex) {
      _selectedIndex = widget.currentIndex!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureSelected());
    }
  }

  GlobalKey _keyFor(int i) => _itemKeys.putIfAbsent(i, GlobalKey.new);

  void _measureSelected() {
    if (!mounted) return;
    final key = _itemKeys[_selectedIndex];
    final box = key?.currentContext?.findRenderObject() as RenderBox?;
    final railBox = context.findRenderObject() as RenderBox?;
    if (box == null || railBox == null || !box.attached || !railBox.attached) {
      return;
    }
    final origin = box.localToGlobal(Offset.zero, ancestor: railBox);
    setState(() {
      _selectedRect = origin & box.size;
    });
  }

  void _onItemTap(int i) {
    final item = widget.items[i];
    if (item.disabled) return;
    final wasSelected = i == _selectedIndex;
    if (!wasSelected || widget.style.resetOnReTap) {
      if (widget.style.hapticFeedback) HapticFeedback.lightImpact();
      setState(() => _selectedIndex = i);
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureSelected());
    }
    if (widget.style.bounceOnTap) {
      _bouncingIndex = i;
      _bounceCtrl?.forward(from: 0).then((_) => _bounceCtrl?.reverse());
    }
    widget.onTap?.call(i);
    item.onTap?.call();
    if (widget.autoNavigate && item.route != null) {
      GoRouter.of(context).go(item.route!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final st = widget.style;
    final selectedColor = st.selectedColor ?? cs.primary;
    final unselectedColor =
        st.unselectedColor ??
        cs.onSurface.withValues(alpha: _kUnselectedOpacity);
    final disabledColor =
        st.disabledColor ?? cs.onSurface.withValues(alpha: _kDisabledOpacity);

    // The SURFACE covers the system inset; the CONTENT sits inside it.
    //
    // A rail stands at the READING EDGE of the screen, which in
    // landscape is exactly where the notch or the dynamic island is —
    // so its destinations were drawn underneath one. Padding the whole
    // widget instead would leave a strip of page showing between the
    // rail and the screen edge, which is the same mistake the bar's
    // `bottomInsetFactor` made along the bottom.
    final systemPad = MediaQuery.paddingOf(context);
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final outerInset = ltr ? systemPad.left : systemPad.right;

    final collapsedWidth =
        st.width ?? (st.compact ? _kCompactWidth : _kCollapsedWidth);
    final width = _effectiveExtended ? st.extendedWidth : collapsedWidth;

    final radius = _resolveRadius(st);
    final bg = st.backgroundGradient == null
        ? (st.backgroundColor ?? cs.surface)
        : null;

    final destinations = <Widget>[];
    for (var i = 0; i < widget.items.length; i++) {
      destinations.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: st.itemSpacing / 2),
          child: KeyedSubtree(
            key: _keyFor(i),
            child: _buildItem(
              context,
              widget.items[i],
              i,
              isSelected: i == _selectedIndex,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              disabledColor: disabledColor,
            ),
          ),
        ),
      );
    }

    final destinationsColumn = Column(
      mainAxisAlignment: st.itemAlignment,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: destinations,
    );

    final destinationsArea = st.scrollable
        ? SingleChildScrollView(child: destinationsColumn)
        : destinationsColumn;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.leading != null) widget.leading!,
        Expanded(child: destinationsArea),
        if (widget.trailing != null) widget.trailing!,
      ],
    );

    Widget rail = Stack(
      // `StackFit.expand` forces non-positioned children (the
      // destinations column) to fill the rail's bounded height —
      // without it the column gets loose constraints and the inner
      // `Expanded` blows up to infinity.
      fit: StackFit.expand,
      children: [
        body,
        // Indicator overlay for full-rail styles (leading / trailing /
        // sliding bars). Pill / dot render per-item inside
        // [_buildItem] so they stay attached to scroll content.
        if (_shouldDrawStackedIndicator(st))
          _buildStackedIndicator(st, selectedColor, width),
      ],
    );

    // Everything the rail DRAWS goes inside the safe region; the
    // decoration below it spans the whole box, inset included. The
    // stacked indicator is in here too — a leading bar outside it would
    // paint its line under the island.
    //
    // `SafeArea` both pads and REMOVES what it consumed, so a caller
    // who has already wrapped one round the rail gets no second inset.
    rail = SafeArea(left: ltr, right: !ltr, child: rail);

    // [InkWell] needs a [Material] ancestor to paint hover / focus /
    // splash ink. The rail surface is otherwise a plain DecoratedBox
    // — the transparent Material here gives every item its hover
    // and focus highlights without re-tinting the background.
    rail = Material(type: MaterialType.transparency, child: rail);

    rail = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        gradient: st.backgroundGradient,
        borderRadius: radius,
        border: st.border,
        boxShadow:
            st.shadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: _kShadowOpacity),
                blurRadius: _kShadowBlur,
                offset: _kShadowOffset,
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        // WITH A SAVE LAYER: a plain antialiased clip does not contain
        // a `BackdropFilter`, so the rail's corners come back SQUARE.
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: st.blur > 0
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: st.blur, sigmaY: st.blur),
                child: ColoredBox(
                  color: (bg ?? cs.surface).withValues(alpha: _kBlurBgOpacity),
                  child: rail,
                ),
              )
            : rail,
      ),
    );

    if (st.trailingBorder != null || st.trailingBorderGradient != null) {
      rail = _TrailingBorder(
        color: st.trailingBorder?.color,
        gradient: st.trailingBorderGradient,
        width: st.trailingBorderWidth,
        child: rail,
      );
    }

    // Compute the live rail width — interpolates between collapsed
    // and extended via the hover controller. When [extended] is
    // true the controller is pinned to 1, so this is just the
    // extended width.
    final liveWidth = widget.expandOnHover
        ? collapsedWidth +
              (st.extendedWidth - collapsedWidth) * _hoverProgress.value
        : width;

    // A FLUSH rail grows by the inset so its surface still reaches the
    // screen edge; a FLOATING one is already off the edge and adds the
    // inset to its margin instead, or it would float over the island.
    Widget sized = SizedBox(
      width: liveWidth + (st.floating ? 0 : outerInset),
      child: rail,
    );

    // Hover-to-expand wrapper. Only attached when caller opts in
    // AND the rail is not already permanently extended — otherwise
    // the controller stays at 1 and the MouseRegion would no-op.
    if (widget.expandOnHover && !widget.extended) {
      sized = MouseRegion(
        onEnter: (_) => _hoverCtrl.forward(),
        onExit: (_) => _hoverCtrl.reverse(),
        child: sized,
      );
    }

    return st.floating
        ? Padding(
            padding:
                st.floatingMargin +
                (ltr
                    ? EdgeInsets.only(left: outerInset)
                    : EdgeInsets.only(right: outerInset)),
            child: sized,
          )
        : sized;
  }

  // ─── Item builder ──────────────────────────────────────────

  Widget _buildItem(
    BuildContext context,
    NavigationRailItem item,
    int index, {
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
    required Color disabledColor,
  }) {
    if (widget.itemBuilder != null) {
      return widget.itemBuilder!(context, item, index, isSelected);
    }

    final st = widget.style;
    final color = item.disabled
        ? disabledColor
        : isSelected
        ? selectedColor
        : unselectedColor;

    Widget content;
    if (item.prominent) {
      content = _buildProminent(item, isSelected, selectedColor);
    } else if (_effectiveExtended) {
      content = _buildExtended(item, isSelected, color, selectedColor);
    } else {
      content = _buildCollapsed(
        item,
        isSelected,
        color,
        selectedColor,
        st.labelMode,
      );
    }

    if (st.bounceOnTap && _bouncingIndex == index) {
      content = ScaleTransition(
        scale: Tween<double>(begin: 1, end: _kBounceScale).animate(
          CurvedAnimation(parent: _bounceCtrl!, curve: Curves.easeOut),
        ),
        child: content,
      );
    }

    var wrapped = content;
    // Custom indicator overlays the whole content.
    if (isSelected &&
        !item.disabled &&
        st.indicatorStyle == NavigationRailIndicatorStyle.custom &&
        st.customIndicator != null) {
      wrapped = Stack(
        alignment: Alignment.center,
        children: [st.customIndicator!, content],
      );
    }

    final padding =
        st.itemPadding ??
        EdgeInsets.symmetric(
          horizontal: _kItemHPad,
          vertical: st.compact ? _kCompactItemVPad : _kItemVPad,
        );

    final hoverBase = st.indicatorColor ?? selectedColor;

    // Force every item to occupy the rail's full width so its
    // tap target + hover / focus highlight stay aligned across
    // selected and non-selected states. Without this, the selected
    // item (pill is wider) would visually shift relative to the
    // others.
    Widget tappable = SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: item.disabled ? null : () => _onItemTap(index),
        onLongPress: item.disabled ? null : item.onLongPress,
        hoverColor: hoverBase.withValues(alpha: 0.06),
        focusColor: hoverBase.withValues(alpha: 0.12),
        highlightColor: hoverBase.withValues(alpha: 0.1),
        splashColor: hoverBase.withValues(alpha: 0.18),
        canRequestFocus: !item.disabled,
        autofocus: false,
        child: Padding(
          padding: padding,
          child: Align(
            alignment: _effectiveExtended
                ? Alignment.centerLeft
                : Alignment.center,
            widthFactor: _effectiveExtended ? null : 1,
            child: wrapped,
          ),
        ),
      ),
    );

    if (item.tooltip != null) {
      tappable = GlobalTooltip(message: item.tooltip!, child: tappable);
    }

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: !item.disabled,
      label: item.label,
      child: tappable,
    );
  }

  Widget _buildCollapsed(
    NavigationRailItem item,
    bool isSelected,
    Color color,
    Color selectedColor,
    NavigationRailLabelMode labelMode,
  ) {
    final iconWidget = _buildIcon(item, isSelected, color, selectedColor);
    final iconWithBadge = _withBadgeAndDot(
      item,
      child: iconWidget,
      color: color,
      selectedColor: selectedColor,
    );
    final iconWithIndicator = _withIconIndicator(
      iconWithBadge,
      item,
      isSelected,
      selectedColor,
    );
    final showLabel =
        labelMode == NavigationRailLabelMode.always ||
        (labelMode == NavigationRailLabelMode.selectedOnly && isSelected);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWithIndicator,
        if (showLabel) ...[
          SizedBox(height: widget.style.compact ? 2 : _kIconLabelGap),
          _buildLabel(item, isSelected, color),
        ],
      ],
    );
  }

  Widget _buildExtended(
    NavigationRailItem item,
    bool isSelected,
    Color color,
    Color selectedColor,
  ) {
    final iconWidget = _buildIcon(item, isSelected, color, selectedColor);
    final iconWithBadge = _withBadgeAndDot(
      item,
      child: iconWidget,
      color: color,
      selectedColor: selectedColor,
    );
    final iconWithIndicator = _withIconIndicator(
      iconWithBadge,
      item,
      isSelected,
      selectedColor,
    );
    final label = _buildLabel(item, isSelected, color, align: TextAlign.start);
    final inHoverMode = widget.expandOnHover && !widget.extended;
    // Hover mode: label fades in via [_labelOpacity] (delayed to the
    // back half of the width animation) and clips horizontally so a
    // mid-animation narrow rail never tries to lay it out.
    final labelChild = inHoverMode
        ? FadeTransition(opacity: _labelOpacity, child: label)
        : label;
    // Lerp the extended-item outer horizontal pad + icon→label gap
    // by hover progress so a collapsed rail isn't forced to host
    // their full values.
    const fullOuterPad = _kExtendedItemHPad - _kItemHPad;
    final outerPad = inHoverMode
        ? fullOuterPad * _hoverProgress.value
        : fullOuterPad;
    final gap = inHoverMode
        ? _kExtendedLabelGap * _hoverProgress.value
        : _kExtendedLabelGap;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: outerPad),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          // Width of the icon-with-pill at the current hover progress.
          // Mirrors the calc in [_withIconIndicator]: icon + 2 * hPad.
          final pillHPad = inHoverMode
              ? 8.0 + (14.0 - 8.0) * _hoverProgress.value
              : 14.0;
          final pillWidth = widget.style.iconSize + pillHPad * 2;
          // Centring offset for the pill inside the available width.
          // When fully collapsed (progress=0) the icon sits at the
          // centre of the rail; when fully extended (progress=1) the
          // icon hugs the leading edge.
          final available = constraints.maxWidth;
          final centerPad = ((available - pillWidth) / 2).clamp(
            0.0,
            double.infinity,
          );
          final leadingPad = inHoverMode
              ? centerPad * (1 - _hoverProgress.value)
              : 0.0;
          return Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(width: leadingPad),
              iconWithIndicator,
              SizedBox(width: gap),
              // [Flexible] (not [Expanded]) so when the label area is
              // 0 (hover collapsed) the Row doesn't force it to claim
              // space. Label fades in + clipped horizontally.
              Flexible(child: ClipRect(child: labelChild)),
            ],
          );
        },
      ),
    );
  }

  /// Wraps the icon (already badge-decorated) with the per-item
  /// indicator chrome — pill rectangle behind the icon, or a dot
  /// pinned to the trailing-top corner. Leading / trailing / sliding
  /// bars + custom indicators are handled elsewhere (rail-level
  /// stack or [_buildItem]).
  ///
  /// The pill wrapper renders for **every** item (transparent when
  /// not selected) so all icons share the same vertical baseline —
  /// without this, the selected item's extra padding would push its
  /// icon slightly higher than its neighbours.
  Widget _withIconIndicator(
    Widget icon,
    NavigationRailItem item,
    bool isSelected,
    Color selectedColor,
  ) {
    if (item.disabled) return icon;
    final st = widget.style;
    switch (st.indicatorStyle) {
      case NavigationRailIndicatorStyle.pill:
        // Pill horizontal padding lerps from a small base (collapsed
        // rail → rounded chip behind the icon) to the wide pill
        // value (extended rail → traditional Material 3 indicator
        // pill). The base stays positive so a collapsed pill is a
        // chip, not a tall vertical capsule.
        const collapsedPad = 8.0;
        const extendedPad = 14.0;
        final inHoverMode = widget.expandOnHover && !widget.extended;
        final hPad = inHoverMode
            ? collapsedPad + (extendedPad - collapsedPad) * _hoverProgress.value
            : extendedPad;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? (st.indicatorColor ?? selectedColor).withValues(
                    alpha: st.indicatorOpacity,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              st.indicatorRadius ?? _kFallbackIndicatorRadius,
            ),
          ),
          child: icon,
        );
      case NavigationRailIndicatorStyle.dot:
        if (!isSelected) return icon;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            icon,
            Positioned(
              top: -2,
              right: -6,
              child: Container(
                width: _kDotIndicatorSize,
                height: _kDotIndicatorSize,
                decoration: BoxDecoration(
                  color: st.indicatorColor ?? selectedColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      case NavigationRailIndicatorStyle.none:
      case NavigationRailIndicatorStyle.leadingBar:
      case NavigationRailIndicatorStyle.trailingBar:
      case NavigationRailIndicatorStyle.sliding:
      case NavigationRailIndicatorStyle.custom:
        return icon;
    }
  }

  Widget _buildProminent(
    NavigationRailItem item,
    bool isSelected,
    Color selectedColor,
  ) {
    final color = item.prominentColor ?? selectedColor;
    final size = item.prominentSize ?? _kProminentSize;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: _kProminentBlur,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: _renderIconShape(
        item,
        Theme.of(context).colorScheme.onPrimary,
        size: size * 0.5,
      ),
    );
  }

  Widget _buildIcon(
    NavigationRailItem item,
    bool isSelected,
    Color color,
    Color selectedColor,
  ) {
    final st = widget.style;
    if (item.lottieAsset != null && isSelected) {
      return SizedBox(
        width: _kLottieSize,
        height: _kLottieSize,
        child: Lottie.asset(item.lottieAsset!, repeat: false),
      );
    }
    final icon = _renderIconShape(item, color, size: st.iconSize);
    if (item.iconGradient != null && isSelected) {
      return ShaderMask(
        shaderCallback: (rect) => item.iconGradient!.createShader(rect),
        child: _renderIconShape(item, Colors.white, size: st.iconSize),
      );
    }
    return icon;
  }

  Widget _renderIconShape(
    NavigationRailItem item,
    Color color, {
    required double size,
  }) {
    if (item.customIcon != null) {
      // Active variant takes priority when present.
      return SizedBox(
        width: size,
        height: size,
        child: item.activeCustomIcon != null && _isSelectedItem(item)
            ? item.activeCustomIcon!
            : item.customIcon!,
      );
    }
    final iconData = _isSelectedItem(item)
        ? (item.activeIcon ?? item.icon)
        : item.icon;
    return Icon(iconData, size: size, color: color);
  }

  bool _isSelectedItem(NavigationRailItem item) =>
      widget.items.indexOf(item) == _selectedIndex;

  Widget _buildLabel(
    NavigationRailItem item,
    bool isSelected,
    Color color, {
    TextAlign align = TextAlign.center,
  }) {
    final st = widget.style;
    return GlobalText(
      item.label,
      preset: TextPreset.labelMedium,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.clip,
      textStyle: GlobalTextStyle(
        color: color,
        fontSize: isSelected ? st.selectedFontSize : st.unselectedFontSize,
        fontWeight: isSelected
            ? _kLabelSelectedWeight
            : _kLabelUnselectedWeight,
      ),
    );
  }

  Widget _withBadgeAndDot(
    NavigationRailItem item, {
    required Widget child,
    required Color color,
    required Color selectedColor,
  }) {
    if (item.badge == null && !item.showDot) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        // `GlobalBadge`, on the reading END rather than the physical
        // right, so both mirror in Arabic. The dot's colour falls back to
        // the badge's own default — an unread marker is an ALERT, which
        // is the module's business rather than the rail's.
        if (item.badge != null)
          PositionedDirectional(
            top: _kBadgeOffset,
            end: _kBadgeOffset,
            child: GlobalBadge.standalone(
              label: item.badge,
              style: BadgeStyle(backgroundColor: selectedColor),
            ),
          )
        else if (item.showDot)
          PositionedDirectional(
            top: _kDotOffset,
            end: _kDotOffset,
            child: GlobalBadge.standalone(
              style: BadgeStyle(backgroundColor: item.dotColor),
            ),
          ),
      ],
    );
  }

  // ─── Stack-level indicators (leading bar / trailing bar / sliding) ─

  bool _shouldDrawStackedIndicator(NavigationRailStyle st) {
    return _selectedRect != null &&
        (st.indicatorStyle == NavigationRailIndicatorStyle.leadingBar ||
            st.indicatorStyle == NavigationRailIndicatorStyle.trailingBar ||
            st.indicatorStyle == NavigationRailIndicatorStyle.sliding);
  }

  Widget _buildStackedIndicator(
    NavigationRailStyle st,
    Color selectedColor,
    double width,
  ) {
    final rect = _selectedRect!;
    final color = st.indicatorColor ?? selectedColor;
    return AnimatedPositioned(
      duration: st.animationDuration,
      curve: st.animationCurve,
      top: rect.top + rect.height / 2 - _kBarIndicatorHeight / 2,
      left: st.indicatorStyle == NavigationRailIndicatorStyle.leadingBar
          ? st.indicatorBarInset
          : null,
      right: st.indicatorStyle == NavigationRailIndicatorStyle.trailingBar
          ? st.indicatorBarInset
          : null,
      width: st.indicatorStyle == NavigationRailIndicatorStyle.sliding
          ? _kSlidingIndicatorWidth
          : st.indicatorBarThickness,
      height: st.indicatorStyle == NavigationRailIndicatorStyle.sliding
          ? _kSlidingIndicatorHeight
          : _kBarIndicatorHeight,
      child: Align(
        alignment: st.indicatorStyle == NavigationRailIndicatorStyle.sliding
            ? Alignment.center
            : Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────

BorderRadius _resolveRadius(NavigationRailStyle st) {
  if (st.borderRadius != null) return st.borderRadius!;
  if (st.floating) {
    if (st.useDeviceRadius && DeviceRadius.hasRoundedCorners) {
      return DeviceRadius.uniformPadded;
    }
    return BorderRadius.circular(_kFloatingRadius);
  }
  return BorderRadius.zero;
}

class _TrailingBorder extends StatelessWidget {
  const _TrailingBorder({
    required this.color,
    required this.gradient,
    required this.width,
    required this.child,
  });

  final Color? color;
  final Gradient? gradient;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _TrailingBorderPainter(
        color: color,
        gradient: gradient,
        thickness: width,
      ),
      child: child,
    );
  }
}

class _TrailingBorderPainter extends CustomPainter {
  _TrailingBorderPainter({
    required this.color,
    required this.gradient,
    required this.thickness,
  });

  final Color? color;
  final Gradient? gradient;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;
    if (gradient != null) {
      paint.shader = gradient!.createShader(
        Rect.fromLTWH(size.width - thickness, 0, thickness, size.height),
      );
    } else if (color != null) {
      paint.color = color!;
    } else {
      return;
    }
    canvas.drawLine(
      Offset(size.width - thickness / 2, 0),
      Offset(size.width - thickness / 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TrailingBorderPainter old) =>
      color != old.color ||
      gradient != old.gradient ||
      thickness != old.thickness;
}
