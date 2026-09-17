import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/common_strings.dart';
import '../../../../core/localization/strings/field_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../divider/global_divider.dart';
import '../models/popup_models.dart';
import 'surface_base.dart';

/// One item in a [GlobalPopupMenuView]. Supports plain items, dividers,
/// section headers, toggled (checkmark) items, destructive items,
/// keyboard-shortcut hints, and direct `onTap` callbacks.
@immutable
class GlobalPopupMenuItem<T> {
  const GlobalPopupMenuItem({
    required this.value,
    required this.label,
    this.leading,
    this.icon,
    this.iconColor,
    this.trailing,
    this.shortcut,
    this.labelStyle,
    this.enabled = true,
    this.destructive = false,
    this.toggled,
    this.onTap,
    this.isDivider = false,
    this.sectionTitle,
    this.semanticLabel,
  });

  /// Divider entry — `value`, `label`, etc. unused.
  factory GlobalPopupMenuItem.divider() => const GlobalPopupMenuItem(
    value: null,
    label: '',
    isDivider: true,
  );

  /// Section header — non-selectable. Pass section title as `label`.
  factory GlobalPopupMenuItem.section(String title) =>
      GlobalPopupMenuItem(value: null, label: title, sectionTitle: title);

  final T? value;
  final String label;

  /// Custom leading widget. Takes priority over [icon].
  final Widget? leading;

  /// Convenience icon — wrapped in `Icon(icon, color: iconColor)`.
  final IconData? icon;

  /// Override icon tint. Null → matches text color (red when destructive).
  final Color? iconColor;

  final Widget? trailing;

  /// Trailing shortcut text like `⌘C`. Rendered to the right of the label.
  final String? shortcut;

  /// Custom label TextStyle. Null = derived from theme + destructive flag.
  final TextStyle? labelStyle;

  final bool enabled;

  /// Renders the label in destructive red + bold weight.
  final bool destructive;

  /// When non-null, shows a checkmark (true) or empty slot (false). For
  /// toggle / radio-style items.
  final bool? toggled;

  /// Direct callback — fires INSTEAD of the menu's `onSelected(value)`.
  final VoidCallback? onTap;

  final bool isDivider;

  /// Non-null marks this entry as a section header (not selectable).
  final String? sectionTitle;
  final String? semanticLabel;

  bool get isHeader => sectionTitle != null;
}

/// Pre-built menu surface. Use as the `overlay` builder of a
/// [GlobalPopup]. Supports sections + optional search filter.
class GlobalPopupMenuView<T> extends StatefulWidget {
  const GlobalPopupMenuView({
    super.key,
    required this.layout,
    required this.items,
    required this.onSelected,
    this.style,
    this.maxWidth,
    this.arrow,
    this.searchable = false,
    this.searchHint,
    this.emptyText,
    this.autoWidth = false,
  });

  final GlobalPopupLayout layout;
  final List<GlobalPopupMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final GlobalPopupSurfaceStyle? style;

  /// Hard cap on the rendered menu width. Combine with [autoWidth] to
  /// size-to-widest-item up to this cap.
  final double? maxWidth;
  final GlobalPopupArrow? arrow;

  /// When true, renders a search field at the top filtering by label.
  final bool searchable;
  final String? searchHint;
  final String? emptyText;

  /// Old `popup_menu` behavior — surface shrinks to the widest item
  /// instead of stretching to anchor / fixed width. Combine with
  /// [maxWidth] to clamp the upper bound when items can be wide
  /// (URLs, long labels). When `false` (default), the surface respects
  /// the popup's normal width strategy.
  final bool autoWidth;

  @override
  State<GlobalPopupMenuView<T>> createState() => _GlobalPopupMenuViewState<T>();
}

class _GlobalPopupMenuViewState<T> extends State<GlobalPopupMenuView<T>> {
  final _searchCtrl = TextEditingController();
  final _menuFocus = FocusNode(debugLabel: 'GlobalPopupMenuView');
  String _query = '';
  int _focusedIndex = -1;

