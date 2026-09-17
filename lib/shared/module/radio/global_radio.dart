import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../shimmer/global_shimmer.dart';
import '../text_field/text_field.dart' show FieldMessage, FieldMessagesColumn;
import '../tooltip/global_tooltip.dart';
import 'radio_models.dart';

export '../text_field/text_field.dart'
    show FieldMessage, FieldMessageType, ValidationMode;
export 'radio_form_fields.dart';
export 'radio_models.dart';
export 'theme/radio_theme.dart';

// ---------------------------------------------------------------------------
// GlobalRadio
// ---------------------------------------------------------------------------

/// A single radio button. Typically used inside a [GlobalRadioGroup].
///
/// Fully controlled — selected when [value] == [groupValue], reports
/// taps via [onChanged], never mutates. Visuals come from the themeable
/// [RadioStyle] bag (`caller > GlobalRadioTheme > defaults > context
/// colors`); haptics gate on the resolved `enableHaptic` (default
/// true). For `Form` integration use [GlobalRadioGroupFormField].
class GlobalRadio<T> extends StatefulWidget {
  const GlobalRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.variant = RadioVariant.dot,
    this.style = const RadioStyle(),
    this.enabled = true,
    this.loading = false,
    this.loadingWidget,
    this.label,
    this.labelWidget,
    this.labelStyle,
    this.labelPosition = RadioLabelPosition.trailing,
    this.description,
    this.descriptionStyle,
    this.tooltip,
    this.debounce = false,
    this.errorText,
    this.messages = const [],
    this.semanticLabel,
  });

  /// The value this radio represents.
  final T value;

  /// The currently selected value in the group.
  final T? groupValue;

  /// Called when this radio is selected.
  final ValueChanged<T>? onChanged;

  /// Visual variant of the indicator.
  final RadioVariant variant;

  /// Themeable styling — see [RadioStyle.resolve] for the merge order.
  final RadioStyle style;

  /// Whether the radio is interactive.
  final bool enabled;

  /// Shows a loading indicator. Interaction is blocked while loading.
  final bool loading;

  /// Custom loading widget (Lottie, animated SVG, etc.).
  /// When null and [loading] is true, a shimmer effect is used.
  final Widget? loadingWidget;

  /// Text label.
  final String? label;

  /// Custom label widget. Takes priority over [label].
  final Widget? labelWidget;

  /// Style for the text label.
  final TextStyle? labelStyle;

  /// Position of the label.
  final RadioLabelPosition labelPosition;

  /// Description text below the label.
  final String? description;

  /// Style for the description text.
  final TextStyle? descriptionStyle;

  /// Tooltip on long press.
  final String? tooltip;

  /// Debounce rapid taps.
  final bool debounce;

  /// Error shown below — rendered in the shared [FieldMessagesColumn]
  /// (icon + status color), like every field.
  final String? errorText;

  /// Status rows below, stacked with [errorText] and sorted
  /// error → success → warning → info.
  final List<FieldMessage> messages;

  /// Accessibility label.
  final String? semanticLabel;

  bool get _isSelected => value == groupValue;

  @override
  State<GlobalRadio<T>> createState() => _GlobalRadioState<T>();
}

