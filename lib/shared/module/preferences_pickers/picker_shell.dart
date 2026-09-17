import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/list_strings.dart';
import '../../common/text_form_fields/generic/search_text_field.dart';
import '../chip/global_chip.dart';
import '../container/global_container.dart';
import '../dialog/global_dialog.dart';
import '../divider/global_divider.dart';
import '../drop_down/global_drop_down.dart';
import '../empty_state/global_empty_state.dart';
import '../icon/global_icon.dart';
import '../radio/global_radio.dart';
import '../segmented_control/global_segmented_control.dart';
import '../sheet/global_sheet.dart';
import '../text/global_text.dart';
import 'picker_item.dart';
import 'picker_options.dart';
import 'picker_style.dart';
import 'theme/picker_theme.dart';

export 'picker_style.dart';
export 'theme/picker_theme.dart';

/// Generic picker host — every preference picker delegates to this.
/// Resolves [PickerOptions.variant] into the matching widget.
///
/// **It owns no controls of its own.** Each variant is one of the
/// app's own: a `GlobalChip`, a `GlobalRadio`, a
/// `GlobalContainer.tile`, a `GlobalSegmentedControl`, a
/// `GlobalDropdown`. It used to hand-roll four of those — a pill out
/// of `Material` and an `InkWell`, a radio out of an
/// `AnimatedContainer`, a row out of a bordered `Container`, and
/// Material's own `DropdownButtonFormField` — so a rebrand reached
/// every chip, radio, tile and dropdown in the app EXCEPT the ones on
/// the settings page.
///
/// Visual configuration is the themeable bag [PickerStyle] —
/// `caller > GlobalPickerTheme.style > PickerStyle.defaults`. It is
/// thin, and stays thin: the controls carry their own.
class PickerShell<T> extends StatelessWidget {
  const PickerShell({
    required this.items,
    required this.value,
    required this.onChanged,
    this.options = const PickerOptions(),
    this.style = const PickerStyle(),
    this.itemBuilder,
    this.previewBuilder,
    this.dropdownBuilder,
    super.key,
  });

  final List<PickerItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final PickerOptions options;
  final PickerStyle style;

  /// Override per-row rendering when needed (e.g. language flag + flag
  /// glyph rendering).
  final Widget Function(BuildContext context, PickerItem<T> item, bool active)?
  itemBuilder;

  /// Optional preview rendered above the picker — used by font scale.
  final WidgetBuilder? previewBuilder;

  /// Replaces the body of [PickerVariant.dropdown].
  ///
  /// The generic dropdown is built from [PickerItem]s, which carry a
  /// label and an icon. Some preferences already have a CANONICAL
  /// dropdown in the commons that knows more than that — the language
  /// one shows a flag image, the localized name and the native name,
  /// and feeds a search string — and a second, plainer dropdown for
  /// the same preference on the same screen is the drift this module
  /// exists to stop.
  final WidgetBuilder? dropdownBuilder;

  @override
  Widget build(BuildContext context) {
    final rs = style.resolve(context);
    final body = switch (options.variant) {
      PickerVariant.pillRow => _PillRow<T>(
        items: items,
        value: value,
        onChanged: onChanged,
        options: options,
        rs: rs,
      ),
      PickerVariant.list => _RadioList<T>(
        items: items,
        value: value,
        onChanged: onChanged,
        options: options,
        rs: rs,
        itemBuilder: itemBuilder,
      ),
      PickerVariant.segmented => _SegmentedRow<T>(
        items: items,
        value: value,
        onChanged: onChanged,
        options: options,
      ),
      PickerVariant.dropdown =>
        dropdownBuilder?.call(context) ??
            _DropdownPicker<T>(
              items: items,
              value: value,
              onChanged: onChanged,
              options: options,
            ),
      PickerVariant.sheet => _SummaryTrigger<T>(
        items: items,
        value: value,
        onChanged: onChanged,
        options: options,
        rs: rs,
        itemBuilder: itemBuilder,
        asDialog: false,
      ),
      PickerVariant.dialog => _SummaryTrigger<T>(
        items: items,
        value: value,
        onChanged: onChanged,
        options: options,
        rs: rs,
        itemBuilder: itemBuilder,
        asDialog: true,
      ),
    };

    return Padding(
      padding: options.padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showsHeader) _Header(options: options, rs: rs),
          if (previewBuilder != null) previewBuilder!(context),
          body,
        ],
      ),
    );
  }

  bool get _showsHeader =>
      options.variant != PickerVariant.pillRow &&
      options.variant != PickerVariant.segmented &&
      options.title != null;
}

