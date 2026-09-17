// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../../../core/animations/animation_presets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../buttons/global_icon_button.dart';
import '../../chip/global_chip.dart';
import '../../progress/global_progress.dart';
import '../../text_field/global_text_field.dart';
import '../drop_down_models.dart';

/// Default trigger height when no `sizing.height` is supplied — matches the
/// text field's intrinsic ~48 dp box.
const double kDropdownTriggerHeight = 48;

// ---------------------------------------------------------------------------
// DropdownTriggerHeader — identifier + info button
// ---------------------------------------------------------------------------

/// Mirrors the text field's own identifier header (`_buildHeader` in
/// `text_field_state_panels.dart`) for the trigger variants that don't
/// embed a `GlobalTextFormField` (chip wrap + loading shimmer).
class DropdownTriggerHeader extends StatelessWidget {
  const DropdownTriggerHeader({
    super.key,
    this.identifier,
    this.required = false,
    this.infoLabel,
    this.onInfoLabelTap,
    this.enabled = true,
  });

  final String? identifier;

  /// Draws the red `*` the text field's header does — see
  /// `GlobalDropdown.required`.
  final bool required;
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (identifier == null && infoLabel == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (identifier != null)
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: identifier,
                  children: [
                    // The same star, the same colour, inheriting the
                    // same weight — see `_identifierText` in
                    // `text_field_state_panels.dart`.
                    if (required)
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: context.statusColors.error),
                      ),
                  ],
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          if (infoLabel != null)
            Semantics(
              label: infoLabel,
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(context.radii.full),
                onTap: onInfoLabelTap,
                child: Padding(
                  padding: EdgeInsets.all(context.spacing.xs),
                  child: Icon(
                    Icons.info_outline,
                    size: context.iconSizes.xs,
                    color: enabled
                        ? theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          )
                        : theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DropdownTriggerControls — trailing clear (×) + chevron
// ---------------------------------------------------------------------------

/// Trailing trigger controls — selected-item trailing widget, clear (×)
/// button and the open-state chevron. Shared by the text-field trigger's
/// suffix slot and [DropdownChipTrigger].
class DropdownTriggerControls extends StatelessWidget {
  const DropdownTriggerControls({
    super.key,
    required this.open,
    this.enabled = true,
    this.showClear = false,
    this.onClear,
    this.onToggle,
    this.iconColor,
    this.selectedTrailing,
    this.dense = false,
    this.showChevron = true,
  });

  final bool open;
  final bool enabled;
  final bool showClear;
  final VoidCallback? onClear;

  /// Open/close the dropdown — the chevron is a real button
  /// ([GlobalIconButton]), so it must fire the same toggle as the field tap.
  final VoidCallback? onToggle;

  final Color? iconColor;
  final Widget? selectedTrailing;

  /// See `DropdownBehavior.showChevron`.
  final bool showChevron;

  /// Tight chevron slot (14dp layout, the 20dp icon paints centered over
  /// it) — for narrow fit-width triggers (joined country/unit pickers)
  /// where the standard 32dp box's slack reads as dead space around the
  /// arrow. The whole trigger is the tap target, so the smaller button
  /// costs nothing.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    // NOTHING to show is not the same as an empty row. The suffix slot
    // reserves space for whatever it is handed, so a childless `Row`
    // still pushed the value off-centre — which is what a dial-code
    // picker with no chevron and no clear button became.
    if (selectedTrailing == null && !showClear && !showChevron) {
      return const SizedBox.shrink();
    }

    final base = iconColor ?? context.iconColors.primary;
    final color = enabled ? base : base.withValues(alpha: 0.5);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // ExcludeFocus: these are in-field affordances — pressing them must not
    // steal focus (a chevron press should feel identical to a field tap).
    return ExcludeFocus(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedTrailing != null) ...[
            selectedTrailing!,
            SizedBox(width: context.spacing.xs),
          ],
          if (showClear)
            GlobalIconButton(
              onPressed: enabled ? onClear : null,
              iconData: Icons.close,
              iconSize: context.iconSizes.xs,
              tooltip: DropDownStrings.clearSelection,
              // 40 dp minimum tap target (a11y floor for in-field
              // actions). Stated as the button's own size rather than a
              // BoxConstraints minimum, and the 48dp enforcement stands
              // down — it would otherwise put the box straight back and
              // the trigger row cannot spare the width.
              enforceMinTouchTarget: false,
              style: ButtonStateStyle(
                width: 40,
                height: 40,
                foregroundColor: color,
                backgroundColor: Colors.transparent,
              ),
            ),
          // Mirrors the text-field module's suffix icon button recipe
          // (compact 32dp box, 20dp icon — the password eye et al.) so a
          // dropdown trigger reads identically to any other field action.
          // No end inset — the 32dp box already carries ~6dp of visual
          // slack around its 20dp icon.
          if (showChevron) _chevron(context, color, reduceMotion),
        ],
      ),
    );
  }

  Widget _chevron(BuildContext context, Color color, bool reduceMotion) {
    final button = GlobalIconButton(
      onPressed: enabled ? onToggle : null,
      tooltip: open ? DropDownStrings.tapToClose : DropDownStrings.tapToOpen,
      enforceMinTouchTarget: false,
      iconWidget: AnimatedRotation(
        turns: open ? 0.5 : 0,
        duration: reduceMotion ? AppDurations.instant : AppDurations.fast,
        child: Icon(Icons.keyboard_arrow_down, size: 20, color: color),
      ),
      style: const ButtonStateStyle(width: 40, height: 40),
    );
    if (!dense) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        child: button,
      );
    }
    // Dense: the LAYOUT slot shrinks below the icon box (the arrow glyph
    // only fills ~12dp of its 20dp icon, so the box's inherent inset
    // reads as padding). The button paints centered via OverflowBox —
    // glyph stays centered, the label side tightens, and the end inset
    // keeps the arrow off the trigger's border.
    return Padding(
      padding: EdgeInsetsDirectional.only(end: context.spacing.xs),
      child: SizedBox(
        width: 14,
        height: 32,
        child: OverflowBox(
          maxWidth: 20,
          maxHeight: 32,
          child: button,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DropdownChipTrigger — wrap-height multi-select trigger
// ---------------------------------------------------------------------------

/// Chip-display trigger for `chips.display: true` multi-select dropdowns.
/// The text-field trigger is single-line, so this variant keeps a custom
/// wrapping surface — styled from the same resolved [TextFieldStyle]
/// (fill / border / radius) so it visually matches the field trigger.
/// Renders its own [DropdownTriggerHeader] and the SAME message column
/// as the field trigger ([FieldMessagesColumn] — [errorText] +
/// [messages]).
class DropdownChipTrigger<T> extends StatelessWidget {
  const DropdownChipTrigger({
    super.key,
    required this.selectedItems,
    required this.hint,
    required this.style,
    this.identifier,
    this.required = false,
    this.infoLabel,
    this.onInfoLabelTap,
    this.errorText,
    this.messages = const [],
    this.minHeight = kDropdownTriggerHeight,
    this.enabled = true,
    this.focused = false,
    this.showLeadingInChip = false,
    this.showTrailingInChip = false,
    this.onDeleteItem,
    this.trailing,
  });

  /// Resolved selected items, in selection order.
  final List<DropdownItem<T>> selectedItems;
  final String hint;
  final TextFieldStyle style;
  final bool required;

  final String? identifier;
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;
  final String? errorText;

  /// Status rows below the chip wrap — same treatment as the field
  /// trigger's message column.
  final List<FieldMessage> messages;

  final double minHeight;
  final bool enabled;
  final bool focused;
  final bool showLeadingInChip;
  final bool showTrailingInChip;
  final ValueChanged<DropdownItem<T>>? onDeleteItem;

  /// Trailing controls (clear button + chevron), shared with the
  /// text-field trigger's suffix.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // stretch (not an infinite-width box) fills the parent: a
    // `width: double.infinity` on the box reported infinite max
    // intrinsic width and blew up IntrinsicWidth / intrinsic Table
    // ancestors that the field trigger survives.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownTriggerHeader(
          identifier: identifier,
          required: required,
          infoLabel: infoLabel,
          onInfoLabelTap: onInfoLabelTap,
          enabled: enabled,
        ),
        _buildBox(context),
        if (errorText != null || messages.isNotEmpty)
          Padding(
            padding: EdgeInsetsDirectional.only(
              top: context.spacing.xs,
              start: context.spacing.sm,
            ),
            child: FieldMessagesColumn(
              errorText: errorText,
              messages: messages,
            ),
          ),
      ],
    );
  }

  Widget _buildBox(BuildContext context) {
    final rs = style.resolve(context);
    final hasError = errorText != null;
    final side = hasError
        ? (focused ? rs.focusedErrorBorder : rs.errorBorder)
        : focused
        ? rs.focusedBorder
        : rs.enabledBorder;
    final borderColor = side.paints ? side.color : Colors.transparent;
    final borderWidth = side.width > 0 ? side.width : 1.0;
    final fill = enabled ? rs.fillColor : rs.fillColor.withValues(alpha: 0.6);

    return AnimatedContainer(
      duration: AppDurations.fast,
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: rs.borderRadius,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      padding:
          rs.contentPadding ??
          EdgeInsets.symmetric(
            horizontal: context.spacing.sm + context.spacing.xs,
            vertical: context.spacing.sm,
          ),
      child: Row(
        children: [
          Expanded(child: _buildChips(context)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _buildChips(BuildContext context) {
    if (selectedItems.isEmpty) {
      return Text(
        hint,
        overflow: TextOverflow.ellipsis,
        style:
            style.hintStyle ??
            context.textTheme.bodyMedium?.copyWith(
              color: context.textColors.secondary,
            ),
      );
    }

    final primary = context.primaryColors.primary;
    return Wrap(
      spacing: context.spacing.xs,
      runSpacing: context.spacing.xs / 2,
      children: selectedItems.map((item) {
        // Tonal by variant rather than by a hand-mixed 10% primary,
        // so a selection chip here matches one anywhere else.
        return GlobalChip(
          label: item.label,
          variant: ChipVariant.tonal,
          avatar: showLeadingInChip ? item.leading : null,
          trailing: showTrailingInChip ? item.trailing : null,
          onDeleted: enabled && onDeleteItem != null
              ? () => onDeleteItem!(item)
              : null,
          deleteIcon: Icon(Icons.close, size: context.iconSizes.xs),
          style: ChipStyle(
            labelColor: primary,
            deleteIconColor: primary,
            labelStyle: context.textTheme.labelSmall,
            borderRadius: BorderRadius.circular(context.radii.sm),
            padding: EdgeInsetsDirectional.only(start: context.spacing.xs),
            labelPadding: EdgeInsetsDirectional.only(
              start: context.spacing.xs,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// DropdownLoadingTrigger — shimmer placeholder
// ---------------------------------------------------------------------------

/// Shimmer trigger for `isLoading: true`. Uses `context.shimmerColors`;
/// reduce-motion renders a static block instead of the sweep. Renders its
/// own [DropdownTriggerHeader].
class DropdownLoadingTrigger extends StatefulWidget {
  const DropdownLoadingTrigger({
    super.key,
    required this.style,
    this.height = kDropdownTriggerHeight,
    this.identifier,
    this.required = false,
    this.infoLabel,
    this.onInfoLabelTap,
    this.enabled = true,
  });

  final TextFieldStyle style;
  final double height;
  final bool required;

  final String? identifier;
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;
  final bool enabled;

  @override
  State<DropdownLoadingTrigger> createState() => _DropdownLoadingTriggerState();
}

class _DropdownLoadingTriggerState extends State<DropdownLoadingTrigger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: AppDurations.shimmer,
    vsync: this,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownTriggerHeader(
          identifier: widget.identifier,
          required: widget.required,
          infoLabel: widget.infoLabel,
          onInfoLabelTap: widget.onInfoLabelTap,
          enabled: widget.enabled,
        ),
        _buildBox(context),
      ],
    );
  }

  Widget _buildBox(BuildContext context) {
    final rs = widget.style.resolve(context);
    final shimmer = context.shimmerColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }

    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: rs.borderRadius,
        color: rs.fillColor.withValues(alpha: 0.6),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm + context.spacing.xs,
        vertical: context.spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final color = reduceMotion
                    ? shimmer.baseColor
                    : Color.lerp(
                        shimmer.baseColor,
                        shimmer.highlight,
                        _controller.value,
                      )!;
                return Container(
                  height: context.spacing.sm + context.spacing.xs,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(context.radii.xs),
                    color: color,
                  ),
                );
              },
            ),
          ),
          SizedBox(width: context.spacing.sm),
          SizedBox(
            width: context.iconSizes.sm,
            height: context.iconSizes.sm,
            child: GlobalProgress.loading(
              type: ProgressType.circular,
              style: ProgressStyle(thickness: 2, color: rs.iconColor),
            ),
          ),
        ],
      ),
    );
  }
}