class _GlobalRadioState<T> extends State<GlobalRadio<T>>
    with TickerProviderStateMixin {
  late AnimationController _selectController;
  CurvedAnimation? _curvedAnimation;
  Curve? _appliedCurve;
  late AnimationController _scaleController;
  late CurvedAnimation _scaleCurve;
  late Animation<double> _scaleAnimation;

  bool _isHovered = false;
  bool _isFocused = false;
  DateTime? _lastTap;

  /// Resolved style — materialized once per build (see build()).
  late ResolvedRadioStyle _rs;
  bool _reduceMotion = false;

  Animation<double> get _selectAnimation =>
      _curvedAnimation ?? _selectController;

  @override
  void initState() {
    super.initState();
    // Duration/curve sync to the resolved style at first build.
    _selectController = AnimationController(
      vsync: this,
      duration: kRadioAnimDuration,
      value: widget._isSelected ? 1.0 : 0.0,
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: kRadioScaleDuration,
    );
    _scaleCurve = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: kRadioScaleOnTap,
    ).animate(_scaleCurve);
  }

  void _updateCurvedAnimation(Curve curve) {
    if (_appliedCurve == curve) return;
    _appliedCurve = curve;
    _curvedAnimation?.dispose();
    _curvedAnimation = CurvedAnimation(parent: _selectController, curve: curve);
  }

  @override
  void didUpdateWidget(GlobalRadio<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._isSelected != widget._isSelected) {
      widget._isSelected
          ? _selectController.forward()
          : _selectController.reverse();
    }
  }

  @override
  void dispose() {
    _curvedAnimation?.dispose();
    _selectController.dispose();
    _scaleCurve.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled || widget.onChanged == null || widget.loading) return;
    if (widget._isSelected) return; // Already selected — no-op

    if (widget.debounce) {
      final now = DateTime.now();
      if (_lastTap != null &&
          now.difference(_lastTap!) < kRadioDebounceDuration) {
        return;
      }
      _lastTap = now;
    }

    if (_rs.enableHaptic) HapticFeedback.lightImpact();

    if (_rs.scaleOnTap && !_reduceMotion) {
      _scaleController.forward().then((_) {
        if (mounted) _scaleController.reverse();
      });
    }

    widget.onChanged!(widget.value);
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Materialize the themeable bag once per build — every visual below
    // reads _rs directly (resolved-style invariant).
    _rs = widget.style.resolve(context);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _selectController.duration = _reduceMotion
        ? Duration.zero
        : _rs.animationDuration;
    _updateCurvedAnimation(_rs.animationCurve);

    final isDisabled = !widget.enabled || widget.onChanged == null;
    final isSelected = widget._isSelected;

    var radio = _buildRadio(isSelected, isDisabled);

    // Scale animation
    if (_rs.scaleOnTap && !_reduceMotion) {
      radio = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: radio,
      );
    }

    // Hover / focus
    radio = _buildHoverFocusWrapper(radio, isDisabled, isSelected);

    // Label
    final hasLabel =
        widget.label != null ||
        widget.labelWidget != null ||
        widget.description != null;
    if (hasLabel) {
      radio = _buildWithLabel(context, radio, isDisabled);
    }

    // Error + status rows — the shared message column (icon + status
    // color), never a bare string.
    if (widget.errorText != null || widget.messages.isNotEmpty) {
      radio = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          radio,
          FieldMessagesColumn(
            errorText: widget.errorText,
            messages: widget.messages,
          ),
        ],
      );
    }

    // Tooltip
    if (widget.tooltip != null) {
      radio = GlobalTooltip(message: widget.tooltip!, child: radio);
    }

    // Semantics
    return Semantics(
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      enabled: !isDisabled,
      label: widget.semanticLabel ?? widget.label ?? RadioStrings.semanticLabel,
      onTap: isDisabled ? null : _handleTap,
      excludeSemantics: true,
      child: radio,
    );
  }

  // ─── Hover / Focus ─────────────────────────────────────────

  Widget _buildHoverFocusWrapper(
    Widget child,
    bool isDisabled,
    bool isSelected,
  ) {
    final hoverColor =
        _rs.hoverColor ??
        _rs.selectedColor.withValues(alpha: kRadioHoverOpacity);
    final focusColor =
        _rs.focusColor ??
        _rs.selectedColor.withValues(alpha: kRadioFocusOpacity);

    return Actions(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _handleTap();
            return null;
          },
        ),
      },
      child: FocusableActionDetector(
        enabled: !isDisabled,
        mouseCursor: isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _isHovered = v),
        onShowFocusHighlight: (v) => setState(() => _isFocused = v),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        child: (_isHovered || _isFocused) && !isDisabled
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  child,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedContainer(
                        duration: AppDurations.fast,
                        decoration: BoxDecoration(
                          color: _isFocused ? focusColor : hoverColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : child,
      ),
    );
  }

  // ─── Radio indicator ───────────────────────────────────────

  Widget _buildRadio(bool isSelected, bool isDisabled) {
    final disabledOverride = isDisabled ? _rs.disabledColor : null;
    final selectedColor = disabledOverride ?? _rs.selectedColor;
    final borderColor = disabledOverride ?? _rs.borderColor;
    final selectedBorderColor = disabledOverride ?? _rs.selectedBorderColor;

    final effectiveBorder = isSelected ? selectedBorderColor : borderColor;
    final effectiveBorderGradient = isSelected
        ? _rs.selectedBorderGradient
        : _rs.borderGradient;
    final effectiveShadow = isSelected ? _rs.selectedShadow : _rs.shadow;

    final loadingContent = widget.loading ? _buildLoadingContent() : null;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: isDisabled ? kRadioDisabledOpacity : 1.0,
        duration: _selectController.duration!,
        child: AnimatedBuilder(
          animation: _selectAnimation,
          builder: (_, _) {
            final t = _selectAnimation.value;
            final bdrColor = Color.lerp(borderColor, effectiveBorder, t)!;

            // Background fill for filled variant
            Color? bgColor;
            Gradient? bgGradient;
            if (widget.variant == RadioVariant.filled) {
              bgColor = _rs.selectedGradient == null
                  ? Color.lerp(_rs.unselectedColor, selectedColor, t)
                  : null;
              bgGradient = _rs.selectedGradient != null
                  ? _lerpGradientOpacity(_rs.selectedGradient!, t)
                  : null;
            }

            Widget circle = Container(
              width: _rs.size,
              height: _rs.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgGradient == null
                    ? (bgColor ?? _rs.unselectedColor)
                    : null,
                gradient: bgGradient,
                border: effectiveBorderGradient == null
                    ? Border.all(color: bdrColor, width: _rs.borderWidth)
                    : null,
                boxShadow: effectiveShadow,
              ),
              child: Center(
                child: loadingContent ?? _buildIndicator(t, selectedColor),
              ),
            );

            // Gradient border
            if (effectiveBorderGradient != null) {
              circle = CustomPaint(
                foregroundPainter: _GradientBorderPainter(
                  gradient: effectiveBorderGradient,
                  size: _rs.size,
                  borderWidth: _rs.borderWidth,
                ),
                child: circle,
              );
            }

            return circle;
          },
        ),
      ),
    );
  }

  Widget _buildIndicator(double t, Color selectedColor) {
    switch (widget.variant) {
      case RadioVariant.dot:
        final dotSize = _rs.size * _rs.dotScale;
        return Transform.scale(
          scale: t,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(Colors.transparent, _rs.dotColor, t),
            ),
          ),
        );

      case RadioVariant.filled:
        return Transform.scale(
          scale: t,
          child: Icon(
            _rs.checkIcon,
            size: _rs.checkIconSize,
            color: _rs.onPrimary.withValues(alpha: t),
          ),
        );

      case RadioVariant.checkmark:
        return Transform.scale(
          scale: t,
          child: Icon(
            _rs.checkIcon,
            size: _rs.checkIconSize,
            color: selectedColor.withValues(alpha: t),
          ),
        );
    }
  }

  Widget _buildLoadingContent() {
    if (widget.loadingWidget != null) {
      return SizedBox(
        width: _rs.checkIconSize,
        height: _rs.checkIconSize,
        child: widget.loadingWidget,
      );
    }
    return ClipOval(
      child: GlobalShimmer.wrap(
        baseColor: Color.lerp(_rs.selectedColor, Colors.black, 0.1)!,
        highlightColor: Color.lerp(_rs.selectedColor, Colors.white, 0.3)!,
        period: AppDurations.slow,
        shape: ShimmerShape.circle,
        child: SizedBox(width: _rs.size, height: _rs.size),
      ),
    );
  }

  // ─── Gradient lerp ─────────────────────────────────────────

  Gradient _lerpGradientOpacity(Gradient gradient, double t) {
    if (gradient is LinearGradient) {
      return LinearGradient(
        colors: gradient.colors.map((c) => c.withValues(alpha: t)).toList(),
        stops: gradient.stops,
        begin: gradient.begin,
        end: gradient.end,
      );
    }
    if (gradient is RadialGradient) {
      return RadialGradient(
        colors: gradient.colors.map((c) => c.withValues(alpha: t)).toList(),
        stops: gradient.stops,
        center: gradient.center,
        radius: gradient.radius,
      );
    }
    if (gradient is SweepGradient) {
      return SweepGradient(
        colors: gradient.colors.map((c) => c.withValues(alpha: t)).toList(),
        stops: gradient.stops,
        center: gradient.center,
        startAngle: gradient.startAngle,
        endAngle: gradient.endAngle,
      );
    }
    return gradient;
  }

  // ─── Label ─────────────────────────────────────────────────

  Widget _buildWithLabel(BuildContext context, Widget radio, bool isDisabled) {
    final labelW =
        widget.labelWidget ??
        (widget.label != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label!,
                    style:
                        widget.labelStyle ??
                        context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDisabled
                              ? context.textColors.disabled
                              : null,
                        ),
                  ),
                  if (widget.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.description!,
                      style:
                          widget.descriptionStyle ??
                          context.textTheme.bodySmall?.copyWith(
                            color: context.textColors.secondary,
                          ),
                    ),
                  ],
                ],
              )
            : null);

    if (labelW == null) return radio;

    final radioWithoutTap = IgnorePointer(child: radio);

    final children = widget.labelPosition == RadioLabelPosition.trailing
        ? [
            radioWithoutTap,
            const SizedBox(width: kRadioLabelSpacing),
            Flexible(child: labelW),
          ]
        : [
            Flexible(child: labelW),
            const SizedBox(width: kRadioLabelSpacing),
            radioWithoutTap,
          ];

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GlobalRadioGroup
// ---------------------------------------------------------------------------

