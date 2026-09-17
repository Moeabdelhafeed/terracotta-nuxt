import 'package:flutter/material.dart';

import '../popup/popup.dart';
import 'theme/tooltip_theme.dart';
import 'tooltip_models.dart';

export 'theme/tooltip_theme.dart';
export 'tooltip_models.dart';

// ---------------------------------------------------------------------------
// GlobalTooltip
// ---------------------------------------------------------------------------

/// A themed tooltip.
///
/// ```dart
/// GlobalTooltip(message: 'Delete', child: icon)
/// GlobalTooltip.bubble(message: 'Points at me', child: icon)
/// ```
///
/// It renders through the POPUP engine, not Material's `Tooltip`, and
/// the reason is the arrow. Material clamps a tooltip inside the screen
/// but never reports how far it clamped, so a bubble near an edge points
/// at the margin beside its anchor and nothing can correct it. The popup
/// engine hands its surface the drift it applied, which is exactly the
/// number the arrow needs — see `popup/CLAUDE.md`.
///
/// What that cost, and what this widget therefore owns: the hover REST
/// before opening, the auto-dismiss after reading, the long-press path
/// for touch, and the anchor's own semantics. All four came free with
/// Material and are configured here.
class GlobalTooltip extends StatelessWidget {
  const GlobalTooltip({
    required this.child,
    super.key,
    this.message,
    this.richMessage,
    this.tooltipWidget,
    this.style = const TooltipStyle(),
    this.shape = TooltipShape.rectangle,
    this.trigger = TooltipTrigger.hoverOrLongPress,
    this.preferBelow = true,
    this.enabled = true,
    this.announceOnAnchor = true,
    this.semanticLabel,
  }) : assert(
         message != null || richMessage != null || tooltipWidget != null,
         'a tooltip needs a message, a richMessage or a tooltipWidget',
       );

  /// A bubble with an arrow pointing back at the child.
  factory GlobalTooltip.bubble({
    required Widget child,
    Key? key,
    String? message,
    InlineSpan? richMessage,
    Widget? tooltipWidget,
    TooltipStyle style = const TooltipStyle(),
    bool preferBelow = true,
    bool enabled = true,
  }) => GlobalTooltip(
    key: key,
    message: message,
    richMessage: richMessage,
    tooltipWidget: tooltipWidget,
    style: style,
    shape: TooltipShape.bubble,
    preferBelow: preferBelow,
    enabled: enabled,
    child: child,
  );

  final Widget child;

  final String? message;
  final InlineSpan? richMessage;

  /// A whole widget inside the tooltip. Outranks both messages.
  final Widget? tooltipWidget;

  /// Themeable style bag. Merges over `GlobalTooltipTheme`.
  final TooltipStyle style;

  final TooltipShape shape;

  /// What opens it. `none` keeps only the semantics.
  final TooltipTrigger trigger;

  /// Whether it prefers to sit below the child. The engine still flips
  /// it when there is no room, and the bubble's arrow follows.
  final bool preferBelow;

  /// When false the anchor renders alone — no trigger, no semantics.
  final bool enabled;

  /// Whether the ANCHOR publishes `Semantics(tooltip:)`.
  ///
  /// False for a host that already publishes it — `GlobalIconButton`
  /// excludes its inner tree and re-exposes the tooltip on its own
  /// node, so leaving this on nests two nodes carrying the same string.
  final bool announceOnAnchor;

  /// Spoken instead of [message]. Required when the tooltip carries a
  /// widget or a span, since neither is a string.
  final String? semanticLabel;

  /// What assistive tech reads. A `richMessage` is a span and a
  /// `tooltipWidget` is a subtree, so neither has a plain-text form —
  /// which is why [semanticLabel] exists.
  String? get _spoken => semanticLabel ?? message;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final rs = style.resolve(context, shape: shape);

