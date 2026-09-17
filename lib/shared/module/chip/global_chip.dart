import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/painters/gradient_border_painter.dart';
import '../badge/global_badge.dart';
import '../progress/global_progress.dart';
import '../tooltip/global_tooltip.dart';
import 'chip_models.dart';
import 'theme/chip_theme.dart';

export 'chip_models.dart';
export 'global_chip_strip.dart';
export 'theme/chip_theme.dart';

/// Marks the checkmark, so a test can find it without matching on
/// `ScaleTransition` — Material mounts its own.
const kChipCheckmarkKey = ValueKey<String>('chip-checkmark');

/// Marks the delete control.
const kChipDeleteKey = ValueKey<String>('chip-delete');

/// Marks the gradient chip's painted surface.
const kChipGradientSurfaceKey = ValueKey<String>('chip-gradient-surface');

/// Marks the icon theme wrapped around the leading and trailing slots.
const kChipIconThemeKey = ValueKey<String>('chip-icon-theme');

// ---------------------------------------------------------------------------
// GlobalChip
// ---------------------------------------------------------------------------

/// A chip: filter, choice, tag or static label.
///
/// ```dart
/// GlobalChip(label: 'All')                                    // static
/// GlobalChip(label: 'Books', selected: s, onSelected: (v) {})  // filter
/// GlobalChip.tag(label: 'flutter', onDeleted: remove)          // tag
/// ```
///
/// Visual configuration is the themeable bag [ChipStyle]; behaviour and
/// content stay as named parameters. See the module's CLAUDE.md.
class GlobalChip extends StatefulWidget {
  const GlobalChip({
    required this.label,
    super.key,
    this.selected = false,
    this.onSelected,
    this.onPressed,
    this.onDeleted,
    this.onLongPress,
    this.enabled = true,
    this.variant = ChipVariant.filled,
    this.style = const ChipStyle(),
    this.avatar,
    this.trailing,
    this.count,
    this.maxWidth,
    this.loading = false,
    this.animateDelete = false,
    this.showCheckmark = false,
    this.deleteIcon,
    this.tooltip,
    this.semanticLabel,
  }) : assert(
         onSelected == null || onPressed == null,
         'a chip is a choice or an action, not both',
       );

  // ─── Core ──────────────────────────────────────────────────

  final String label;
  final bool selected;

  /// Makes this a CHOICE chip: it carries a selected state and reports
  /// the value it is moving to.
  final ValueChanged<bool>? onSelected;

  /// Makes this an ACTION chip: it does something and has no state.
  ///
  /// Separate from [onSelected] on purpose — a tag you tap to edit is
  /// not a filter you tap to choose, and announcing one as the other
  /// tells a screen reader the chip has a selected state it does not.
  /// Material splits the same way; pass at most one.
  final VoidCallback? onPressed;

  final VoidCallback? onDeleted;
  final VoidCallback? onLongPress;
  final bool enabled;
  final ChipVariant variant;

  /// Themeable style bag. Merges over `GlobalChipTheme`.
  final ChipStyle style;

  // ─── Content ───────────────────────────────────────────────

  final Widget? avatar;
  final Widget? trailing;

  /// Built-in count pill after the label.
  final int? count;

  /// Max width — the label truncates with an ellipsis past it.
  final double? maxWidth;

  /// Shows a spinner in place of the avatar.
  final bool loading;

  /// Whether the chip shrinks away before [onDeleted] fires.
  final bool animateDelete;

  /// Whether a selected chip shows a checkmark. Selectable chips only —
  /// a checkmark on a chip that cannot be chosen is a lie.
  final bool showCheckmark;

  /// Replaces the default ✕.
  final Widget? deleteIcon;

  final String? tooltip;

  /// Spoken instead of the label.
  final String? semanticLabel;

  // ─── Convenience factories ─────────────────────────────────