/// An item in a [GlobalRadioGroup].
@immutable
class RadioGroupItem<T> {
  const RadioGroupItem({
    required this.value,
    required this.label,
    this.description,
    this.enabled = true,
    this.labelWidget,
  });

  final T value;
  final String label;
  final String? description;
  final bool enabled;
  final Widget? labelWidget;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadioGroupItem<T> &&
          other.value == value &&
          other.label == label;

  @override
  int get hashCode => Object.hash(value, label);
}

/// A group of radio buttons with single-select behavior.
class GlobalRadioGroup<T> extends StatelessWidget {
  const GlobalRadioGroup({
    super.key,
    required this.items,
    required this.groupValue,
    required this.onChanged,
    this.variant = RadioVariant.dot,
    this.style = const RadioStyle(),
    this.spacing = kRadioGroupSpacing,
    this.direction = Axis.vertical,
    this.enabled = true,
    this.debounce = false,
    this.errorText,
    this.messages = const [],
    this.labelPosition = RadioLabelPosition.trailing,
  });

  /// Available items.
  final List<RadioGroupItem<T>> items;

  /// Currently selected value.
  final T? groupValue;

  /// Called when selection changes.
  final ValueChanged<T> onChanged;

  /// Visual variant.
  final RadioVariant variant;

  /// Themeable style applied to all radios.
  final RadioStyle style;

