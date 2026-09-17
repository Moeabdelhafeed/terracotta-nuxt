import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../../../core/painters/gradient_border_painter.dart';
import '../popup/popup.dart';
import '../text_field/text_field.dart' show FieldMessage, FieldMessagesColumn;
import '../tooltip/global_tooltip.dart';
import 'toggle_group_models.dart';
import 'toggle_group_overflow.dart';

export '../text_field/text_field.dart' show FieldMessage, FieldMessageType;
export 'theme/toggle_group_theme.dart';
export 'toggle_group_models.dart';
export 'toggle_group_overflow.dart';

// ---------------------------------------------------------------------------
// GlobalToggleGroup
// ---------------------------------------------------------------------------

/// A row of mutually exclusive or multi-select toggle buttons — the
/// BUTTON-SET selection control (borders, dividers, icon-only,
/// vertical, multi-select). For the sliding-indicator single-select
/// look use `GlobalSegmentedControl` instead; that split is the module
/// boundary.
///
/// Fully controlled — displays [selectedValues] as passed and reports
/// via [onChanged]. Visuals come from the themeable [ToggleGroupStyle]
/// bag (`caller > GlobalToggleGroupTheme > defaults > context colors`);
/// haptics gate on the resolved `enableHaptic` (default true).
class GlobalToggleGroup<T> extends StatefulWidget {
  const GlobalToggleGroup({
    super.key,
    required this.items,
    required this.selectedValues,
    required this.onChanged,
    this.variant = ToggleGroupVariant.outlined,
    this.style = const ToggleGroupStyle(),
    this.multiSelect = false,
    this.enabled = true,
    this.orientation = Axis.horizontal,
    this.errorText,
    this.messages = const [],
    this.semanticLabel,
    this.overflow = ToggleGroupOverflow.collapse,
    this.coordinateOverflow = true,
    this.overflowLabelBuilder,
  });

  /// Available items.
  final List<ToggleGroupItem<T>> items;

  /// Currently selected value(s).
  final List<T> selectedValues;

  /// Called when selection changes.
  final ValueChanged<List<T>> onChanged;

  /// Visual variant.
  final ToggleGroupVariant variant;

  /// Themeable styling — see [ToggleGroupStyle.resolve] for the merge
  /// order.
  final ToggleGroupStyle style;

  /// When true, multiple items can be selected.
  final bool multiSelect;

  /// Whether the group is interactive.
  final bool enabled;

  /// Layout orientation.
  final Axis orientation;

  /// Error shown below — rendered in the shared [FieldMessagesColumn]
  /// (icon + status color), like every field.
  final String? errorText;

  /// Status rows below, stacked with [errorText].
  final List<FieldMessage> messages;

  /// Accessibility label.
  final String? semanticLabel;

  /// What happens when the buttons do not fit.
  ///
  /// Defaults to COLLAPSING, because the alternative was a striped
  /// `RenderFlex overflowed` bar and buttons nobody could reach — a
  /// seven-day weekday set on a phone did exactly that.
  ///
  /// Vertical groups ignore it: a column overflows downwards, which
  /// the page it is on already scrolls.
  final ToggleGroupOverflow overflow;

  /// Whether it narrows in step with the other groups around it.
  ///
  /// Two groups on one card that collapse at different moments look
  /// broken rather than responsive. Set false for a group that has no
  /// business shrinking because its neighbour ran out of room — a pair
  /// of sort arrows beside seven weekdays.
  ///
  /// It needs a [ToggleGroupOverflowScope] above it to have anything
  /// to coordinate WITH.
  final bool coordinateOverflow;

  /// What the overflow button says. Default is `+N`.
  final String Function(int hidden)? overflowLabelBuilder;

