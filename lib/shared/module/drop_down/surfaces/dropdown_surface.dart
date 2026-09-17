// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import '../../../../core/animations/animation_presets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/localization/tr.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../generated/l10n.dart';
import '../../buttons/global_text_button.dart';
import '../../popup/popup.dart';
import '../../scrollable/global_edge_fade.dart';
import '../../shimmer/global_shimmer.dart';
import '../../text_field/global_text_field.dart';
import '../drop_down_models.dart';
import '../models/drop_down_style.dart';

// ---------------------------------------------------------------------------
// DropdownSurface — the open-session body (search + list + footer)
// ---------------------------------------------------------------------------

/// One widget owns everything that lives only while the dropdown is open:
/// search query, async items + loading + error, the filtered/grouped list,
/// the multi-select working set, the select-all/done footer, the create-new
/// row and the selection flash.
///
/// Rendered inside the popup builder (wrapped in [GlobalPopupSurface]) AND
/// directly in-tree for `inline: true` (pass `layout: null`). Because the
/// surface is disposed when the session ends, the search query resets on
/// close for free — and parent rebuilds can't clobber session state.
class DropdownSurface<T> extends StatefulWidget {
  const DropdownSurface({
    super.key,
    required this.items,
    this.groups,
    required this.multiSelect,
    this.selectedValue,
    this.selectedValues = const [],
    this.enableSearch = false,
    this.searchIdentifier,
    this.asyncItemsLoader,
    this.itemBuilder,
    this.onCreateNew,
    this.maxSelections,
    this.emptyBuilder,
    this.onSelected,
    this.onMultiChanged,
    required this.onCloseRequested,
    this.layout,
    this.surfaceStyle,
    this.dropdownStyle,
    this.inlineMaxHeight = 250,
  }) : assert(
         multiSelect ? onMultiChanged != null : onSelected != null,
         'Provide onMultiChanged for multiSelect, onSelected otherwise',
       );

  final List<DropdownItem<T>> items;
  final List<DropdownGroup<T>>? groups;
  final bool multiSelect;
  final T? selectedValue;
  final List<T> selectedValues;
  final bool enableSearch;
  final String? searchIdentifier;
  final Future<List<DropdownItem<T>>> Function(String query)? asyncItemsLoader;
  final Widget Function(BuildContext, DropdownItem<T>, bool selected)?
  itemBuilder;
  final ValueChanged<String>? onCreateNew;
  final int? maxSelections;
  final Widget Function(BuildContext)? emptyBuilder;

  /// Single-select tap. The parent gets the full item (not just the value)
  /// so it can display async-loaded selections that aren't in [items].
  final void Function(DropdownItem<T> item)? onSelected;

  /// Multi-select change. [DropdownItem]s currently known to the surface
  /// ride along so the parent can resolve labels for async-loaded picks.
  final void Function(List<T> values, List<DropdownItem<T>> knownItems)?
  onMultiChanged;

  /// Ask the owner to close the session (single-select post-flash, footer
  /// Done, create-new).
  final VoidCallback onCloseRequested;

  /// Popup layout when rendered in an overlay; `null` → inline mode.
  final GlobalPopupLayout? layout;

  /// Optional surface override forwarded from the dropdown's popup options.
  final GlobalPopupSurfaceStyle? surfaceStyle;

  /// Row visuals — merged over `GlobalDropdownTheme` + defaults.
  final DropdownStyle? dropdownStyle;

  /// Height cap in inline mode ([layout] `null`).
  final double inlineMaxHeight;

  @override
  State<DropdownSurface<T>> createState() => _DropdownSurfaceState<T>();
}