  @override
  void initState() {
    super.initState();
    // Autofocus the menu shell so keyboard input routes to the
    // shortcuts handler from the first frame onward (without stealing
    // focus from the search field when present).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.searchable) return;
      _menuFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _menuFocus.dispose();
    super.dispose();
  }

  /// Indices of selectable (non-divider, non-section) items within the
  /// filtered list. Used to skip headers/dividers when moving focus.
  List<int> _selectableIndices(List<GlobalPopupMenuItem<T>> items) {
    final out = <int>[];
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      if (!it.isDivider && !it.isHeader && it.enabled) out.add(i);
    }
    return out;
  }

  void _moveFocus(int delta, List<GlobalPopupMenuItem<T>> items) {
    final selectable = _selectableIndices(items);
    if (selectable.isEmpty) return;
    final cursor = selectable.indexOf(_focusedIndex);
    final nextCursor = (cursor < 0
        ? (delta > 0 ? 0 : selectable.length - 1)
        : (cursor + delta) % selectable.length);
    setState(
      () => _focusedIndex =
          selectable[nextCursor < 0
              ? nextCursor + selectable.length
              : nextCursor],
    );
  }

  void _activateFocused(List<GlobalPopupMenuItem<T>> items) {
    if (_focusedIndex < 0 || _focusedIndex >= items.length) return;
    final item = items[_focusedIndex];
    if (item.onTap != null) {
      item.onTap!();
    } else if (item.value != null) {
      widget.onSelected(item.value as T);
    }
  }

  List<GlobalPopupMenuItem<T>> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    final out = <GlobalPopupMenuItem<T>>[];
    String? currentSection;
    var pendingSection = false;
    for (final it in widget.items) {
      if (it.isHeader) {
        currentSection = it.sectionTitle;
        pendingSection = true;
        continue;
      }
      if (it.isDivider) continue;
      if (!it.label.toLowerCase().contains(q)) continue;
      if (pendingSection && currentSection != null) {
        out.add(GlobalPopupMenuItem.section(currentSection));
        pendingSection = false;
      }
      out.add(it);
    }
    return out;
  }

  Widget _buildItem(
    BuildContext context,
    GlobalPopupMenuItem<T> item, {
    bool focused = false,
  }) {
    if (item.isDivider) {
      // Dividers are purely decorative — skip them in the semantics
      // tree so screen-reader users don't hear "separator" between
      // every item.
      return const ExcludeSemantics(
        child: GlobalDivider(),
      );
    }
    if (item.isHeader) {
      return _SectionHeader(label: item.sectionTitle!);
    }
    return _MenuItemTile<T>(
      item: item,
      onSelected: widget.onSelected,
      keyboardFocused: focused,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    // ArrowUp/ArrowDown move highlight, Enter activates, Escape closes.
    // Wrapping the menu in `CallbackShortcuts` lets us drive keyboard
    // navigation without needing a per-item `FocusNode`.
    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
          _moveFocus(1, filtered),
      const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
          _moveFocus(-1, filtered),
      const SingleActivator(LogicalKeyboardKey.enter): () =>
          _activateFocused(filtered),
      const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
          _activateFocused(filtered),
    };
    return GlobalPopupSurface(
      layout: widget.layout,
      style: widget.style,
      maxWidth: widget.maxWidth,
      arrow: widget.arrow,
      child: CallbackShortcuts(
        bindings: shortcuts,
        child: Focus(
          focusNode: _menuFocus,
          // Don't trap Tab — let the surrounding `FocusTraversalGroup`
          // handle Tab between menu items if user prefers it over
          // arrow-keys.
          skipTraversal: true,
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.searchable)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.spacing.sm,
                      context.spacing.sm,
                      context.spacing.sm,
                      context.spacing.xs,
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: widget.searchHint ?? FieldStrings.searchHint,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.radii.sm),
                        ),
                        prefixIcon: const Icon(Icons.search, size: 18),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                Flexible(
                  child: filtered.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: context.spacing.lg,
                          ),
                          child: Text(
                            widget.emptyText ?? CommonStrings.noResults,
                          ),
                        )
                      : FocusTraversalGroup(
                          // When autoWidth is on the surface is wrapped in
                          // IntrinsicWidth, which queries `computeMaxIntrinsicWidth`
                          // down the tree. Viewports (ListView / SingleChildScrollView)
                          // throw on that query, so we MUST render an
                          // intrinsic-friendly tree — `Column` of pre-built
                          // children. `SingleChildScrollView` then wraps the
                          // Column for vertical scrolling; that's safe
                          // because the intrinsic query stops at the Column
                          // wrapper's children inside SingleChildScrollView
                          // (the scrollable receives a tight width from
                          // outside, not from intrinsic measurement).
                          child: widget.autoWidth
                              ? SingleChildScrollView(
                                  padding: EdgeInsets.zero,
                                  child: IntrinsicWidth(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        for (
                                          var i = 0;
                                          i < filtered.length;
                                          i++
                                        )
                                          _buildItem(
                                            context,
                                            filtered[i],
                                            focused: i == _focusedIndex,
                                          ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: filtered.length,
                                  itemBuilder: (ctx, i) => _buildItem(
                                    ctx,
                                    filtered[i],
                                    focused: i == _focusedIndex,
                                  ),
                                ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.md,
        context.spacing.sm,
        context.spacing.md,
        context.spacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MenuItemTile<T> extends StatelessWidget {
  const _MenuItemTile({
    required this.item,
    required this.onSelected,
    this.keyboardFocused = false,
  });

  final GlobalPopupMenuItem<T> item;
  final ValueChanged<T> onSelected;

  /// True when this item is the current keyboard-navigation cursor.
  /// Renders an extra hover-color background so users can see which
  /// item Enter would activate.
  final bool keyboardFocused;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Pull destructive tint from the project's role-aware extension
    // instead of a hardcoded literal so it respects palette + dark mode.
    final destructiveColor = context.statusColors.error;
    final fg = !item.enabled
        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
        : item.destructive
        ? destructiveColor
        : theme.colorScheme.onSurface;
    final iconColor = item.iconColor ?? fg;
    final selectedBg = theme.colorScheme.primary.withValues(alpha: 0.08);
    final keyboardBg = theme.colorScheme.onSurface.withValues(alpha: 0.06);

    final hasIcon = item.leading != null || item.icon != null;
    final showsCheckmark = item.toggled != null;

    void handleTap() {
      if (!item.enabled) return;
      if (item.onTap != null) {
        item.onTap!();
      } else if (item.value != null) {
        onSelected(item.value as T);
      }
    }

    return Semantics(
      button: true,
      enabled: item.enabled,
      // Toggle items report selected state so the screen reader
      // announces "checked"/"unchecked".
      selected: item.toggled,
      label: item.semanticLabel ?? item.label,
      child: Material(
        color: item.toggled == true
            ? selectedBg
            : keyboardFocused
            ? keyboardBg
            : Colors.transparent,
        child: InkWell(
          onTap: item.enabled ? handleTap : null,
          hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.md,
              vertical: context.spacing.sm,
            ),
            child: Row(
              children: [
                if (showsCheckmark) ...[
                  SizedBox(
                    width: 20,
                    child: item.toggled!
                        ? Icon(Icons.check_rounded, size: 18, color: fg)
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 12),
                ] else if (hasIcon) ...[
                  item.leading ?? Icon(item.icon, size: 18, color: iconColor),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    item.label,
                    style:
                        item.labelStyle ??
                        TextStyle(
                          color: fg,
                          fontWeight: item.destructive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.shortcut != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    item.shortcut!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (item.trailing != null) ...[
                  const SizedBox(width: 12),
                  item.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