  /// Spacing between items.
  final double spacing;

  /// Layout direction.
  final Axis direction;

  /// Whether the entire group is enabled.
  final bool enabled;

  /// Debounce for all children.
  final bool debounce;

  /// Error shown below the group — shared message column treatment.
  final String? errorText;

  /// Status rows below the group.
  final List<FieldMessage> messages;

  /// Label position for all items.
  final RadioLabelPosition labelPosition;

  @override
  Widget build(BuildContext context) {
    final children = items.map((item) {
      final isItemEnabled = enabled && item.enabled;

      return GlobalRadio<T>(
        value: item.value,
        groupValue: groupValue,
        onChanged: isItemEnabled ? onChanged : null,
        variant: variant,
        style: style,
        enabled: isItemEnabled,
        label: item.labelWidget == null ? item.label : null,
        labelWidget: item.labelWidget,
        description: item.description,
        labelPosition: labelPosition,
        debounce: debounce,
      );
    }).toList();

    Widget group;
    if (direction == Axis.vertical) {
      group = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: _intersperse(children, SizedBox(height: spacing)),
      );
    } else {
      group = Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children,
      );
    }

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

    return group;
  }

  List<Widget> _intersperse(List<Widget> widgets, Widget separator) {
    if (widgets.length <= 1) return widgets;
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) result.add(separator);
    }
    return result;
  }
}

// ---------------------------------------------------------------------------
// GlobalRadioTile
// ---------------------------------------------------------------------------