  /// Single-select convenience constructor.
  factory GlobalToggleGroup.single({
    Key? key,
    required List<ToggleGroupItem<T>> items,
    required T? value,
    required ValueChanged<T> onChanged,
    ToggleGroupVariant variant = ToggleGroupVariant.outlined,
    ToggleGroupStyle style = const ToggleGroupStyle(),
    bool enabled = true,
    Axis orientation = Axis.horizontal,
    String? errorText,
    List<FieldMessage> messages = const [],
    String? semanticLabel,
    ToggleGroupOverflow overflow = ToggleGroupOverflow.collapse,
    bool coordinateOverflow = true,
  }) {
    return GlobalToggleGroup<T>(
      key: key,
      items: items,
      selectedValues: value != null ? [value] : [],
      onChanged: (values) {
        if (values.isNotEmpty) onChanged(values.last);
      },
      variant: variant,
      style: style,
      multiSelect: false,
      enabled: enabled,
      orientation: orientation,
      errorText: errorText,
      messages: messages,
      semanticLabel: semanticLabel,
      overflow: overflow,
      coordinateOverflow: coordinateOverflow,
    );
  }

  @override
  State<GlobalToggleGroup<T>> createState() => _GlobalToggleGroupState<T>();
}

class _GlobalToggleGroupState<T> extends State<GlobalToggleGroup<T>> {
  /// Identity in the scope's register — the widget itself is rebuilt
  /// constantly and cannot be the key.
  final Object _id = Object();

  /// The collapsed "+N"'s focus. The popup owns the tab stop, so this
  /// is the only way that button can know it is focused — it has no
  /// tap handler, and therefore no `InkWell` focus to paint from.
  final FocusNode _overflowFocus = FocusNode(debugLabel: 'toggleOverflow');
  bool _overflowFocused = false;

  /// Which way the panel opened, or null while it is shut.
  ///
  /// The trigger and the panel JOIN along the edge between them: the
  /// corner each of them has on that edge goes square, so the two read
  /// as one piece of the strip rather than a button with a card near
  /// it. Only the popup knows which edge that is — it flips to
  /// whichever side has room.
  ///
  /// Plain state rather than a notifier: the BUTTONS need it too, to
  /// clip their ink to the same shape, and a `ValueListenableBuilder`
  /// around the container alone left them rounding a corner the strip
  /// had already given up.
  bool? _panelAbove;

  void _setPanelAbove(bool? value) {
    if (!mounted || _panelAbove == value) return;
    setState(() => _panelAbove = value);
  }

  /// How many buttons the row last said it could fit.
  int _fits = -1;