class _DropdownSurfaceState<T> extends State<DropdownSurface<T>> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _listScroll = ScrollController();
  Timer? _debounce;
  String _query = '';

  List<DropdownItem<T>>? _asyncItems;
  bool _asyncLoading = false;
  bool _asyncError = false;
  int _asyncRequestId = 0;

  late List<T> _working;
  T? _flashing;

  /// Resolved row visuals — materialized once per build (see [build]).
  late ResolvedDropdownStyle _rs;

  void _haptic() {
    if (_rs.enableHaptic) HapticFeedback.selectionClick();
  }

  bool get _isAsync => widget.asyncItemsLoader != null;

  List<DropdownItem<T>> get _allItems => (widget.groups?.isNotEmpty ?? false)
      ? widget.groups!.expand((g) => g.items).toList()
      : widget.items;

  /// Full item list the surface currently knows about.
  List<DropdownItem<T>> get _knownItems =>
      _isAsync ? (_asyncItems ?? const []) : _allItems;

  List<DropdownItem<T>> get _filtered {
    if (_isAsync) return _asyncItems ?? const [];
    if (_query.isEmpty) return _allItems;
    final q = _query.toLowerCase();
    return _allItems.where((i) => i.matchesQuery(q)).toList();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _working = List.of(widget.selectedValues);
    if (_isAsync) _load('');
  }

  @override
  void didUpdateWidget(covariant DropdownSurface<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.selectedValues, widget.selectedValues)) {
      _working = List.of(widget.selectedValues);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  // ─── Search + async ───────────────────────────────────────────

  /// Single search path: only the field's `onChanged` feeds it (the old
  /// widget also had a controller listener, double-firing the debounce).
  void _onQueryChanged(String value) {
    setState(() => _query = value);
    if (!_isAsync) return;
    _debounce?.cancel();
    _debounce = Timer(AppDurations.normal, () => _load(value));
  }

  Future<void> _load(String query) async {
    final id = ++_asyncRequestId;
    setState(() {
      _asyncLoading = true;
      _asyncError = false;
    });
    try {
      final results = await widget.asyncItemsLoader!(query);
      if (!mounted || id != _asyncRequestId) return;
      setState(() {
        _asyncItems = results;
        _asyncLoading = false;
      });
    } catch (_) {
      if (!mounted || id != _asyncRequestId) return;
      setState(() {
        _asyncLoading = false;
        _asyncError = true;
      });
    }
  }

  // ─── Selection ────────────────────────────────────────────────

  void _tapSingle(DropdownItem<T> item) {
    _haptic();
    widget.onSelected?.call(item);
    if (_reduceMotion) {
      widget.onCloseRequested();
      return;
    }
    setState(() => _flashing = item.value);
    Future.delayed(AppDurations.quick, () {
      if (mounted) setState(() => _flashing = null);
      widget.onCloseRequested();
    });
  }

  void _tapMulti(DropdownItem<T> item) {
    _haptic();
    setState(() {
      _working.contains(item.value)
          ? _working.remove(item.value)
          : _working.add(item.value);
    });
    widget.onMultiChanged?.call(List.of(_working), _knownItems);
  }

  /// "All" under a [DropdownSurface.maxSelections] cap means "at the
  /// cap" — the plain everything-selected predicate could never become
  /// true, leaving Clear all unreachable.
  bool get _allSelected {
    final selectable = _knownItems.where((i) => i.enabled).toList();
    if (selectable.isEmpty) return false;
    final cap = widget.maxSelections;
    if (cap != null && cap < selectable.length) return _working.length >= cap;
    return selectable.every((i) => _working.contains(i.value));
  }

  void _toggleSelectAll() {
    final selectable = _knownItems.where((i) => i.enabled).toList();
    setState(() {
      if (_allSelected) {
        _working = <T>[];
      } else {
        // Fill PRESERVING the user's existing picks — replacing the set
        // with take(cap) silently discarded them.
        final cap = widget.maxSelections ?? selectable.length;
        final next = List<T>.of(_working);
        for (final item in selectable) {
          if (next.length >= cap) break;
          if (!next.contains(item.value)) next.add(item.value);
        }
        _working = next;
      }
    });
    widget.onMultiChanged?.call(List.of(_working), _knownItems);
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _rs = (widget.dropdownStyle ?? const DropdownStyle()).resolve(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.enableSearch) _buildSearchField(context),
        Flexible(child: _buildBody(context)),
        if (widget.multiSelect && _working.isNotEmpty) _buildFooter(context),
      ],
    );

    final layout = widget.layout;
    if (layout != null) {
      return GlobalPopupSurface(
        layout: layout,
        style: widget.surfaceStyle,
        child: _morph(BoxConstraints(maxHeight: layout.maxHeight), content),
      );
    }

    // Inline mode — bordered in-tree panel.
    final radius = BorderRadius.circular(context.radii.md);
    return Container(
      decoration: BoxDecoration(
        color: context.backgroundColors.surface,
        borderRadius: radius,
        border: Border.all(color: context.backgroundColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: _morph(
        BoxConstraints(maxHeight: widget.inlineMaxHeight),
        content,
      ),
    );
  }

  /// Height morph while the open session's content changes (search
  /// narrowing the list, async results landing, footer appearing) —
  /// mirrors the text field's suggestions overlay. The AnimatedSize
  /// sits ABOVE the height cap: with the cap inside, a long list is
  /// properly height-limited (and scrolls) while grow/shrink tweens;
  /// with the cap outside, the list lays out full-height past the clip
  /// and scrolling breaks.
  Widget _morph(BoxConstraints cap, Widget child) {
    return AnimatedSize(
      duration: _reduceMotion ? AppDurations.instant : AppDurations.quick,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: cap, child: child),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.spacing.sm),
      child: GlobalTextFormField(
        controller: _searchCtrl,
        hint: DropDownStrings.search,
        identifier: widget.searchIdentifier,
        callbacks: TextFieldCallbacks(onChanged: _onQueryChanged),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_asyncLoading) return _buildLoadingShimmer(context);
    if (_asyncError) return _buildErrorRow(context);

    final filtered = _filtered;
    final showCreateNew =
        widget.onCreateNew != null &&
        filtered.isEmpty &&
        _query.trim().isNotEmpty;

    if ((widget.groups?.isNotEmpty ?? false) && !_isAsync) {
      return _buildGroupedList(context, showCreateNew: showCreateNew);
    }
    if (filtered.isEmpty && !showCreateNew) return _buildEmpty(context);
    return _buildFlatList(context, filtered, showCreateNew: showCreateNew);
  }

  /// Item-shaped shimmer rows while the async loader runs — matches the
  /// trigger's shimmer treatment instead of a spinner popping into an
  /// otherwise item-shaped surface (varying widths sell "rows of text
  /// are coming").
  Widget _buildLoadingShimmer(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      // stretch gives the FractionallySizedBox the full row width to
      // fraction against — without it the Column centers the bars.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final widthFactor in const [0.9, 0.65, 0.8])
          Padding(
            padding: _rs.itemPadding,
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              alignment: AlignmentDirectional.centerStart,
              child: GlobalShimmer.placeholder(
                width: double.infinity,
                height: context.spacing.md,
                borderRadius: BorderRadius.circular(context.radii.xs),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.spacing.md),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: context.iconSizes.sm,
            color: context.statusColors.error,
          ),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Text(
              DropDownStrings.loadFailed,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.statusColors.error,
              ),
            ),
          ),
          GlobalTextButton(
            text: Tr.t('common_retry', S.current.common_retry),
            onPressed: () => _load(_query),
            shrinkWidth: true,
            enforceMinTouchTarget: false,
            style: ButtonStateStyle(
              textStyle: context.textTheme.labelMedium,
              padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    if (widget.emptyBuilder != null) return widget.emptyBuilder!(context);
    return Padding(
      padding: EdgeInsets.all(context.spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: context.iconSizes.lg,
            color: context.textColors.secondary,
          ),
          SizedBox(height: context.spacing.sm),
          Text(
            DropDownStrings.noResults,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Scroll-edge effect (fade/scrim/shadow/blur per the resolved
  /// style) — the softened edge doubles as the "more rows" affordance.
  Widget _withEdgeFade(Widget list) {
    return GlobalEdgeFade(
      controller: _listScroll,
      style: _rs.edgeFade,
      child: list,
    );
  }

  Widget _buildFlatList(
    BuildContext context,
    List<DropdownItem<T>> filtered, {
    required bool showCreateNew,
  }) {
    final totalCount = filtered.length + (showCreateNew ? 1 : 0);
    return _withEdgeFade(
      ListView.builder(
        controller: _listScroll,
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: totalCount,
        itemBuilder: (_, i) {
          if (showCreateNew && i == filtered.length) {
            return _buildCreateNewRow(context);
          }
          return _buildRow(context, filtered[i]);
        },
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context, {
    required bool showCreateNew,
  }) {
    final q = _query.toLowerCase();
    final entries = <_GroupEntry<T>>[];
    for (final group in widget.groups!) {
      final groupItems = q.isEmpty
          ? group.items
          : group.items.where((i) => i.matchesQuery(q)).toList();
      if (groupItems.isNotEmpty) {
        entries.add(_GroupEntry<T>.header(group.label));
        entries.addAll(groupItems.map(_GroupEntry<T>.item));
      }
    }
    if (entries.isEmpty && !showCreateNew) return _buildEmpty(context);

    final totalCount = entries.length + (showCreateNew ? 1 : 0);
    return _withEdgeFade(
      ListView.builder(
        controller: _listScroll,
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: totalCount,
        itemBuilder: (_, i) {
          if (showCreateNew && i == entries.length) {
            return _buildCreateNewRow(context);
          }
          final entry = entries[i];
          if (entry.isHeader) return _buildGroupHeader(context, entry.label!);
          return _buildRow(context, entry.item!);
        },
      ),
    );
  }

  Widget _buildGroupHeader(BuildContext context, String label) {
    final accent = _rs.accentColor;
    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.only(
        start: context.spacing.md,
        end: context.spacing.md,
        top: context.spacing.sm + context.spacing.xs,
        bottom: context.spacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: accent.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: context.spacing.sm + context.spacing.xs,
            margin: EdgeInsetsDirectional.only(end: context.spacing.sm),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(context.radii.xs),
            ),
          ),
          Text(label.toUpperCase(), style: _rs.groupHeaderTextStyle),
        ],
      ),
    );
  }

  Widget _buildCreateNewRow(BuildContext context) {
    final primary = context.primaryColors.primary;
    final query = _query.trim();
    return InkWell(
      onTap: () {
        widget.onCreateNew?.call(query);
        widget.onCloseRequested();
      },
      child: Semantics(
        button: true,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.md,
            vertical: context.spacing.sm + context.spacing.xs,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: context.backgroundColors.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                size: context.iconSizes.sm,
                color: primary,
              ),
              SizedBox(width: context.spacing.sm + context.spacing.xs),
              Expanded(
                child: Text(
                  DropDownStrings.createNew(query),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Rows ─────────────────────────────────────────────────────

  Widget _buildRow(BuildContext context, DropdownItem<T> item) {
    if (widget.multiSelect) {
      return _buildMultiRow(context, item, _working.contains(item.value));
    }
    return _buildSingleRow(context, item, widget.selectedValue == item.value);
  }

  Widget _buildSingleRow(
    BuildContext context,
    DropdownItem<T> item,
    bool sel,
  ) {
    final disabled = !item.enabled;
    final isFlashing = _flashing == item.value;

    final Widget body;
    if (widget.itemBuilder != null) {
      body = widget.itemBuilder!(context, item, sel);
    } else {
      body = _rowContainer(
        context,
        sel: sel,
        flashing: isFlashing,
        child: Row(
          children: [
            if (item.effectiveDropdownLeading != null) ...[
              item.effectiveDropdownLeading!,
              SizedBox(width: context.spacing.sm + context.spacing.xs),
            ],
            Expanded(
              child: Text(
                item.effectiveDropdownLabel,
                style: sel ? _rs.selectedItemTextStyle : _rs.itemTextStyle,
              ),
            ),
            if (item.effectiveDropdownTrailing != null) ...[
              SizedBox(width: context.spacing.sm),
              item.effectiveDropdownTrailing!,
            ],
            if (sel) ...[
              SizedBox(width: context.spacing.sm),
              Icon(
                Icons.check,
                size: context.iconSizes.xs,
                color: _rs.accentColor,
              ),
            ],
          ],
        ),
      );
    }

    return Semantics(
      button: true,
      selected: sel,
      enabled: !disabled,
      label: item.effectiveDropdownLabel,
      child: Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: InkWell(
          onTap: disabled ? null : () => _tapSingle(item),
          child: body,
        ),
      ),
    );
  }

  Widget _buildMultiRow(BuildContext context, DropdownItem<T> item, bool sel) {
    final cap = widget.maxSelections;
    final disabledByLimit = !sel && cap != null && _working.length >= cap;
    final disabled = !item.enabled || disabledByLimit;

    final Widget body;
    if (widget.itemBuilder != null) {
      body = widget.itemBuilder!(context, item, sel);
    } else {
      body = _rowContainer(
        context,
        sel: sel,
        flashing: false,
        child: Row(
          children: [
            _buildCheckbox(context, sel: sel, disabled: disabled),
            SizedBox(width: context.spacing.sm + context.spacing.xs),
            if (item.effectiveDropdownLeading != null) ...[
              item.effectiveDropdownLeading!,
              SizedBox(width: context.spacing.sm + context.spacing.xs),
            ],
            Expanded(
              child: Text(
                item.effectiveDropdownLabel,
                style: sel ? _rs.selectedItemTextStyle : _rs.itemTextStyle,
              ),
            ),
            if (item.effectiveDropdownTrailing != null) ...[
              SizedBox(width: context.spacing.sm),
              item.effectiveDropdownTrailing!,
            ],
          ],
        ),
      );
    }

    return Semantics(
      button: true,
      selected: sel,
      checked: sel,
      enabled: !disabled,
      label: item.effectiveDropdownLabel,
      child: Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: InkWell(
          onTap: disabled ? null : () => _tapMulti(item),
          child: body,
        ),
      ),
    );
  }

  Widget _buildCheckbox(
    BuildContext context, {
    required bool sel,
    required bool disabled,
  }) {
    final accent = _rs.accentColor;
    final box = Container(
      width: _rs.checkboxSize,
      height: _rs.checkboxSize,
      decoration: BoxDecoration(
        color: sel ? accent : Colors.transparent,
        border: Border.all(
          color: sel ? accent : context.backgroundColors.outline,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(context.radii.xs),
      ),
      child: sel
          ? Icon(
              Icons.check,
              size: _rs.checkboxSize - context.spacing.xs,
              color: context.textColors.onPrimary,
            )
          : null,
    );
    if (_reduceMotion) return box;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: sel ? 0.8 : 1.0, end: 1.0),
      duration: AppDurations.quick,
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: box,
    );
  }

  Widget _rowContainer(
    BuildContext context, {
    required bool sel,
    required bool flashing,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: _reduceMotion ? AppDurations.instant : AppDurations.quick,
      decoration: BoxDecoration(
        color: flashing
            ? _rs.flashTint
            : sel
            ? _rs.selectedTint
            : null,
        border: sel && _rs.accentBarWidth > 0
            ? BorderDirectional(
                start: BorderSide(
                  color: _rs.accentColor,
                  width: _rs.accentBarWidth,
                ),
              )
            : null,
      ),
      padding: _rs.itemPadding,
      child: child,
    );
  }

  // ─── Footer ───────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context) {
    final allSelected = _allSelected;

    final cap = widget.maxSelections;
    final selectionText = cap != null
        ? DropDownStrings.selectedOfMax(_working.length, cap)
        : DropDownStrings.selectedCount(_working.length);

    final buttonStyle = ButtonStateStyle(
      textStyle: context.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm + context.spacing.xs,
        vertical: context.spacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.backgroundColors.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectionText,
              style: context.textTheme.labelMedium?.copyWith(
                color: context.textColors.secondary,
              ),
            ),
          ),
          GlobalTextButton(
            onPressed: _toggleSelectAll,
            text: allSelected
                ? DropDownStrings.clearAll
                : DropDownStrings.selectAll,
            style: buttonStyle,
            shrinkWidth: true,
            enforceMinTouchTarget: false,
          ),
          GlobalTextButton(
            onPressed: widget.onCloseRequested,
            text: Tr.t('common_done', S.current.common_done),
            style: buttonStyle,
            shrinkWidth: true,
            enforceMinTouchTarget: false,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _GroupEntry — flattened header-or-item for grouped rendering
// ---------------------------------------------------------------------------

class _GroupEntry<T> {
  final String? label;
  final DropdownItem<T>? item;

  const _GroupEntry.header(this.label) : item = null;
  const _GroupEntry.item(this.item) : label = null;

  bool get isHeader => label != null;
}
