import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../../../core/painters/gradient_border_painter.dart';
import '../../../core/tokens/extensions.dart';
import '../divider/global_divider.dart';
import '../shimmer/global_shimmer.dart';
import '../text_field/text_field.dart' show FieldMessage, FieldMessagesColumn;
import '../tooltip/global_tooltip.dart';
import 'checkbox_models.dart';

export '../text_field/text_field.dart'
    show FieldMessage, FieldMessageType, ValidationMode;
export 'checkbox_form_fields.dart';
export 'checkbox_models.dart';
export 'theme/checkbox_theme.dart';

// ---------------------------------------------------------------------------
// GlobalCheckbox
// ---------------------------------------------------------------------------

/// Tri-state checkbox with standard / circle variants (for a
/// switch/toggle pill use the dedicated `GlobalSwitch` module).
///
/// Fully controlled — displays [value] as passed and reports taps via
/// [onChanged], never mutates. Visuals come from the themeable
/// [CheckboxStyle] bag (`caller > GlobalCheckboxTheme > defaults >
/// context colors`); haptics gate on the resolved `enableHaptic`
/// (default true). For `Form` integration use [GlobalCheckboxFormField]
/// / [GlobalCheckboxGroupFormField].
class GlobalCheckbox extends StatefulWidget {
  const GlobalCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.variant = CheckboxVariant.standard,
    this.style = const CheckboxStyle(),
    this.enabled = true,
    this.loading = false,
    this.loadingWidget,
    this.label,
    this.labelWidget,
    this.labelStyle,
    this.labelPosition = CheckboxLabelPosition.trailing,
    this.description,
    this.descriptionStyle,
    this.tooltip,
    this.debounce = false,
    this.errorText,
    this.messages = const [],
    this.semanticLabel,
  });

  /// Current value (checked, unchecked, or indeterminate).
  final CheckboxValue value;

  /// Called when the user taps the checkbox.
  final ValueChanged<CheckboxValue>? onChanged;

  /// Visual variant.
  final CheckboxVariant variant;

  /// Themeable styling — see [CheckboxStyle.resolve] for the merge
  /// order.
  final CheckboxStyle style;

  /// Whether the checkbox is interactive.
  final bool enabled;

  /// When true, shows a loading indicator instead of the check icon.
  /// Interaction is blocked while loading.
  final bool loading;

  /// Custom loading widget (e.g. Lottie animation, animated SVG).
  /// When null and [loading] is true, a shimmer effect is used.
  final Widget? loadingWidget;

  /// Text label displayed beside the checkbox.
  final String? label;

  /// Custom label widget. Takes priority over [label].
  final Widget? labelWidget;

  /// Style for the text label.
  final TextStyle? labelStyle;

  /// Position of the label.
  final CheckboxLabelPosition labelPosition;

  /// Description text below the label.
  final String? description;

  /// Style for the description text.
  final TextStyle? descriptionStyle;

  /// Tooltip on long press.
  final String? tooltip;

  /// Debounce rapid taps — ignores toggles within 300ms.
  final bool debounce;

  /// Error shown below the checkbox — rendered in the shared
  /// [FieldMessagesColumn] (icon + status color), like every field.
  final String? errorText;

  /// Status rows below the checkbox, stacked with [errorText] and
  /// sorted error → success → warning → info.
  final List<FieldMessage> messages;

  /// Accessibility label.
  final String? semanticLabel;

  // ─── Convenience: bool-based constructors ─────────────────

  /// Simple bool-based checkbox.
  factory GlobalCheckbox.simple({
    Key? key,
    required bool value,
    required ValueChanged<bool>? onChanged,
    CheckboxVariant variant = CheckboxVariant.standard,
    CheckboxStyle style = const CheckboxStyle(),
    bool enabled = true,
    bool loading = false,
    Widget? loadingWidget,
    String? label,
    Widget? labelWidget,
    TextStyle? labelStyle,
    CheckboxLabelPosition labelPosition = CheckboxLabelPosition.trailing,
    String? description,
    TextStyle? descriptionStyle,
    String? tooltip,
    bool debounce = false,
    String? errorText,
    List<FieldMessage> messages = const [],
    String? semanticLabel,
  }) {
    return GlobalCheckbox(
      key: key,
      value: value ? CheckboxValue.checked : CheckboxValue.unchecked,
      onChanged: onChanged != null
          ? (v) => onChanged(v == CheckboxValue.checked)
          : null,
      variant: variant,
      style: style,
      enabled: enabled,
      loading: loading,
      loadingWidget: loadingWidget,
      label: label,
      labelWidget: labelWidget,
      labelStyle: labelStyle,
      labelPosition: labelPosition,
      description: description,
      descriptionStyle: descriptionStyle,
      tooltip: tooltip,
      debounce: debounce,
      errorText: errorText,
      messages: messages,
      semanticLabel: semanticLabel,
    );
  }

  @override
  State<GlobalCheckbox> createState() => _GlobalCheckboxState();
}