  /// Kept rather than looked up: deregistering happens in `dispose`,
  /// and an ancestor lookup from there is unsafe.
  ToggleGroupOverflowRegistration _scope =
      const ToggleGroupOverflowRegistration.none();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = toggleGroupOverflowRegistration(context);
  }

  @override
  void initState() {
    super.initState();
    _overflowFocus.addListener(_onOverflowFocus);
  }

  void _onOverflowFocus() {
    if (!mounted || _overflowFocused == _overflowFocus.hasFocus) return;
    setState(() => _overflowFocused = _overflowFocus.hasFocus);
  }

  @override
  void dispose() {
    _overflowFocus
      ..removeListener(_onOverflowFocus)
      ..dispose();
    _scope.forget(_id);
    super.dispose();
  }

  List<ToggleGroupItem<T>> get items => widget.items;
  List<T> get selectedValues => widget.selectedValues;
  ValueChanged<List<T>> get onChanged => widget.onChanged;
  ToggleGroupVariant get variant => widget.variant;
  ToggleGroupStyle get style => widget.style;
  bool get multiSelect => widget.multiSelect;
  bool get enabled => widget.enabled;
  Axis get orientation => widget.orientation;
  String? get errorText => widget.errorText;
  List<FieldMessage> get messages => widget.messages;
  String? get semanticLabel => widget.semanticLabel;

  void _handleTap(ToggleGroupItem<T> item, ResolvedToggleGroupStyle rs) {
    if (!enabled || !item.enabled) return;

    if (rs.enableHaptic) HapticFeedback.lightImpact();

    final newValues = List<T>.from(selectedValues);
    if (multiSelect) {
      if (newValues.contains(item.value)) {
        newValues.remove(item.value);
      } else {
        newValues.add(item.value);
      }
    } else {
      newValues
        ..clear()
        ..add(item.value);
    }
    onChanged(newValues);
  }

  @override
  Widget build(BuildContext context) {
    // Materialize the themeable bag once per build (resolved-style
    // invariant).
    final rs = style.resolve(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : rs.animationDuration;

    // The strip's radius, less whatever it has given up to an open
    // panel. Everything that draws a corner reads THIS, not
    // `rs.borderRadius` — the container, and every button's ink clip.
    final groupRadius = _joinedRadius(rs, _panelAbove, context);

    // One SLOT per item, each carrying its own leading divider, so
    // hiding a button hides the rule that introduced it. A divider as
    // a sibling would be left behind as a hairline against the
    // overflow button.
    Widget buttonFor(int i) {
      final item = items[i];
      final button = _ToggleButton<T>(
        item: item,
        isSelected: selectedValues.contains(item.value),
        isEnabled: enabled && item.enabled,
        variant: variant,
        rs: rs,
        groupRadius: groupRadius,
        duration: duration,
        orientation: orientation,
        isFirst: i == 0,
        // The last button ON SCREEN, which is the "+N" once anything
        // has collapsed behind it. A COLUMN never collapses, so its
        // last item really is the last.
        isLast: orientation == Axis.vertical
            ? i == items.length - 1
            : i == items.length - 1 && _visibleCount >= items.length,
        // A vertical group is a PANEL, and a panel that opens without
        // taking the keyboard with it cannot be used from one.
        autofocus: orientation == Axis.vertical && i == 0,
        // The row's INNER height, not its outer one. `rs.height` is
        // the whole strip including its border; a button inside it is
        // that less the border on both sides. Forcing the outer figure
        // made every menu item two points taller than the button it
        // came out of — 40 against 38.
        fixedHeight: orientation == Axis.vertical
            ? math.max(0, rs.height - rs.borderWidth * 2)
            : null,
        onTap: () => _handleTap(item, rs),
      );
      return button;
    }

    final divides = rs.showDividers && rs.borderGradient == null;

    /// Dividers as SIBLINGS, which is what a `Flex` wants: an
    /// `expandEqual` button is an `Expanded`, and an `Expanded` inside
    /// a shrink-wrapping inner Row has no remaining space to expand
    /// into.
    List<Widget> flatChildren() => [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0 && divides) _buildDivider(rs),
        buttonFor(i),
      ],
    ];

    /// One SLOT per item for the overflow row, each carrying its own
    /// leading divider — a divider left as a sibling would survive its
    /// button being hidden and sit as a hairline against the "+N".
    ///
    /// A collapsed slot is still in the tree, because the row has to
    /// measure it to know it does not fit — so it is taken out of the
    /// FOCUS tree by hand. Tab was walking through buttons nobody
    /// could see, and stopping on each one. `ExcludeFocus` is always
    /// in the tree and only its flag moves, for the same reason the
    /// focus ring never was a conditional wrapper: adding or removing
    /// one changes the tree SHAPE at that slot and remounts the button
    /// under it.
    Widget hideable(int i, Widget child) =>
        ExcludeFocus(excluding: i >= _visibleCount, child: child);

    List<Widget> slots() => [
      for (var i = 0; i < items.length; i++)
        hideable(
          i,
          i > 0 && divides
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [_buildDivider(rs), buttonFor(i)],
                )
              : buttonFor(i),
        ),
    ];

    Widget group;
    if (orientation == Axis.vertical) {
      // A column overflows DOWNWARDS, which the page it sits on
      // already scrolls. Nothing to collapse.
      // Every item the size of a real one: the row's own height, and
      // ONE width for all of them. A column of buttons that hug their
      // labels is a menu, and this is supposed to be the strip stood
      // on its end.
      group = IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: flatChildren(),
        ),
      );
    } else if (widget.overflow == ToggleGroupOverflow.none || rs.expandEqual) {
      // `expandEqual` makes every button an `Expanded`, which fills
      // the row rather than overflowing it — there is nothing to
      // collapse, and a `ParentDataWidget` outside a `Flex` throws.
      // It squeezes instead, which is its own trade and not this one.
      group = Row(
        mainAxisSize: MainAxisSize.min,
        children: flatChildren(),
      );
    } else {
      group = ToggleOverflowRow(
        textDirection: Directionality.of(context),
        slots: slots(),
        // And the "+N" is unreachable when there is nothing behind
        // it — it sits in the tree either way.
        overflow: ExcludeFocus(
          excluding: _visibleCount >= items.length,
          child: divides && _visibleCount > 0
              // Its own leading rule, like every other slot has. It
              // had none, so a collapsed button sat flush against the
              // one before it — and when the two were both filled they
              // read as a single wide button.
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDivider(rs),
                    _buildOverflowButton(context, rs, duration),
                  ],
                )
              : _buildOverflowButton(context, rs, duration),
        ),
        maxVisible: widget.coordinateOverflow ? _scope.cap : null,
        onFits: (fits) {
          if (_fits == fits || !mounted) return;
          // A REBUILD, not just a note. How many buttons fit is
          // decided during layout, and the "+N" button and the panel
          // behind it are built before that — without this they were
          // built from the previous frame's count, so the first
          // collapse showed "+0" over an empty panel.
          setState(() => _fits = fits);
          if (widget.coordinateOverflow) _scope.report(_id, fits);
        },
      );
    }

    // Outer container with border and shadow. While the panel is open
    // the strip gives up the corner on the edge it is joined to, and
    // `AnimatedContainer` morphs it rather than snapping.
    group = AnimatedContainer(
      duration: duration,
      height: orientation == Axis.horizontal ? rs.height : null,
      decoration: BoxDecoration(
        borderRadius: groupRadius,
        border: rs.borderGradient == null
            ? Border.all(color: rs.borderColor, width: rs.borderWidth)
            : null,
        boxShadow: rs.shadow,
      ),
      // Also WITH a layer. The strip is the second clip the ink passes
      // through, and a soft edge here leaks the same hairline the
      // button's own clip was leaking.
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: group,
    );

    // Gradient border
    if (rs.borderGradient != null) {
      group = CustomPaint(
        foregroundPainter: GradientBorderPainter(
          gradient: rs.borderGradient!,
          borderRadius: rs.borderRadius,
          borderWidth: rs.borderWidth,
        ),
        child: group,
      );
    }

    // Disabled opacity
    if (!enabled) {
      group = AnimatedOpacity(
        opacity: kToggleGroupDisabledOpacity,
        duration: duration,
        child: group,
      );
    }

    // Error + status rows — the shared message column.
    if (errorText != null || messages.isNotEmpty) {
      group = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          group,
          FieldMessagesColumn(errorText: errorText, messages: messages),
        ],
      );
    }

    // Group-level semantics; per-item selected state lives on the
    // buttons themselves.
    return Semantics(
      label: semanticLabel ?? ToggleGroupStrings.semanticLabel,
      enabled: enabled,
      child: group,
    );
  }

  /// The "+N" button, and the panel it opens.
  ///
  /// The panel is the SAME widget stacked vertically — not a list, not
  /// a menu of check marks. A reader who has been tapping bordered
  /// buttons should recognise what opened, and every state the row can
  /// show (selected, disabled, icon-only) comes along for free because
  /// it IS the row.
  Widget _buildOverflowButton(
    BuildContext context,
    ResolvedToggleGroupStyle rs,
    Duration duration,
  ) {
    // Which items are hidden is decided during LAYOUT, and this is
    // built before it. The button therefore reads the count it last
    // settled on, and the panel takes everything from there on.
    final shown = _visibleCount;
    final hidden = items.length - shown;
    final hiddenItems = hidden <= 0
        ? const <ToggleGroupItem<Never>>[]
        : items.sublist(shown);

    // A selection the reader cannot see is a selection they will
    // assume is gone, so the button wears the selected state when one
    // of the items behind it is on.
    final holdsSelection = hiddenItems.any(
      (i) => selectedValues.contains(i.value),
    );

    // An ICON in an icon-only group, so the button is exactly as wide
    // as the ones beside it. "+2" is a label, and a label in a set of
    // 40-point icon squares came out half as wide again — visibly not
    // one of them.
    final isIconOnly = variant == ToggleGroupVariant.iconOnly;
    final label = isIconOnly
        ? ''
        : (widget.overflowLabelBuilder?.call(hidden) ??
              '+${hidden > 0 ? hidden : 0}');

    final button = _ToggleButton<T>(
      item: ToggleGroupItem<T>(
        value: items.isNotEmpty ? items.last.value : null as T,
        label: label,
        icon: isIconOnly ? Icons.more_horiz_rounded : null,
        tooltip: ToggleGroupStrings.overflowTooltip,
      ),
      isSelected: holdsSelection,
      isEnabled: enabled,
      variant: variant,
      rs: rs,
      groupRadius: _joinedRadius(rs, _panelAbove, context),
      duration: duration,
      orientation: Axis.horizontal,
      isFocused: _overflowFocused,
      // It is only ever at the end, and only ever there when something
      // is behind it.
      isLast: true,
      // A tap handler for the RIPPLE, and no focus at all: a
      // focusable `InkWell` consumes Enter through its own
      // `ActivateIntent`, so the button was focusable and pressing it
      // did nothing. The popup around it owns the tab stop and the
      // key; this only paints.
      onTap: () {},
      canRequestFocus: false,
    );

    return GlobalPopup(
      anchorFocusNode: _overflowFocus,
      options: GlobalPopupOptions(
        placement: GlobalPopupPlacement.bottomEnd,
        // Sized by its CONTENT, and at least as wide as the trigger.
        // The default matches the anchor, so the panel came out
        // exactly as wide as the "+N" — and inside its own border
        // every item lost another two points, 40 against the row's 42.
        width: const GlobalPopupWidth.minAnchor(),
        // Butted together, border to border. Overlapping them by a
        // border did leave one clean line, but it also read as the
        // panel sitting ON the strip rather than under it.
        gap: 0,
        // Shut, the strip takes its corner back.
        hooks: GlobalPopupHooks(onClose: () => _setPanelAbove(null)),
      ),
      overlay: (ctx, layout) {
        // The GROUP's direction, not the overlay's. An overlay entry
        // sits above the page in the tree, so `Directionality.of` on
        // its context reads the app's default — LTR even on an Arabic
        // page — and the nudge below went the wrong way.
        final rtlPanel = Directionality.of(context) == TextDirection.rtl;
        // Reported OUT of the build: the trigger rebuilds on it, and
        // the trigger is not a descendant of this overlay.
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _setPanelAbove(layout.isAbove);
        });

        final r = rs.borderRadius;
        // Opening UPWARDS, the list runs the other way: the item
        // nearest the trigger is the one that would have come first,
        // so the order still reads outward from the strip.
        final ordered = layout.isAbove
            ? hiddenItems.reversed.toList()
            : hiddenItems;
        // The panel gives up the WHOLE edge it is joined along — both
        // corners, not just the end one. The strip gives up a single
        // corner because only that corner touches the panel; the
        // panel's joined edge is entirely against the strip's side, so
        // a rounded corner at either end of it reads as a seam.
        final joined = layout.isAbove
            ? r.copyWith(bottomLeft: Radius.zero, bottomRight: Radius.zero)
            : r.copyWith(topLeft: Radius.zero, topRight: Radius.zero);

        return GlobalPopupPanel(
          layout: layout,
          // NOTHING of its own. The background is painted below,
          // exactly behind the group — a surface sized by the popup
          // left a sliver of its own colour showing past the bottom
          // edge of the group inside it.
          style: GlobalPopupSurfaceStyle(
            color: Colors.transparent,
            elevation: 0,
            padding: EdgeInsets.zero,
            borderWidth: 0,
            shadow: const [],
            // The SAME corner the panel has. The surface clips what it
            // holds, so with its own default radius it rounded the
            // joined edge back off — the group inside reported square
            // corners while the screen showed curved ones.
            borderRadius: joined,
            // And it does not clip at all: the panel's own container
            // below already clips to that shape, and a clip here would
            // shave the border off the side the panel is nudged
            // towards.
            clipBehavior: Clip.none,
          ),
          // Nudged by one BORDER towards the end.
          //
          // The popup aligns the panel to the anchor's box, and the
          // anchor is the "+N" button — which sits INSIDE the strip's
          // border. So the panel's outline landed a point short of the
          // strip's, and the join had a visible jog in it. This puts
          // the two outlines on the same line.
          child: Transform.translate(
            offset: Offset(rtlPanel ? -rs.borderWidth : rs.borderWidth, 0),
            child: AnimatedContainer(
              duration: duration,
              // The fill only — the group inside draws the border,
              // and keeping it there is what keeps a menu item exactly
              // the size of a row button. Unselected buttons are
              // transparent, so without this the page shows straight
              // through the menu.
              decoration: BoxDecoration(
                color: context.backgroundColors.container,
                borderRadius: joined,
              ),
              clipBehavior: Clip.antiAlias,
              child: GlobalToggleGroup<T>(
                items: ordered.cast<ToggleGroupItem<T>>(),
                selectedValues: selectedValues,
                onChanged: onChanged,
                variant: variant,
                // The SAME bag, so the panel inherits every colour,
                // border and divider the row has — including a caller's
                // overrides — with only the joined corner replaced.
                style: style.copyWith(borderRadius: joined),
                multiSelect: multiSelect,
                enabled: enabled,
                orientation: Axis.vertical,
                semanticLabel: semanticLabel,
              ),
            ),
          ),
        );
      },
      child: Semantics(
        button: true,
        label: ToggleGroupStrings.overflowSemanticLabel(hidden),
        child: ExcludeSemantics(child: button),
      ),
    );
  }

  /// How many buttons are on the row, after the scope has had its say.
  int get _visibleCount {
    final fits = _fits < 0 ? items.length : _fits;
    final cap = widget.coordinateOverflow ? _scope.cap : null;
    // The same one-button slack the row itself allows: holding every
    // group to the strict minimum threw away room that was already
    // there.
    final visible = cap != null && cap + 1 < fits ? cap + 1 : fits;
    return visible.clamp(0, items.length);
  }

  /// The strip's radius, less the corner it gives up to an open panel.
  ///
  /// Only the END corner: the start end of the strip is nowhere near
  /// the panel, and squaring it would just make the group look
  /// clipped. Which corner that is mirrors — in Arabic the "+N" sits
  /// at the left.
  BorderRadius _joinedRadius(
    ResolvedToggleGroupStyle rs,
    bool? panelAbove,
    BuildContext context,
  ) {
    final r = rs.borderRadius;
    if (panelAbove == null || orientation == Axis.vertical) return r;

    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The panel is joined along the top edge when it opened ABOVE.
    if (panelAbove) {
      return rtl
          ? r.copyWith(topLeft: Radius.zero)
          : r.copyWith(topRight: Radius.zero);
    }
    return rtl
        ? r.copyWith(bottomLeft: Radius.zero)
        : r.copyWith(bottomRight: Radius.zero);
  }

  Widget _buildDivider(ResolvedToggleGroupStyle rs) {
    if (orientation == Axis.horizontal) {
      return Container(width: rs.borderWidth, color: rs.borderColor);
    }
    return Container(height: rs.borderWidth, color: rs.borderColor);
  }
}