    final anchored = GlobalPopup(
      enabled: trigger.popupTrigger != null,
      trigger: trigger.popupTrigger ?? GlobalPopupTrigger.manual,
      options: GlobalPopupOptions(
        // Content-sized. The popup's default is `matchAnchor`, which on
        // an icon button is 40dp — and a tooltip 40dp wide wraps one
        // character per line.
        width: GlobalPopupWidth.content(max: rs.maxWidth),
        placement: preferBelow
            ? GlobalPopupPlacement.bottom
            : GlobalPopupPlacement.top,
        hoverOpenDelay: rs.waitDuration,
        autoDismissAfter: rs.showDuration,
        // A tooltip never EVICTS another popup. The default is to
        // close everything else on open, which is right for a menu
        // replacing a menu and wrong for a label: holding an item in
        // an open menu to read its tooltip shut the menu.
        closeOthersOnOpen: false,
        // To the BODY. A bubble's arrow stands in this gap, so it asks
        // for less of one — see `gapFor`.
        gap: rs.gapFor(shape),
        screenPadding: rs.screenMargin,
        // NOT `arrow:` here. `GlobalPopupOptions.arrow` is read only by
        // the `.menu` / `.panel` factories, which forward it to the
        // surface they build; a custom `overlay:` builder hands it to
        // its own surface, which is what the bubble does below.
      ),
      overlay: (ctx, layout) => _TooltipSurface(
        layout: layout,
        rs: rs,
        shape: shape,
        message: message,
        richMessage: richMessage,
        tooltipWidget: tooltipWidget,
        spoken: _spoken,
      ),
      child: child,
    );

    // On the ANCHOR, not only on the surface. A screen reader has to be
    // able to read a control's tooltip without opening it — Material's
    // Tooltip publishes the same property, and losing it is the one
    // regression this move could have shipped.
    return _spoken == null || !announceOnAnchor
        ? anchored
        : Semantics(tooltip: _spoken, child: anchored);
  }
}

// ---------------------------------------------------------------------------
// Surface
// ---------------------------------------------------------------------------

/// The tooltip's own surface, styled from [ResolvedTooltipStyle].
///
/// Separate from `GlobalPopupTooltip` because that one styles itself off
/// `Theme.of`'s colour scheme; this module's bag is the app's, and two
/// tooltips with two surfaces was the duplication this merge removes.
class _TooltipSurface extends StatelessWidget {
  const _TooltipSurface({
    required this.layout,
    required this.rs,
    required this.shape,
    required this.message,
    required this.richMessage,
    required this.tooltipWidget,
    required this.spoken,
  });

  final GlobalPopupLayout layout;
  final ResolvedTooltipStyle rs;
  final TooltipShape shape;
  final String? message;
  final InlineSpan? richMessage;
  final Widget? tooltipWidget;
  final String? spoken;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (tooltipWidget != null) {
      content = tooltipWidget!;
    } else if (richMessage != null) {
      content = Text.rich(richMessage!, style: rs.textStyle);
    } else {
      content = Text(message!, style: rs.textStyle);
    }

    return Semantics(
      // A live region: it appeared without the user moving focus, so
      // nothing else will announce it.
      liveRegion: true,
      container: true,
      label: spoken,
      child: rs.decoration != null
          ? _decorated(content)
          : GlobalPopupSurface(
              layout: layout,
              style: GlobalPopupSurfaceStyle(
                color: rs.backgroundColor,
                gradient: rs.gradient,
                borderRadius: rs.borderRadius,
                borderColor: rs.borderColor,
                shadow: [rs.shadow],
                padding: rs.padding,
              ),
              // The surface is what RENDERS a tail; the arrow on
              // `GlobalPopupOptions` is only forwarded by the popup's
              // own factories, so a bubble that set it there and not
              // here drew no arrow at all.
              arrow: shape.isBubble
                  ? GlobalPopupArrow(
                      size: rs.arrowSize,
                      color: rs.backgroundColor,
                      // A dark tooltip's outline runs onto its tail —
                      // the painter strokes the two slanted edges only,
                      // so the base still stitches into the body.
                      borderColor: rs.borderColor,
                      alignment: GlobalPopupArrowAlignment.center,
                    )
                  : null,
              child: content,
            ),
    );
  }

  /// A caller's own decoration, painted INSTEAD of the surface.
  ///
  /// It wins outright, shape included — an arrow belongs to a border
  /// this module drew — so the popup surface is reduced to a transparent
  /// carrier for the layout constraints it computed.
  Widget _decorated(Widget content) => GlobalPopupSurface(
    layout: layout,
    style: const GlobalPopupSurfaceStyle(
      color: Colors.transparent,
      elevation: 0,
      shadow: [],
      padding: EdgeInsets.zero,
      clipBehavior: Clip.none,
    ),
    child: DecoratedBox(
      decoration: rs.decoration!,
      child: Padding(padding: rs.padding, child: content),
    ),
  );
}