class _GlobalCheckboxState extends State<GlobalCheckbox>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Pending CurvedAnimation disposal (avoids accumulation on rapid curve changes)
  CurvedAnimation? _curvedAnimation;
  Curve? _appliedCurve;

  bool _isHovered = false;
  bool _isFocused = false;
  DateTime? _lastToggle;

  /// Resolved style — materialized once per build (see build()).
  late ResolvedCheckboxStyle _rs;
  bool _reduceMotion = false;

  Animation<double> get _checkAnimation => _curvedAnimation ?? _checkController;

  @override
  void initState() {
    super.initState();
    // Duration/curve sync to the resolved style at first build.
    _checkController = AnimationController(
      vsync: this,
      duration: kCheckboxAnimDuration,
      value: widget.value != CheckboxValue.unchecked ? 1.0 : 0.0,
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: kCheckboxScaleDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: kCheckboxScaleOnTap)
        .animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
        );
  }

  void _updateCurvedAnimation(Curve curve) {
    if (_appliedCurve == curve) return;
    _appliedCurve = curve;
    _curvedAnimation?.dispose();
    _curvedAnimation = CurvedAnimation(parent: _checkController, curve: curve);
  }

  @override
  void didUpdateWidget(GlobalCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value != CheckboxValue.unchecked) {
        _checkController.forward();
      } else {
        _checkController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _curvedAnimation?.dispose();
    _checkController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled || widget.onChanged == null || widget.loading) return;

    // Debounce guard
    if (widget.debounce) {
      final now = DateTime.now();
      if (_lastToggle != null &&
          now.difference(_lastToggle!) < kCheckboxDebounceDuration) {
        return;
      }
      _lastToggle = now;
    }

    if (_rs.enableHaptic) HapticFeedback.lightImpact();

    if (_rs.scaleOnTap && !_reduceMotion) {
      _scaleController.forward().then((_) {
        if (mounted) _scaleController.reverse();
      });
    }

    final next = switch (widget.value) {
      CheckboxValue.unchecked => CheckboxValue.checked,
      CheckboxValue.checked => CheckboxValue.unchecked,
      CheckboxValue.indeterminate => CheckboxValue.checked,
    };
    widget.onChanged!(next);
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Materialize the themeable bag once per build — every visual below
    // reads _rs directly (resolved-style invariant).
    _rs = widget.style.resolve(context, variant: widget.variant);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _checkController.duration = _reduceMotion
        ? Duration.zero
        : _rs.animationDuration;
    _updateCurvedAnimation(_rs.animationCurve);

    final isDisabled = !widget.enabled || widget.onChanged == null;
    final isChecked = widget.value != CheckboxValue.unchecked;

    var checkbox = _buildCheckbox(isChecked, isDisabled);

    // Scale animation
    if (_rs.scaleOnTap && !_reduceMotion) {
      checkbox = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: checkbox,
      );
    }

    // Hover / focus wrapper
    checkbox = _buildHoverFocusWrapper(checkbox, isDisabled, isChecked);

    // Label — wraps as a single tap target, no double GestureDetector
    final hasLabel =
        widget.label != null ||
        widget.labelWidget != null ||
        widget.description != null;
    if (hasLabel) {
      checkbox = _buildWithLabel(context, checkbox, isDisabled);
    }

    // Error + status rows — the shared message column (icon + status
    // color), never a bare string.
    if (widget.errorText != null || widget.messages.isNotEmpty) {
      checkbox = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          checkbox,
          FieldMessagesColumn(
            errorText: widget.errorText,
            messages: widget.messages,
          ),
        ],
      );
    }

    // Tooltip
    if (widget.tooltip != null) {
      checkbox = GlobalTooltip(message: widget.tooltip!, child: checkbox);
    }

    // Semantics
    return Semantics(
      checked: isChecked,
      enabled: !isDisabled,
      label:
          widget.semanticLabel ?? widget.label ?? CheckboxStrings.semanticLabel,
      onTap: isDisabled ? null : _handleTap,
      excludeSemantics: true,
      child: checkbox,
    );
  }

  // ─── Hover / Focus ─────────────────────────────────────────

  Widget _buildHoverFocusWrapper(
    Widget child,
    bool isDisabled,
    bool isChecked,
  ) {
    // Check-color overlay on checked (contrasts the filled box), primary
    // overlay on unchecked (light bg).
    final hoverColor =
        _rs.hoverColor ??
        (isChecked
            ? _rs.checkColor.withValues(alpha: 0.15)
            : _rs.checkedColor.withValues(alpha: kCheckboxHoverOpacity));
    final focusColor =
        _rs.focusColor ??
        (isChecked
            ? _rs.checkColor.withValues(alpha: 0.25)
            : _rs.checkedColor.withValues(alpha: kCheckboxFocusOpacity));

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
                          borderRadius: _rs.borderRadius,
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

  // ─── Standard / Circle checkbox ────────────────────────────

  Widget _buildCheckbox(bool isChecked, bool isDisabled) {
    final disabledOverride = isDisabled ? _rs.disabledColor : null;
    final checkedColor = disabledOverride ?? _rs.checkedColor;
    final borderColor = disabledOverride ?? _rs.borderColor;
    final checkedBorderColor = disabledOverride ?? _rs.checkedBorderColor;

    final effectiveBg = isChecked ? checkedColor : _rs.uncheckedColor;
    final effectiveBorder = isChecked ? checkedBorderColor : borderColor;
    final effectiveBorderGradient = isChecked
        ? _rs.checkedBorderGradient
        : _rs.borderGradient;
    final effectiveShadow = isChecked ? _rs.checkedShadow : _rs.shadow;

    final iconData = widget.value == CheckboxValue.indeterminate
        ? _rs.indeterminateIcon
        : _rs.checkIcon;

    // Pre-build the loading content outside the AnimatedBuilder so it
    // doesn't rebuild every animation frame.
    final loadingContent = widget.loading ? _buildLoadingContent() : null;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: isDisabled ? kCheckboxDisabledOpacity : 1.0,
        duration: _checkController.duration!,
        child: AnimatedBuilder(
          animation: _checkAnimation,
          builder: (_, _) {
            final t = _checkAnimation.value;
            final bgColor = Color.lerp(_rs.uncheckedColor, effectiveBg, t)!;
            final bdrColor = Color.lerp(borderColor, effectiveBorder, t)!;

            Widget box = Container(
              width: _rs.size,
              height: _rs.size,
              decoration: BoxDecoration(
                color: _rs.checkedGradient == null ? bgColor : null,
                gradient: _rs.checkedGradient != null
                    ? _lerpGradientOpacity(_rs.checkedGradient!, t)
                    : null,
                borderRadius: _rs.borderRadius,
                border: effectiveBorderGradient == null
                    ? Border.all(color: bdrColor, width: _rs.borderWidth)
                    : null,
                boxShadow: effectiveShadow,
              ),
              child: Center(
                child:
                    loadingContent ??
                    Transform.scale(
                      scale: t,
                      child: Icon(
                        iconData,
                        size: _rs.iconSize,
                        color: _rs.checkColor.withValues(alpha: t),
                      ),
                    ),
              ),
            );

            // Gradient border
            if (effectiveBorderGradient != null) {
              box = CustomPaint(
                foregroundPainter: GradientBorderPainter(
                  gradient: effectiveBorderGradient,
                  borderRadius: _rs.borderRadius,
                  borderWidth: _rs.borderWidth,
                ),
                child: box,
              );
            }

            return box;
          },
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    if (widget.loadingWidget != null) {
      return SizedBox(
        width: _rs.iconSize,
        height: _rs.iconSize,
        child: widget.loadingWidget,
      );
    }
    // Default: shimmer effect over the checkbox shape
    return ClipRRect(
      borderRadius: _rs.borderRadius,
      child: GlobalShimmer.wrap(
        baseColor: Color.lerp(_rs.checkedColor, Colors.black, 0.1)!,
        highlightColor: Color.lerp(_rs.checkedColor, Colors.white, 0.3)!,
        period: AppDurations.slow,
        borderRadius: _rs.borderRadius,
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

  Widget _buildWithLabel(
    BuildContext context,
    Widget checkbox,
    bool isDisabled,
  ) {
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

    if (labelW == null) return checkbox;

    // Remove the inner GestureDetector's onTap to avoid double-firing.
    // The outer GestureDetector handles the tap for the entire row.
    final checkboxWithoutTap = IgnorePointer(child: checkbox);

    final children = widget.labelPosition == CheckboxLabelPosition.trailing
        ? [
            checkboxWithoutTap,
            const SizedBox(width: kCheckboxLabelSpacing),
            Flexible(child: labelW),
          ]
        : [
            Flexible(child: labelW),
            const SizedBox(width: kCheckboxLabelSpacing),
            checkboxWithoutTap,
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
// GlobalCheckboxTile
// ---------------------------------------------------------------------------

/// A full-width tappable tile with an embedded checkbox — like a ListTile.
class GlobalCheckboxTile extends StatelessWidget {
  const GlobalCheckboxTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.variant = CheckboxVariant.standard,
    this.style = const CheckboxStyle(),
    this.enabled = true,
    this.loading = false,
    this.loadingWidget,
    this.checkboxPosition = CheckboxLabelPosition.trailing,
    this.contentPadding,
    this.tileColor,
    this.selectedTileColor,
    this.borderRadius,
    this.border,
    this.debounce = false,
    this.dense = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final CheckboxVariant variant;
  final CheckboxStyle style;
  final bool enabled;
  final bool loading;
  final Widget? loadingWidget;

  /// Where the checkbox sits in the tile.
  final CheckboxLabelPosition checkboxPosition;

  final EdgeInsets? contentPadding;
  final Color? tileColor;
  final Color? selectedTileColor;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final bool debounce;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final rs = style.resolve(context, variant: variant);
    final isDisabled = !enabled || onChanged == null;
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(context.radii.md);
    final effectiveBg = value
        ? (selectedTileColor ?? rs.checkedColor.withValues(alpha: 0.05))
        : (tileColor ?? Colors.transparent);
    final effectivePadding =
        contentPadding ??
        EdgeInsets.symmetric(
          vertical: dense ? 8 : kCheckboxTileVerticalPadding,
          horizontal: kCheckboxTileHorizontalPadding,
        );

    // The checkbox is non-interactive here — the tile's InkWell handles the tap
    final checkbox = IgnorePointer(
      child: GlobalCheckbox.simple(
        value: value,
        onChanged: onChanged,
        variant: variant,
        style: style,
        enabled: enabled,
        loading: loading,
        loadingWidget: loadingWidget,
        debounce: debounce,
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

    if (checkboxPosition == CheckboxLabelPosition.leading) {
      contentChildren.add(checkbox);
      contentChildren.add(const SizedBox(width: kCheckboxLabelSpacing));
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

    if (checkboxPosition == CheckboxLabelPosition.trailing) {
      contentChildren.add(const SizedBox(width: kCheckboxLabelSpacing));
      contentChildren.add(checkbox);
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
                  onChanged?.call(!value);
                },
          borderRadius: effectiveRadius,
          child: AnimatedOpacity(
            opacity: isDisabled ? kCheckboxDisabledOpacity : 1.0,
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
// GlobalCheckboxGroup
// ---------------------------------------------------------------------------

/// An item in a [GlobalCheckboxGroup].
@immutable
class CheckboxGroupItem<T> {
  const CheckboxGroupItem({
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
      other is CheckboxGroupItem<T> &&
          other.value == value &&
          other.label == label;

  @override
  int get hashCode => Object.hash(value, label);
}

/// A group of checkboxes with min/max selection enforcement and optional
/// select-all master checkbox.
class GlobalCheckboxGroup<T> extends StatelessWidget {
  const GlobalCheckboxGroup({
    super.key,
    required this.items,
    required this.selectedValues,
    required this.onChanged,
    this.variant = CheckboxVariant.standard,
    this.style = const CheckboxStyle(),
    this.spacing = kCheckboxGroupSpacing,
    this.direction = Axis.vertical,
    this.minSelections = 0,
    this.maxSelections,
    this.enabled = true,
    this.debounce = false,
    this.errorText,
    this.messages = const [],
    this.labelPosition = CheckboxLabelPosition.trailing,
    this.showSelectAll = false,
    this.selectAllLabel,
  });

  /// Available items.
  final List<CheckboxGroupItem<T>> items;

  /// Currently selected values.
  final List<T> selectedValues;

  /// Called when selection changes.
  final ValueChanged<List<T>> onChanged;

  /// Visual variant applied to all checkboxes.
  final CheckboxVariant variant;

  /// Themeable style applied to all checkboxes.
  final CheckboxStyle style;

  /// Spacing between items.
  final double spacing;

  /// Layout direction.
  final Axis direction;

  /// Minimum required selections.
  final int minSelections;

  /// Maximum allowed selections. Null = unlimited.
  final int? maxSelections;

  /// Whether the entire group is enabled.
  final bool enabled;

  /// Debounce passed to all children.
  final bool debounce;

  /// Error shown below the group — shared message column treatment.
  final String? errorText;

  /// Status rows below the group.
  final List<FieldMessage> messages;

  /// Label position for all items.
  final CheckboxLabelPosition labelPosition;

  /// When true, shows a master "Select All" checkbox at the top.
  final bool showSelectAll;

  /// Label for the select-all checkbox.
  final String? selectAllLabel;

  @override
  Widget build(BuildContext context) {
    final enabledItems = items.where((i) => i.enabled).toList();
    final allSelected = enabledItems.every(
      (i) => selectedValues.contains(i.value),
    );
    final someSelected = enabledItems.any(
      (i) => selectedValues.contains(i.value),
    );

    final children = <Widget>[];

    // Select All master checkbox
    if (showSelectAll && direction == Axis.vertical) {
      final masterValue = allSelected
          ? CheckboxValue.checked
          : someSelected
          ? CheckboxValue.indeterminate
          : CheckboxValue.unchecked;

      children.add(
        GlobalCheckbox(
          value: masterValue,
          onChanged: enabled
              ? (v) {
                  if (v == CheckboxValue.checked) {
                    final newList = List<T>.from(selectedValues);
                    for (final item in enabledItems) {
                      if (!newList.contains(item.value)) {
                        newList.add(item.value);
                      }
                    }
                    onChanged(newList);
                  } else {
                    final newList = List<T>.from(selectedValues);
                    for (final item in enabledItems) {
                      if (newList.length > minSelections) {
                        newList.remove(item.value);
                      }
                    }
                    onChanged(newList);
                  }
                }
              : null,
          variant: variant,
          style: style,
          enabled: enabled,
          label: selectAllLabel ?? CheckboxStrings.selectAll,
          labelPosition: labelPosition,
          labelStyle: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.textColors.primary,
          ),
          debounce: debounce,
        ),
      );
      children.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: spacing / 2),
          child: const GlobalDivider(),
        ),
      );
    }

    // Individual items
    for (final item in items) {
      final isSelected = selectedValues.contains(item.value);

      final canUncheck = isSelected && selectedValues.length > minSelections;
      final canCheck =
          !isSelected &&
          (maxSelections == null || selectedValues.length < maxSelections!);
      final isItemEnabled =
          enabled && item.enabled && (isSelected ? canUncheck : canCheck);

      children.add(
        GlobalCheckbox.simple(
          value: isSelected,
          onChanged: isItemEnabled
              ? (checked) {
                  final newList = List<T>.from(selectedValues);
                  if (checked) {
                    newList.add(item.value);
                  } else {
                    newList.remove(item.value);
                  }
                  onChanged(newList);
                }
              : null,
          variant: variant,
          style: style,
          enabled: isItemEnabled,
          label: item.labelWidget == null ? item.label : null,
          labelWidget: item.labelWidget,
          description: item.description,
          labelPosition: labelPosition,
          debounce: debounce,
        ),
      );
    }

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
// Gradient border painter
// ---------------------------------------------------------------------------