// ---------------------------------------------------------------------------
// Individual toggle button
// ---------------------------------------------------------------------------

class _ToggleButton<T> extends StatefulWidget {
  const _ToggleButton({
    required this.item,
    required this.isSelected,
    required this.isEnabled,
    required this.variant,
    required this.rs,
    required this.groupRadius,
    required this.duration,
    required this.onTap,
    required this.orientation,
    this.isFirst = false,
    this.isLast = false,
    this.isFocused = false,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.fixedHeight,
  });

  final ToggleGroupItem<T> item;
  final bool isSelected;
  final bool isEnabled;
  final ToggleGroupVariant variant;
  final ResolvedToggleGroupStyle rs;

  /// The strip's CURRENT radius — `rs.borderRadius` less any corner it
  /// has given up to an open panel. The ink is clipped to this, so a
  /// squared corner has squared ink rather than a rounded splash
  /// sitting in a cut corner.
  final BorderRadius groupRadius;
  final Duration duration;

  /// Null makes the button inert AND unfocusable — which is what the
  /// overflow "+N" wants, since the popup around it owns both.
  final VoidCallback? onTap;

  final Axis orientation;

  /// Whether this is the first or last button ON SCREEN.
  ///
  /// The focus ring wears the button's OWN shape, and only the two
  /// ends of the strip are rounded — a middle button is square on both
  /// sides. A ring with a corner on it there is visibly the wrong
  /// shape, and one with the group's full radius overhangs the fill it
  /// is supposed to sit inside.
  ///
  /// It is what is VISIBLE, not what is in the list: when the row has
  /// collapsed, the last button on screen is the "+N".
  final bool isFirst;
  final bool isLast;