  /// A removable tag: tonal, no selection.
  factory GlobalChip.tag({
    required String label,
    Key? key,
    Widget? avatar,
    VoidCallback? onDeleted,
    ChipStyle style = const ChipStyle(),
    bool animateDelete = false,
  }) => GlobalChip(
    key: key,
    label: label,
    avatar: avatar,
    onDeleted: onDeleted,
    variant: ChipVariant.tonal,
    style: style,
    animateDelete: animateDelete,
  );

  /// A choice chip that keeps its outline in both states.
  factory GlobalChip.outlined({
    required String label,
    required bool selected,
    Key? key,
    ValueChanged<bool>? onSelected,
    Widget? avatar,
    ChipStyle style = const ChipStyle(),
    bool showCheckmark = false,
  }) => GlobalChip(
    key: key,
    label: label,
    selected: selected,
    onSelected: onSelected,
    avatar: avatar,
    variant: ChipVariant.outlined,
    style: style,
    showCheckmark: showCheckmark,
  );

  /// Fully rounded. Geometry only — the variant still decides colour.
  factory GlobalChip.pill({
    required String label,
    Key? key,
    bool selected = false,
    ValueChanged<bool>? onSelected,
    Widget? avatar,
    ChipStyle style = const ChipStyle(),
    ChipVariant variant = ChipVariant.filled,
  }) => GlobalChip(
    key: key,
    label: label,
    selected: selected,
    onSelected: onSelected,
    avatar: avatar,
    variant: variant,
    style: ChipStyle.pill.mergedWith(style),
  );

  /// A gradient surface in both states, which takes the hand-painted
  /// build path.
  factory GlobalChip.gradient({
    required String label,
    required Gradient gradient,
    Key? key,
    bool selected = false,
    ValueChanged<bool>? onSelected,
    Widget? avatar,
    Widget? trailing,
    ChipStyle style = const ChipStyle(),
  }) => GlobalChip(
    key: key,
    label: label,
    selected: selected,
    onSelected: onSelected,
    avatar: avatar,
    trailing: trailing,
    style: ChipStyle(
      backgroundGradient: gradient,
      selectedBackgroundGradient: gradient,
    ).mergedWith(style),
  );

  @override
  State<GlobalChip> createState() => _GlobalChipState();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _GlobalChipState extends State<GlobalChip> with TickerProviderStateMixin {
  late final AnimationController _checkmark;
  late final Animation<double> _checkmarkScale;
  late final Animation<double> _checkmarkReveal;
  late final AnimationController _delete;
  late final Animation<double> _deleteAnimation;
  bool _deleteInProgress = false;

  @override
  void initState() {
    super.initState();
    _checkmark = AnimationController(
      duration: ChipDefaults.animationDuration,
      vsync: this,
      value: widget.selected && widget.showCheckmark ? 1.0 : 0.0,
    );
    // Two curves off one controller. The SPRING is only safe on the
    // scale: elasticOut overshoots past 1, which a width and an opacity
    // both refuse — SizeTransition would jitter and Opacity asserts.
    _checkmarkScale = CurvedAnimation(
      parent: _checkmark,
      curve: Curves.elasticOut,
    );
    _checkmarkReveal = CurvedAnimation(
      parent: _checkmark,
      curve: Curves.easeOut,
    );
    _delete = AnimationController(
      duration: ChipDefaults.deleteAnimationDuration,
      vsync: this,
    );
    _deleteAnimation = CurvedAnimation(parent: _delete, curve: Curves.easeIn);
  }

  @override
  void didUpdateWidget(GlobalChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showCheckmark || widget.selected == oldWidget.selected) return;

    if (_resolve().animateCheckmark) {
      if (widget.selected) {
        _checkmark.forward(from: 0);
      } else {
        _checkmark.reverse();
      }
    } else {
      _checkmark.value = widget.selected ? 1.0 : 0.0;
    }
  }

  @override
  void dispose() {
    _checkmark.dispose();
    _delete.dispose();
    super.dispose();
  }

  // ─── Internal ──────────────────────────────────────────────

  ResolvedChipStyle _resolve() => widget.style.resolve(
    context,
    variant: widget.variant,
    selected: widget.selected,
    enabled: widget.enabled,
    disableAnimations: MediaQuery.disableAnimationsOf(context),
  );