// ─────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.options, required this.rs});

  final PickerOptions options;
  final ResolvedPickerStyle rs;

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final btn = context.buttonsColors;
    return Padding(
      padding: EdgeInsets.only(bottom: rs.pillSpacing),
      child: Semantics(
        // The section heading names the group of options under it.
        header: true,
        child: Row(
          children: [
            if (options.icon != null) ...[
              GlobalIcon(
                icon: options.icon!,
                style: IconStyle(
                  size: rs.headerIconSize,
                  color: btn.primary,
                  containerSize: rs.headerIconContainerSize,
                  containerShape: IconContainerShape.rounded,
                  backgroundColor: btn.primary,
                  backgroundOpacity: 0.12,
                ),
              ),
              SizedBox(width: rs.pillSpacing),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlobalText(
                    options.title ?? '',
                    preset: TextPreset.bodyMedium,
                    textStyle: GlobalTextStyle(
                      color: tx.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((options.subtitle ?? '').isNotEmpty)
                    GlobalText(
                      options.subtitle!,
                      preset: TextPreset.bodySmall,
                      textStyle: GlobalTextStyle(color: tx.secondary),
                    ),
                ],
              ),
            ),
            if (options.trailing != null) options.trailing!,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pill row — GlobalChip, in a choice role
// ─────────────────────────────────────────────────────────────

class _PillRow<T> extends StatelessWidget {
  const _PillRow({
    required this.items,
    required this.value,
    required this.onChanged,
    required this.options,
    required this.rs,
  });

  final List<PickerItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final PickerOptions options;
  final ResolvedPickerStyle rs;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: rs.pillSpacing,
        children: [
          for (final item in items)
            // `onSelected` is the CHOICE role — one node that is a
            // button and reports whether it is picked. The hand-rolled
            // pill reported neither.
            GlobalChip(
              label: item.label,
              selected: item.value == value,
              onSelected: (_) => onChanged(item.value),
              avatar: options.showIcons && item.icon != null
                  ? Icon(item.icon)
                  : null,
              // `dense` is the picker's word for tighter; a chip
              // spells it as its own padding.
              style: options.dense
                  ? const ChipStyle(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    )
                  : const ChipStyle(),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Radio list — GlobalRadio rows, in one mutually exclusive group
// ─────────────────────────────────────────────────────────────

/// The option rows, as ONE keyboard stop.
///
/// A radio group is a roving tab stop: TAB reaches the group once and
/// the ARROWS move within it — the same contract the stepper's run and
/// the dot indicator follow. Each row was individually focusable, so
/// tabbing through a settings page walked every option of every
/// preference before reaching the next control.
class _RadioList<T> extends StatefulWidget {
  const _RadioList({
    required this.items,
    required this.value,
    required this.onChanged,
    required this.options,
    required this.rs,
    this.itemBuilder,
  });

  final List<PickerItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final PickerOptions options;
  final ResolvedPickerStyle rs;
  final Widget Function(BuildContext, PickerItem<T>, bool)? itemBuilder;

  @override
  State<_RadioList<T>> createState() => _RadioListState<T>();
}

class _RadioListState<T> extends State<_RadioList<T>> {
  final FocusNode _focus = FocusNode(debugLabel: 'picker options');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// Moves the SELECTION, not just a highlight.
  ///
  /// Which is what an arrow does in a radio group everywhere else: the
  /// choice follows the focus, and there is nothing to "confirm".
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final items = widget.items;
    if (items.isEmpty) return KeyEventResult.ignored;
    final current = items.indexWhere((i) => i.value == widget.value);
    final key = event.logicalKey;

    int? next;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowRight) {
      next = (current + 1).clamp(0, items.length - 1);
    } else if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowLeft) {
      next = (current - 1).clamp(0, items.length - 1);
    } else if (key == LogicalKeyboardKey.home) {
      next = 0;
    } else if (key == LogicalKeyboardKey.end) {
      next = items.length - 1;
    }
    if (next == null) return KeyEventResult.ignored;
    if (next != current) widget.onChanged(items[next].value);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final rs = widget.rs;
    final rows = <Widget>[];
    for (var i = 0; i < widget.items.length; i++) {
      rows.add(
        _RadioRow<T>(
          item: widget.items[i],
          value: widget.value,
          options: widget.options,
          rs: rs,
          onChanged: widget.onChanged,
          customBuilder: widget.itemBuilder,
        ),
      );
      if (rs.showDividers && i < widget.items.length - 1) {
        rows.add(const GlobalDivider());
      } else if (rs.rowSpacing > 0 && i < widget.items.length - 1) {
        rows.add(SizedBox(height: rs.rowSpacing));
      }
    }
    // ONE `Focus`, holding both the node and the handler. Nesting a
    // handler under a different focusable node meant the keys went to
    // the node that had focus and the handler never ran.
    //
    // NOT autofocus: a picker sits in the middle of a settings page
    // that may already have something focused.
    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}

class _RadioRow<T> extends StatelessWidget {
  const _RadioRow({
    required this.item,
    required this.value,
    required this.options,
    required this.rs,
    required this.onChanged,
    this.customBuilder,
  });

  final PickerItem<T> item;
  final T value;
  final PickerOptions options;
  final ResolvedPickerStyle rs;
  final ValueChanged<T> onChanged;
  final Widget Function(BuildContext, PickerItem<T>, bool)? customBuilder;

  @override
  Widget build(BuildContext context) {
    final active = item.value == value;
    final tx = context.textColors;

    // `GlobalRadioTile`, not a `GlobalRadio` with a label hung off it.
    // The radio's own row is a `GestureDetector` — it commits the
    // choice but does not RIPPLE, so a row the size of a settings
    // entry gave no sign it had been pressed. The tile is the
    // module's own answer to that: an `InkWell` over the whole row,
    // a tint while selected, a haptic, and the radio inside it left
    // non-interactive so there is still exactly one target and one
    // semantics node.
    return GlobalRadioTile<T>(
      value: item.value,
      groupValue: value,
      onChanged: onChanged,
      dense: options.dense,
      // The tile's title can be a caller's own widget, so the NAME has
      // to be said explicitly — otherwise the selected state lands on
      // a node announcing the generic "Radio option".
      semanticLabel: item.label,
      contentPadding: rs
          .paddingFor(dense: options.dense)
          .resolve(Directionality.of(context)),
      leading: customBuilder != null
          ? null
          : (options.showIcons && (item.leading != null || item.icon != null)
                ? SizedBox(
                    width: rs.headerIconContainerSize,
                    height: rs.headerIconContainerSize,
                    child:
                        item.leading ??
                        Icon(
                          item.icon,
                          size: rs.rowIconSize,
                          color: tx.secondary,
                        ),
                  )
                : null),
      title: customBuilder != null
          ? customBuilder!(context, item, active)
          : GlobalText(
              item.label,
              preset: TextPreset.bodyMedium,
              textStyle: GlobalTextStyle(
                color: tx.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
      subtitle: customBuilder == null && (item.subtitle ?? '').isNotEmpty
          ? GlobalText(
              item.subtitle!,
              preset: TextPreset.bodySmall,
              textStyle: GlobalTextStyle(color: tx.secondary),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Segmented (2-4 options)
// ─────────────────────────────────────────────────────────────

class _SegmentedRow<T> extends StatelessWidget {
  const _SegmentedRow({
    required this.items,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final List<PickerItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final PickerOptions options;

  @override
  Widget build(BuildContext context) {
    return GlobalSegmentedControl<T>(
      segments: [
        for (final item in items)
          SegmentItem<T>(
            value: item.value,
            label: item.label,
            icon: options.showIcons ? item.icon : null,
          ),
      ],
      value: value,
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dropdown — the app's own, not Material's
// ─────────────────────────────────────────────────────────────

class _DropdownPicker<T> extends StatelessWidget {
  const _DropdownPicker({
    required this.items,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final List<PickerItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final PickerOptions options;

  @override
  Widget build(BuildContext context) {
    // It was a raw `DropdownButtonFormField`. `GlobalDropdown` is a
    // whole themed module with search, validation and its own popup
    // surface, and the settings page was the one screen in the app
    // that got Material's stock menu instead.
    return GlobalDropdown<T>(
      items: [
        for (final item in items)
          DropdownItem<T>(
            value: item.value,
            label: item.label,
            leading: options.showIcons && item.icon != null
                ? Icon(item.icon)
                : null,
          ),
      ],
      selectedValue: value,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      behavior: DropdownBehavior(denseTrigger: options.dense),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Summary tile — opens a sheet or a dialog
// ─────────────────────────────────────────────────────────────

/// The collapsed row the `sheet` and `dialog` variants show.
///
/// One widget for the two: they differed only in which surface they
/// opened and which chevron they drew, and keeping two copies is how
/// the sheet's tile and the dialog's tile drifted apart on padding.
class _SummaryTrigger<T> extends StatelessWidget {
  const _SummaryTrigger({
    required this.items,
    required this.value,
    required this.onChanged,
    required this.options,
    required this.rs,
    required this.asDialog,
    this.itemBuilder,
  });

  final List<PickerItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final PickerOptions options;
  final ResolvedPickerStyle rs;
  final bool asDialog;
  final Widget Function(BuildContext, PickerItem<T>, bool)? itemBuilder;

  PickerItem<T>? get _current =>
      items.where((i) => i.value == value).cast<PickerItem<T>?>().firstOrNull;

  Widget _optionList(BuildContext surfaceContext) {
    final list = _RadioList<T>(
      items: items,
      value: value,
      onChanged: (v) => Navigator.of(surfaceContext).pop(v),
      options: options.copyWith(variant: PickerVariant.list),
      rs: rs,
      itemBuilder: itemBuilder,
    );
    if (items.length < options.searchThreshold) return list;
    return _SearchableOptions<T>(
      items: items,
      value: value,
      options: options,
      rs: rs,
      itemBuilder: itemBuilder,
      onChanged: (v) => Navigator.of(surfaceContext).pop(v),
    );
  }

  Future<void> _open(BuildContext context) async {
    final picked = asDialog
        ? await GlobalDialog.show<T>(
            context: context,
            title: options.title ?? '',
            content: Builder(builder: _optionList),
          )
        // The sheet carries the picker's own heading and its close
        // button. It used to open bare — no title, no handle, no way
        // out but the scrim — and a small unlabelled panel of three
        // rows reads as nothing having happened.
        : await GlobalBottomSheet.show<T>(
            context: context,
            responsive: true,
            style: options.sheetStyle,
            title: options.title,
            subtitle: options.subtitle,
            icon: options.icon,
            content: Builder(builder: _optionList),
          );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cur = _current;
    return GlobalContainer.tile(
      onTap: () => _open(context),
      style: ContainerStyle(
        borderRadius: BorderRadius.circular(rs.summaryRadius),
      ),
      leading: options.showIcons && cur?.icon != null
          ? Icon(cur!.icon, size: rs.rowIconSize)
          : null,
      title: cur?.label ?? '—',
      subtitle: options.title,
      trailing: Icon(
        asDialog ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
        color: context.textColors.secondary,
      ),
    );
  }
}

/// The option list with a filter above it.
///
/// Only past [PickerOptions.searchThreshold]: a three-option theme
/// picker with a search field looks like a mistake, and a forty-locale
/// language list without one is a scroll.
class _SearchableOptions<T> extends StatefulWidget {
  const _SearchableOptions({
    required this.items,
    required this.value,
    required this.options,
    required this.rs,
    required this.onChanged,
    this.itemBuilder,
  });

  final List<PickerItem<T>> items;
  final T value;
  final PickerOptions options;
  final ResolvedPickerStyle rs;
  final ValueChanged<T> onChanged;
  final Widget Function(BuildContext, PickerItem<T>, bool)? itemBuilder;

  @override
  State<_SearchableOptions<T>> createState() => _SearchableOptionsState<T>();
}

class _SearchableOptionsState<T> extends State<_SearchableOptions<T>> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<PickerItem<T>> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items
        .where(
          (i) =>
              i.label.toLowerCase().contains(q) ||
              (i.subtitle ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _filtered;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchTextField(
          controller: _controller,
          onChanged: (q) => setState(() => _query = q),
        ),
        SizedBox(height: widget.rs.pillSpacing),
        if (matches.isEmpty)
          GlobalEmptyState(
            title: ListStrings.emptyTitle,
            icon: Icons.search_off_rounded,
            variant: EmptyStateVariant.compact,
          )
        else
          _RadioList<T>(
            items: matches,
            value: widget.value,
            onChanged: widget.onChanged,
            options: widget.options.copyWith(variant: PickerVariant.list),
            rs: widget.rs,
            itemBuilder: widget.itemBuilder,
          ),
      ],
    );
  }
}