/// A full-width tappable tile with an embedded radio — like a ListTile.
class GlobalRadioTile<T> extends StatelessWidget {
  const GlobalRadioTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.variant = RadioVariant.dot,
    this.style = const RadioStyle(),
    this.enabled = true,
    this.loading = false,
    this.loadingWidget,
    this.radioPosition = RadioLabelPosition.trailing,
    this.contentPadding,
    this.tileColor,
    this.selectedTileColor,
    this.borderRadius,
    this.border,
    this.dense = false,
    this.semanticLabel,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final RadioVariant variant;
  final RadioStyle style;
  final bool enabled;
  final bool loading;
  final Widget? loadingWidget;
  final RadioLabelPosition radioPosition;
  final EdgeInsets? contentPadding;
  final Color? tileColor;
  final Color? selectedTileColor;
  final BorderRadius? borderRadius;

  /// What the row announces.
  ///
  /// Without it the inner radio falls back to the generic "Radio
  /// option" — so a tile whose title is a rich widget (an icon beside
  /// two lines, a flag beside a name) had the SELECTED state sitting
  /// on a node that never said which option it belonged to.
  final String? semanticLabel;
  final BoxBorder? border;
  final bool dense;

  bool get _isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final rs = style.resolve(context);
    final isDisabled = !enabled || onChanged == null;
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(context.radii.md);
    final effectiveBg = _isSelected
        ? (selectedTileColor ?? rs.selectedColor.withValues(alpha: 0.05))
        : (tileColor ?? Colors.transparent);
    final effectivePadding =
        contentPadding ??
        EdgeInsets.symmetric(
          vertical: dense ? 8 : kRadioTileVerticalPadding,
          horizontal: kRadioTileHorizontalPadding,
        );

    // The radio is non-interactive here — the tile's InkWell handles the tap
    final radio = IgnorePointer(
      child: GlobalRadio<T>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        variant: variant,
        style: style,
        enabled: enabled,
        loading: loading,
        loadingWidget: loadingWidget,
        semanticLabel: semanticLabel,
      ),
    );

    final titleContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle(
          style: context.textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w500,
            color: isDisabled ? context.textColors.disabled : null,
          ),
          child: title,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          DefaultTextStyle(
            style: context.textTheme.bodySmall!.copyWith(
              color: context.textColors.secondary,
            ),
            child: subtitle!,
          ),
        ],
      ],
    );

    final contentChildren = <Widget>[];

    if (radioPosition == RadioLabelPosition.leading) {
      contentChildren.add(radio);
      contentChildren.add(const SizedBox(width: kRadioLabelSpacing));
    }

    if (leading != null) {
      contentChildren.add(leading!);
      contentChildren.add(SizedBox(width: context.spacing.sm));
    }

    contentChildren.add(Expanded(child: titleContent));

    if (trailing != null) {
      contentChildren.add(SizedBox(width: context.spacing.xs));
      contentChildren.add(trailing!);
    }

    if (radioPosition == RadioLabelPosition.trailing) {
      contentChildren.add(const SizedBox(width: kRadioLabelSpacing));
      contentChildren.add(radio);
    }

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: rs.animationDuration,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: effectiveRadius,
          border: border,
        ),
        child: InkWell(
          onTap: isDisabled
              ? null
              : () {
                  if (rs.enableHaptic) HapticFeedback.lightImpact();
                  onChanged?.call(value);
                },
          borderRadius: effectiveRadius,
          child: AnimatedOpacity(
            opacity: isDisabled ? kRadioDisabledOpacity : 1.0,
            duration: rs.animationDuration,
            child: Padding(
              padding: effectivePadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: contentChildren,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient border painter (circle)
// ---------------------------------------------------------------------------

class _GradientBorderPainter extends CustomPainter {
  _GradientBorderPainter({
    required this.gradient,
    required this.size,
    required this.borderWidth,
  });

  final Gradient gradient;
  final double size;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return;
    final rect = Offset.zero & canvasSize;
    final radius = canvasSize.shortestSide / 2 - borderWidth / 2;
    canvas.drawCircle(
      rect.center,
      radius,
      Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_GradientBorderPainter old) =>
      gradient != old.gradient ||
      size != old.size ||
      borderWidth != old.borderWidth;
}