  bool get _isInteractive => widget.enabled && widget.onSelected != null;

  bool get _isPressable => widget.enabled && widget.onPressed != null;

  void _handlePressed() {
    if (_resolve().enableHaptic) HapticFeedback.selectionClick();
    widget.onPressed?.call();
  }

  /// A checkmark only renders on a chip that can actually be chosen.
  bool get _showsCheckmark =>
      widget.showCheckmark && widget.onSelected != null && !widget.loading;

  void _handleSelected(bool value) {
    if (_resolve().enableHaptic) HapticFeedback.selectionClick();
    widget.onSelected?.call(value);
  }

  void _handleDelete() {
    // Rapid taps would otherwise fire onDeleted once per tap while the
    // shrink is still running.
    if (_deleteInProgress) return;
    _deleteInProgress = true;

    if (!widget.animateDelete) {
      widget.onDeleted?.call();
      _deleteInProgress = false;
      return;
    }
    _delete.duration = _resolve().deleteAnimationDuration;
    _delete.forward().then((_) {
      if (!mounted) return;
      widget.onDeleted?.call();
      _deleteInProgress = false;
    });
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rs = _resolve();

    var chip = rs.hasGradient ? _gradientChip(rs) : _materialChip(rs);

    if (widget.animateDelete) chip = _wrapDeleteAnimation(chip);
    if (widget.maxWidth != null) {
      chip = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth!),
        child: chip,
      );
    }
    if (widget.tooltip != null) {
      chip = GlobalTooltip(message: widget.tooltip!, child: chip);
    }

    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      button: widget.onSelected != null || widget.onPressed != null,
      // An ACTION chip has no selected state, and saying it does tells
      // a screen reader about a state the chip can never enter.
      selected: widget.onSelected != null ? widget.selected : null,
      enabled: widget.enabled,
      excludeSemantics: true,
      child: chip,
    );
  }

  Widget _wrapDeleteAnimation(Widget chip) => AnimatedBuilder(
    animation: _deleteAnimation,
    builder: (context, child) {
      // Two halves: fade and shrink in place, THEN collapse the space.
      // Collapsing first would yank the chips after it before this one
      // has visibly gone.
      final t = _deleteAnimation.value;
      final scale = t < 0.5 ? 1.0 - t : 0.0;
      final opacity = t < 0.5 ? 1.0 - t * 2 : 0.0;
      final sizeFactor = t < 0.5 ? 1.0 : 1.0 - (t - 0.5) * 2;
      return SizeTransition(
        sizeFactor: AlwaysStoppedAnimation(sizeFactor.clamp(0.0, 1.0)),
        axis: Axis.horizontal,
        child: Transform.scale(
          scale: scale.clamp(0.0, 1.0),
          child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: child),
        ),
      );
    },
    child: chip,
  );

  // ─── Pieces ────────────────────────────────────────────────

  Widget? _leading(ResolvedChipStyle rs) {
    if (widget.loading) {
      return SizedBox(
        width: ChipDefaults.loadingSize,
        height: ChipDefaults.loadingSize,
        child: GlobalProgress.loading(
          type: ProgressType.circular,
          style: ProgressStyle(
            thickness: ChipDefaults.loadingStrokeWidth,
            color: rs.foreground,
          ),
        ),
      );
    }
    return widget.avatar == null ? null : _tinted(widget.avatar!, rs);
  }

  /// Puts a slot's glyphs on the SAME colour as the label.
  ///
  /// A caller hands in a bare `Icon`, which otherwise inherits whatever
  /// ambient `IconTheme` the page has — so a selected chip showed a
  /// white label beside a dark icon. `IconTheme.merge` is the seam
  /// Material's own chip uses, and it still loses to an `Icon` that was
  /// given an explicit colour, which is how a caller opts out.
  Widget _tinted(Widget slot, ResolvedChipStyle rs) => IconTheme.merge(
    key: kChipIconThemeKey,
    data: IconThemeData(color: rs.foreground, size: ChipDefaults.iconSize),
    child: slot,
  );

  /// The tick, and the SPACE it takes.
  ///
  /// A `ScaleTransition` at scale 0 still occupies its full width — it
  /// is a paint-time transform — so an unselected chip reserved the
  /// icon plus its gap and sat visibly wider than a chip with no
  /// checkmark at all. The size collapses with the reveal, so the chip
  /// grows into the tick as it springs in.
  Widget _checkmarkWidget(ResolvedChipStyle rs) => SizeTransition(
    key: kChipCheckmarkKey,
    axis: Axis.horizontal,
    // Grows from the START edge, so the label stays put and the tick
    // arrives beside it rather than pushing out from the middle.
    alignment: AlignmentDirectional.centerStart,
    sizeFactor: _checkmarkReveal,
    child: ScaleTransition(
      scale: _checkmarkScale,
      child: FadeTransition(
        opacity: _checkmarkReveal,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            end: ChipDefaults.trailingGap,
          ),
          child: Icon(
            Icons.check,
            size: ChipDefaults.checkmarkSize,
            color: rs.checkmarkColor,
          ),
        ),
      ),
    ),
  );

  Widget _deleteWidget(ResolvedChipStyle rs) => IconTheme(
    data: IconThemeData(
      color: rs.deleteIconColor,
      size: ChipDefaults.deleteIconSize,
    ),
    child:
        widget.deleteIcon ??
        Icon(
          Icons.close,
          size: ChipDefaults.deleteIconSize,
          color: rs.deleteIconColor,
        ),
  );

  /// Label, plus the count pill and any trailing widget.
  Widget _labelRow(ResolvedChipStyle rs) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (_showsCheckmark) _checkmarkWidget(rs),
      Flexible(
        child: Text(
          widget.label,
          style: rs.labelStyle,
          overflow: widget.maxWidth != null ? TextOverflow.ellipsis : null,
          maxLines: 1,
        ),
      ),
      if (widget.count != null) ...[
        const SizedBox(width: ChipDefaults.countGap),
        // The same pill every other surface uses. It was hand-rolled
        // here — one more copy of the geometry the badge sweep pulled
        // together — so a chip count read at a different size from an
        // unread count sitting beside it.
        GlobalBadge.standalone(
          count: widget.count,
          style: chipCountBadgeStyle(rs),
        ),
      ],
      if (widget.trailing != null) ...[
        const SizedBox(width: ChipDefaults.trailingGap),
        _tinted(widget.trailing!, rs),
      ],
    ],
  );

  // ─── Material path ─────────────────────────────────────────

  Widget _materialChip(ResolvedChipStyle rs) {
    // RawChip, not Chip / ChoiceChip. Those are thin wrappers that each
    // cover ONE of selection and deletion, and a chip doing both used to
    // be built as a ChoiceChip with the ✕ pushed inside its label —
    // where `RawChip` wraps the label in an `IgnorePointer` so the whole
    // surface is one tap target. The ✕ was decoration: tapping it did
    // nothing. RawChip takes `onSelected` AND `onDeleted` together and
    // gives the delete control its own hit target.
    Widget chip = RawChip(
      label: _labelRow(rs),
      avatar: _leading(rs),
      isEnabled: widget.enabled,
      selected: widget.selected,
      onSelected: _isInteractive ? _handleSelected : null,
      onPressed: _isPressable ? _handlePressed : null,
      onDeleted: widget.onDeleted != null ? _handleDelete : null,
      deleteIcon: KeyedSubtree(key: kChipDeleteKey, child: _deleteWidget(rs)),
      deleteIconColor: rs.deleteIconColor,
      backgroundColor: rs.background,
      selectedColor: rs.selectedBackground,
      disabledColor: rs.disabledBackground,
      labelPadding: rs.labelPadding,
      padding: rs.padding,
      elevation: rs.elevation,
      pressElevation: rs.elevation,
      shadowColor: rs.shadowColor,
      // Ours is animated and coloured from the bag; Material's would be
      // a second tick beside it.
      showCheckmark: false,
      shape: rs.shape,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    if (widget.onLongPress != null) {
      chip = GestureDetector(onLongPress: widget.onLongPress, child: chip);
    }

    if (!rs.hasShadow) return chip;
    return AnimatedContainer(
      duration: rs.animationDuration,
      curve: rs.animationCurve,
      decoration: BoxDecoration(
        borderRadius: rs.borderRadius,
        boxShadow: [
          BoxShadow(
            color: rs.shadowColor!,
            blurRadius: rs.shadowBlur,
            offset: Offset(0, rs.elevation),
          ),
        ],
      ),
      child: chip,
    );
  }

  // ─── Gradient path ─────────────────────────────────────────

  /// A gradient of one colour, so a flat state can be interpolated
  /// against a real gradient instead of crossfading with it.
  static LinearGradient _flat(Color color) =>
      LinearGradient(colors: [color, color]);

  Widget _gradientChip(ResolvedChipStyle rs) {
    final leading = _leading(rs);

    Widget content = Padding(
      // The bag's padding is honoured here too. It used to be a
      // hard-coded 12/8, so `padding:` was silently ignored the moment
      // a caller added a gradient.
      padding: rs.padding ?? ChipDefaults.gradientPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 8)],
          _labelRow(rs),
          if (widget.onDeleted != null) ...[
            const SizedBox(width: ChipDefaults.trailingGap),
            GestureDetector(
              key: kChipDeleteKey,
              onTap: _handleDelete,
              child: _deleteWidget(rs),
            ),
          ],
        ],
      ),
    );

    if (_isInteractive || _isPressable) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: rs.borderRadius,
          onTap: _isPressable
              ? _handlePressed
              : () => _handleSelected(!widget.selected),
          onLongPress: widget.onLongPress,
          child: content,
        ),
      );
    } else if (widget.onLongPress != null) {
      content = GestureDetector(
        onLongPress: widget.onLongPress,
        child: content,
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedContainer(
            key: kChipGradientSurfaceKey,
            duration: rs.animationDuration,
            curve: rs.animationCurve,
            decoration: BoxDecoration(
              // ALWAYS a gradient, even when the state has none of its
              // own. A chip that gradients on selection only was
              // swapping `gradient` for `color` between states, and
              // `BoxDecoration.lerp` fades one out while fading the
              // other in — so mid-flight it was a half-transparent
              // gradient over a half-transparent fill, which reads as a
              // grey flash. Two gradients interpolate cleanly.
              gradient:
                  rs.backgroundGradient ??
                  _flat(
                    widget.selected ? rs.selectedBackground : rs.background,
                  ),
              borderRadius: rs.borderRadius,
              border: rs.borderGradient == null && rs.border != BorderSide.none
                  ? Border.fromBorderSide(rs.border)
                  : null,
              boxShadow: rs.hasShadow
                  ? [
                      BoxShadow(
                        color: rs.shadowColor!,
                        blurRadius: rs.shadowBlur,
                        offset: Offset(0, rs.elevation),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
        if (rs.borderGradient != null)
          Positioned.fill(
            child: CustomPaint(
              painter: GradientBorderPainter(
                gradient: rs.borderGradient!,
                borderRadius: rs.borderRadius,
                borderWidth: rs.borderWidth,
              ),
            ),
          ),
        content,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Count pill
// ---------------------------------------------------------------------------

/// The badge style a chip's count pill uses.
///
/// Top-level so the mapping from chip state to badge style lives in one
/// place: a chip count is a NEUTRAL number, so it takes a wash of the
/// chip's own foreground rather than the badge's error red.
BadgeStyle chipCountBadgeStyle(ResolvedChipStyle rs) => BadgeStyle(
  backgroundColor: rs.countBackground,
  foregroundColor: rs.foreground,
  fontSize: ChipDefaults.countFontSize,
  borderWidth: 0,
);

// ---------------------------------------------------------------------------
// Gradient border painter
// ---------------------------------------------------------------------------