  /// Focused from OUTSIDE — the collapsed "+N" has no tap handler of
  /// its own, so no `InkWell` focus to paint from, and the popup
  /// around it owns the tab stop.
  final bool isFocused;

  final bool autofocus;

  /// Whether the button's own `InkWell` may take focus. False on the
  /// "+N", where the popup owns the tab stop.
  final bool canRequestFocus;

  /// Forced height. The panel's buttons take the row's, so a menu item
  /// is the same size as the button it came out of.
  final double? fixedHeight;

  @override
  State<_ToggleButton<T>> createState() => _ToggleButtonState<T>();
}

class _ToggleButtonState<T> extends State<_ToggleButton<T>> {
  ToggleGroupItem<T> get item => widget.item;
  bool get isSelected => widget.isSelected;
  bool get isEnabled => widget.isEnabled;
  ToggleGroupVariant get variant => widget.variant;
  ResolvedToggleGroupStyle get rs => widget.rs;
  Duration get duration => widget.duration;
  VoidCallback? get onTap => widget.onTap;
  Axis get orientation => widget.orientation;

  /// The ink's corner, CORNER BY CORNER.
  ///
  /// Not `BorderRadius.horizontal`/`vertical`: those take one radius
  /// for a whole side, and the strip's own radius is not symmetric
  /// once a panel has squared one corner of it. The first item of an
  /// open menu has a rounded top-start and a square top-end, and a
  /// side-at-a-time radius rounded both.
  ///
  /// Every corner is pulled in by the group's border, so the ink is
  /// clipped to the INNER curve — clipped to the outer one a splash
  /// bulges past the border it sits inside.
  BorderRadius get _inkRadius {
    final r = widget.groupRadius;
    Radius inner(Radius corner) =>
        Radius.circular(math.max(0, corner.x - rs.borderWidth));

    final leading = widget.isFirst;
    final trailing = widget.isLast;

    if (orientation == Axis.horizontal) {
      return BorderRadius.only(
        topLeft: leading ? inner(r.topLeft) : Radius.zero,
        bottomLeft: leading ? inner(r.bottomLeft) : Radius.zero,
        topRight: trailing ? inner(r.topRight) : Radius.zero,
        bottomRight: trailing ? inner(r.bottomRight) : Radius.zero,
      );
    }
    return BorderRadius.only(
      topLeft: leading ? inner(r.topLeft) : Radius.zero,
      topRight: leading ? inner(r.topRight) : Radius.zero,
      bottomLeft: trailing ? inner(r.bottomLeft) : Radius.zero,
      bottomRight: trailing ? inner(r.bottomRight) : Radius.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Resolve colors
    final Color bg;
    final Color fg;

    if (!isEnabled) {
      bg = rs.disabledColor ?? Colors.transparent;
      fg = rs.disabledForegroundColor;
    } else if (isSelected) {
      bg = rs.selectedGradient == null ? rs.selectedColor : Colors.transparent;
      fg = rs.selectedForegroundColor;
    } else {
      bg = rs.unselectedColor;
      fg = rs.unselectedForegroundColor;
    }

    final hasIcon = item.icon != null || item.iconWidget != null;
    final isIconOnly = variant == ToggleGroupVariant.iconOnly && hasIcon;

    final textStyle =
        (isSelected ? rs.selectedTextStyle : rs.unselectedTextStyle)?.copyWith(
          color: fg,
        );

    // Content
    Widget content;
    if (isIconOnly) {
      content =
          item.iconWidget ?? Icon(item.icon, size: rs.iconSize, color: fg);
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasIcon) ...[
            item.iconWidget ?? Icon(item.icon, size: rs.iconSize, color: fg),
            SizedBox(width: rs.iconSpacing),
          ],
          Flexible(
            child: AnimatedDefaultTextStyle(
              duration: duration,
              style: textStyle ?? TextStyle(color: fg),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      );
    }

    // The FILL sits OUTSIDE the Material, and that is the whole fix.
    //
    // An `InkWell` paints its splash, hover and focus onto the nearest
    // `Material` — below everything the InkWell wraps. With the fill
    // as the InkWell's CHILD, an opaque button covered all three: no
    // ripple, no hover and no focus on any button with a background,
    // which is every selected one. Nothing was wrong with the focus;
    // it was being painted underneath.
    //
    // Turning it round — fill, then Material, then InkWell — puts the
    // ink above the fill, so `focusColor` does the job and the custom
    // ring that was here to work around it is gone.
    Widget button = AnimatedContainer(
      duration: duration,
      curve: rs.animationCurve,
      decoration: BoxDecoration(
        color: rs.selectedGradient == null || !isSelected ? bg : null,
        gradient: isSelected ? rs.selectedGradient : null,
      ),
      child: Material(
        color: Colors.transparent,
        // The ink is clipped to the button's OWN shape: the strip's
        // radius at its two ends, square in the middle. Without this a
        // splash on the first button squares off the rounded corner it
        // is sitting in.
        borderRadius: _inkRadius,
        // WITH a save layer. Plain `antiAlias` clips the ink with a
        // soft edge and leaves a hairline of the hover wash outside
        // the curve — a few pixels of bleed in exactly the corners
        // that are meant to be cut. The layer costs a composite per
        // button and is the only thing that clips ink exactly.
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          // A button with no tap of its own still RIPPLES: the "+N"
          // is pressed like any other and looked dead without it. It
          // must not take the focus though — an `InkWell` that can
          // would consume Enter through its own `ActivateIntent`, and
          // the popup around it owns both the tab stop and the key.
          canRequestFocus: widget.canRequestFocus,
          // A long press is CLAIMED here even though nothing is bound
          // to it. Unclaimed, it fell through to the popup's barrier
          // and dismissed the menu — so holding a menu item to read
          // its tooltip shut the menu instead. The tooltip itself
          // listens to raw pointer events and fires either way.
          onLongPress: isEnabled && item.tooltip != null ? () {} : null,
          autofocus: widget.autofocus,
          // Both take what READS on this button's own background —
          // `onPrimary` over a filled one, the text colour over an
          // empty one — so neither disappears on a selected item.
          hoverColor: fg.withValues(alpha: kToggleGroupHoverOpacity),
          focusColor: fg.withValues(alpha: kToggleGroupFocusOpacity),
          child: Padding(
            padding: isIconOnly
                ? const EdgeInsets.symmetric(horizontal: 12)
                : rs.itemPadding,
            child: Align(alignment: Alignment.center, child: content),
          ),
        ),
      ),
    );

    if (widget.fixedHeight != null) {
      button = SizedBox(height: widget.fixedHeight, child: button);
    }

    // The wash the `InkWell` would paint if it owned the focus. It
    // does not on the "+N", so the same colour is painted by hand
    // rather than leaving that one button with no focus state at all.
    if (widget.isFocused) {
      button = Stack(
        children: [
          button,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: kToggleGroupFocusOpacity),
                  borderRadius: _inkRadius,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Per-item semantics — the selected flag screen readers need.
    button = Semantics(
      selected: isSelected,
      enabled: isEnabled,
      label: isIconOnly ? item.label : null,
      child: button,
    );

    // Tooltip
    if (item.tooltip != null) {
      button = GlobalTooltip(message: item.tooltip!, child: button);
    }

    if (rs.expandEqual) {
      return Expanded(child: button);
    }
    return button;
  }
}

// ---------------------------------------------------------------------------
// Gradient border painter
// ---------------------------------------------------------------------------
