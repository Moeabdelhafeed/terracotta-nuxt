import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../../../core/utils/device/info/screen_radius.dart';
import '../avatar/global_avatar.dart';
import '../badge/global_badge.dart';
import '../buttons/global_icon_button.dart';
import '../divider/global_divider.dart';
import '../shimmer/global_shimmer.dart';
import '../text/global_text.dart';
import '../text_field/global_text_field.dart';
import '../tooltip/global_tooltip.dart';
import 'drawer_models.dart';
import 'theme/drawer_theme.dart';

export 'drawer_models.dart';
export 'theme/drawer_theme.dart';

part 'drawer_internals.dart';

/// A themed navigation drawer with header, sections, items, badges,
/// expandable items, collapsible sections, notification dots, staggered
/// entrance animation, search/filter, mini/rail mode, account switcher,
/// swipeable items, reorderable items, loading skeleton, compact mode,
/// pinned items, header actions, and customizable styling.
class GlobalDrawer extends StatefulWidget {
  // ─── Constants ─────────────────────────────────────────────

  // ─── Fields ────────────────────────────────────────────────

  /// Header widget at the top (e.g. user avatar, app logo).
  final Widget? header;

  /// Navigation sections with grouped items.
  final List<DrawerSection> sections;

  /// Footer widget at the bottom.
  final Widget? footer;

  /// Styling configuration.
  final DrawerStyle style;

  /// Called when the drawer should close.
  final VoidCallback? onClose;

  /// Whether this is an end drawer (right side).
  final bool isEndDrawer;

  /// Enable search/filter bar above items.
  final bool showSearch;

  /// Hint text for the search bar.
  final String searchHint;

  /// Custom search filter. If null, filters by item title.
  final bool Function(DrawerItem item, String query)? searchFilter;

  /// Mini/rail mode — shows only icons, expands on tap.
  final bool miniMode;

  /// Called when mini mode expand button is tapped.
  final VoidCallback? onExpandMini;

  /// Account switcher data. Shows account header when provided.
  final List<DrawerAccount>? accounts;

  /// Called when an account is switched.
  final ValueChanged<DrawerAccount>? onAccountSwitch;

  /// Action buttons shown in the header area.
  final List<Widget>? headerActions;

  /// Shows loading skeleton instead of items.
  final bool loading;

  /// Number of skeleton placeholder items.
  final int skeletonCount;

  /// Enable drag-to-reorder on items.
  final bool reorderable;

  /// Called when items are reordered (section index, old index, new index).
  final void Function(int sectionIndex, int oldIndex, int newIndex)? onReorder;

  /// Row of icon buttons shown in the footer area.
  final List<Widget>? footerActions;

  const GlobalDrawer({
    super.key,
    this.header,
    this.sections = const [],
    this.footer,
    this.style = const DrawerStyle(),
    this.onClose,
    this.isEndDrawer = false,
    this.showSearch = false,
    this.searchHint = 'Search...',
    this.searchFilter,
    this.miniMode = false,
    this.onExpandMini,
    this.accounts,
    this.onAccountSwitch,
    this.headerActions,
    this.loading = false,
    this.skeletonCount = DrawerDefaults.skeletonItems,
    this.reorderable = false,
    this.onReorder,
    this.footerActions,
  });

  // ─── Factories ─────────────────────────────────────────────

  /// Simple drawer with flat item list (no sections).
  factory GlobalDrawer.simple({
    Key? key,
    Widget? header,
    required List<DrawerItem> items,
    Widget? footer,
    DrawerStyle style = const DrawerStyle(),
    VoidCallback? onClose,
    bool isEndDrawer = false,
    bool showSearch = false,
    String searchHint = 'Search...',
    bool Function(DrawerItem, String)? searchFilter,
    bool miniMode = false,
    VoidCallback? onExpandMini,
    List<DrawerAccount>? accounts,
    ValueChanged<DrawerAccount>? onAccountSwitch,
    List<Widget>? headerActions,
    bool loading = false,
    int skeletonCount = DrawerDefaults.skeletonItems,
    bool reorderable = false,
    void Function(int, int, int)? onReorder,
    List<Widget>? footerActions,
  }) => GlobalDrawer(
    key: key,
    header: header,
    footer: footer,
    style: style,
    onClose: onClose,
    isEndDrawer: isEndDrawer,
    showSearch: showSearch,
    searchHint: searchHint,
    searchFilter: searchFilter,
    miniMode: miniMode,
    onExpandMini: onExpandMini,
    accounts: accounts,
    onAccountSwitch: onAccountSwitch,
    headerActions: headerActions,
    loading: loading,
    skeletonCount: skeletonCount,
    reorderable: reorderable,
    onReorder: onReorder,
    footerActions: footerActions,
    sections: [DrawerSection(items: items)],
  );

  /// The scrim a drawer asks for, for the `Scaffold` that has to paint
  /// it. See [DrawerStyle.scrimColor] — the value lives on the drawer,
  /// the backdrop belongs to the scaffold, and this is the seam.
  static Color? scrimOf(Widget? drawer) =>
      drawer is GlobalDrawer ? drawer.style.scrimColor : null;

  @override
  State<GlobalDrawer> createState() => _GlobalDrawerState();
}

class _GlobalDrawerState extends State<GlobalDrawer>
    with SingleTickerProviderStateMixin {
  AnimationController? _entranceCtrl;
  int _totalItemCount = 0;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  /// Materialized once per build: `caller > theme > defaults`, then
  /// colours from the palette and width from the breakpoint.
  late ResolvedDrawerStyle _rs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rs = widget.style.resolve(context, mini: widget.miniMode);
    _syncEntrance();
  }

  @override
  void didUpdateWidget(GlobalDrawer old) {
    super.didUpdateWidget(old);
    _rs = widget.style.resolve(context, mini: widget.miniMode);
    _syncEntrance();
  }

  /// The staggered entrance lives here rather than in `initState`
  /// because it needs two things `initState` cannot see: the RESOLVED
  /// style (the theme can turn it on app-wide) and the reduced-motion
  /// setting. A staggered reveal is decoration — exactly what
  /// `disableAnimations` asks to be spared — so it is not merely sped up
  /// but skipped, and the rows are simply there.
  void _syncEntrance() {
    final wanted = _rs.animateItems && !MediaQuery.disableAnimationsOf(context);
    if (wanted && _entranceCtrl == null) {
      _totalItemCount = _countAllItems();
      _entranceCtrl = AnimationController(
        vsync: this,
        duration: _rs.entranceAnimationDuration,
      )..forward();
    } else if (!wanted && _entranceCtrl != null) {
      _entranceCtrl!.dispose();
      _entranceCtrl = null;
    }
  }

  @override
  void dispose() {
    _entranceCtrl?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  int _countAllItems() {
    var count = 0;
    for (final s in widget.sections) {
      count += s.items.length;
      for (final item in s.items) {
        if (item.hasChildren) count += item.children!.length;
      }
    }
    return count;
  }

  bool _matchesSearch(DrawerItem item) {
    if (_searchQuery.isEmpty) return true;
    if (widget.searchFilter != null) {
      return widget.searchFilter!(item, _searchQuery);
    }
    final q = _searchQuery.toLowerCase();
    if (item.title.toLowerCase().contains(q)) return true;
    if (item.subtitle?.toLowerCase().contains(q) ?? false) return true;
    if (item.hasChildren) return item.children!.any(_matchesSearch);
    return false;
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bg = _rs.backgroundColor;
    final primary = _rs.selectedColor;
    final itemRadius = _rs.itemBorderRadius;
    final isMini = widget.miniMode;
    // Width, the mini override and the bucket-aware default all resolve
    // together — see `DrawerStyleResolve.resolve`.
    final width = _rs.width;
    final borderRadius = _resolveRadius();

    // ── Mini/rail mode ──
    if (isMini) {
      return _buildDrawerShell(
        width,
        borderRadius,
        isDark,
        bg,
        child: _buildMiniContent(cs, primary, isDark),
      );
    }

    var itemIndex = 0;

    final content = Column(
      children: [
        // Account switcher header
        if (widget.accounts != null && widget.accounts!.isNotEmpty)
          _buildAccountSwitcher(cs, isDark),

        // Custom header + actions row
        if (widget.header != null ||
            (widget.headerActions != null && widget.headerActions!.isNotEmpty))
          _buildHeaderRow(),

        // Search bar
        if (widget.showSearch) _buildSearchBar(cs),

        // Loading skeleton
        if (widget.loading)
          Expanded(child: _buildSkeleton())
        // Sections
        else
          Expanded(
            child: _buildSectionsList(
              cs,
              primary,
              itemRadius,
              () => itemIndex,
              (v) => itemIndex = v,
              bg,
            ),
          ),

        // Footer actions bar
        if (widget.footerActions != null && widget.footerActions!.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              DrawerDefaults.footerActionsPad,
              DrawerDefaults.footerActionsSpacing,
              DrawerDefaults.footerActionsPad,
              0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.footerActions!,
            ),
          ),

        // Footer
        if (widget.footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              DrawerDefaults.hPad,
              DrawerDefaults.itemVPad,
              DrawerDefaults.hPad,
              DrawerDefaults.hPad,
            ),
            child: widget.footer,
          ),
      ],
    );

    return _buildDrawerShell(width, borderRadius, isDark, bg, child: content);
  }

  // ─── Drawer shell ─────────────────────────────────────────

  Widget _buildDrawerShell(
    double width,
    BorderRadius borderRadius,
    bool isDark,
    Color bg, {
    required Widget child,
  }) {
    final body = _buildBackground(child, bg, borderRadius, isDark);

    if (_rs.floating) {
      return Drawer(
        width: width + _rs.floatingMargin.horizontal,
        elevation: 0,
        backgroundColor: Colors.transparent,
        clipBehavior: Clip.none,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: _rs.floatingMargin,
            child: ClipRRect(borderRadius: borderRadius, child: body),
          ),
        ),
      );
    }

    return Drawer(
      width: width,
      elevation: 0,
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.none,
      child: ClipRRect(borderRadius: borderRadius, child: body),
    );
  }

  // ─── Header row with actions ──────────────────────────────

  Widget _buildHeaderRow() {
    final hasActions =
        widget.headerActions != null && widget.headerActions!.isNotEmpty;
    return Padding(
      padding: _rs.headerPadding,
      child: hasActions
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.header != null) Expanded(child: widget.header!),
                if (widget.header == null) const Spacer(),
                ...widget.headerActions!,
              ],
            )
          : widget.header!,
    );
  }

  // ─── Account switcher ─────────────────────────────────────

  Widget _buildAccountSwitcher(ColorScheme cs, bool isDark) {
    final accounts = widget.accounts!;
    final selected = accounts.firstWhere(
      (a) => a.selected,
      orElse: () => accounts.first,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        DrawerDefaults.headerHPad,
        DrawerDefaults.headerVPad,
        DrawerDefaults.headerHPad,
        DrawerDefaults.hPad,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected account
          Row(
            children: [
              // `GlobalAvatar` rather than a raw `CircleAvatar`: it
              // generates a colour from the NAME, so two accounts are
              // told apart at a glance instead of both landing on the
              // theme's default grey.
              GlobalAvatar(
                name: selected.name,
                imageProvider: selected.avatar,
                size: DrawerDefaults.accountAvatarSize,
              ),
              const SizedBox(width: DrawerDefaults.avatarSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlobalText(
                      selected.name,
                      preset: TextPreset.bodyLarge,
                      textStyle: const GlobalTextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (selected.email != null)
                      GlobalText(
                        selected.email!,
                        textStyle: GlobalTextStyle(
                          fontSize: context.textTheme.bodySmall?.fontSize,
                          color: _rs.subtitleColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Other accounts row
          if (accounts.length > 1) ...[
            const SizedBox(height: DrawerDefaults.accountSwitcherSpacing),
            SizedBox(
              height: DrawerDefaults.accountSmallAvatarSize,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: accounts.length,
                separatorBuilder: (_, _) => const SizedBox(
                  width: DrawerDefaults.accountSwitcherSpacing,
                ),
                itemBuilder: (_, i) {
                  final account = accounts[i];
                  final isSelected = account.selected;
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: [
                      account.name,
                      ?account.email,
                    ].join(', '),
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () {
                        if (_rs.enableHaptic) HapticFeedback.selectionClick();
                        widget.onAccountSwitch?.call(account);
                        account.onTap?.call();
                      },
                      child: AnimatedContainer(
                        duration: DrawerDefaults.accountAnimDuration,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: _rs.selectedColor,
                                  width: DrawerDefaults.accountRingWidth,
                                )
                              : null,
                        ),
                        child: GlobalAvatar(
                          name: account.name,
                          imageProvider: account.avatar,
                          size:
                              DrawerDefaults.accountSmallAvatarSize -
                              (isSelected
                                  ? DrawerDefaults.accountRingWidth * 2
                                  : 0),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Search bar ───────────────────────────────────────────

  Widget _buildSearchBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        DrawerDefaults.searchPad,
        0,
        DrawerDefaults.searchPad,
        DrawerDefaults.searchPad,
      ),
      child: GlobalTextFormField(
        controller: _searchCtrl,
        hint: widget.searchHint,
        style: TextFieldStyle(
          borderRadius: BorderRadius.circular(DrawerDefaults.searchRadius),
          fillColor: _rs.searchFillColor,
        ),
        behavior: const TextFieldBehavior(
          textInputAction: TextInputAction.search,
        ),
        features: const TextFieldFeatures(showClearButton: true),
        slots: const TextFieldSlots(
          prefixIcon: Icon(Icons.search),
        ),
        callbacks: TextFieldCallbacks(
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      ),
    );
  }

  // ─── Sections list ────────────────────────────────────────

  Widget _buildSectionsList(
    ColorScheme cs,
    Color primary,
    BorderRadius itemRadius,
    int Function() getIndex,
    void Function(int) setIndex,
    Color bg,
  ) {
    // Check if search is active and nothing matches
    if (_searchQuery.isNotEmpty) {
      final hasAnyMatch = widget.sections.any(
        (s) => s.items.any(_matchesSearch),
      );
      if (!hasAnyMatch) return _buildSearchEmpty(cs);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: DrawerDefaults.hPad),
      children: [
        // Pinned items first
        for (final s in widget.sections)
          for (final item in s.items)
            if (item.pinned && _matchesSearch(item))
              _buildItemTree(
                item,
                primary,
                cs,
                itemRadius,
                getIndex(),
                0,
                onIndex: setIndex,
                bg: bg,
              ),

        for (var s = 0; s < widget.sections.length; s++) ...[
          if (s > 0) _buildSectionDivider(s),
          if (widget.sections[s].title != null)
            widget.sections[s].collapsible
                ? _CollapsibleSectionTitle(
                    style: _rs,
                    title: widget.sections[s].title!,
                    itemCount: widget.sections[s].showItemCount
                        ? widget.sections[s].items.length
                        : null,
                    initiallyExpanded: widget.sections[s].initiallyExpanded,
                    duration: _rs.expandAnimationDuration,
                    cs: cs,
                    children: [
                      for (final item in widget.sections[s].items)
                        if (!item.pinned && _matchesSearch(item))
                          _buildItemTree(
                            item,
                            primary,
                            cs,
                            itemRadius,
                            getIndex(),
                            0,
                            onIndex: setIndex,
                            bg: bg,
                          ),
                    ],
                  )
                : _buildSectionTitle(
                    widget.sections[s].title!,
                    cs,
                    widget.sections[s].showItemCount
                        ? widget.sections[s].items.length
                        : null,
                  ),
          if (!widget.sections[s].collapsible)
            if (widget.reorderable && widget.onReorder != null)
              _buildReorderableSection(
                s,
                primary,
                cs,
                itemRadius,
                getIndex,
                setIndex,
                bg,
              )
            else
              for (final item in widget.sections[s].items)
                if (!item.pinned && _matchesSearch(item))
                  _buildItemTree(
                    item,
                    primary,
                    cs,
                    itemRadius,
                    getIndex(),
                    0,
                    onIndex: setIndex,
                    bg: bg,
                  ),
        ],
      ],
    );
  }

  // ─── Search empty state ───────────────────────────────────

  Widget _buildSearchEmpty(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DrawerDefaults.headerHPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: DrawerDefaults.emptyIconSize,
              color: _rs.muted(DrawerDefaults.emptyIconOpacity),
            ),
            const SizedBox(height: DrawerDefaults.emptySpacing),
            GlobalText(
              DrawerStrings.noResults,
              textStyle: GlobalTextStyle(
                fontSize: context.textTheme.bodyLarge?.fontSize,
                fontWeight: FontWeight.w600,
                color: _rs.muted(DrawerDefaults.emptyTextOpacity),
              ),
            ),
            const SizedBox(height: DrawerDefaults.searchEmptyGap),
            GlobalText(
              DrawerStrings.noItemsMatch(_searchQuery),
              textStyle: GlobalTextStyle(
                fontSize: context.textTheme.bodySmall?.fontSize,
                color: _rs.muted(DrawerDefaults.emptySubtextOpacity),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Reorderable section ──────────────────────────────────

  Widget _buildReorderableSection(
    int sectionIdx,
    Color primary,
    ColorScheme cs,
    BorderRadius itemRadius,
    int Function() getIndex,
    void Function(int) setIndex,
    Color bg,
  ) {
    final items = widget.sections[sectionIdx].items
        .where((i) => !i.pinned && _matchesSearch(i))
        .toList();
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      onReorderItem: (oldIdx, newIdx) =>
          widget.onReorder?.call(sectionIdx, oldIdx, newIdx),
      proxyDecorator: (child, _, animation) => AnimatedBuilder(
        animation: animation,
        builder: (_, child) => Material(
          elevation: 4 * animation.value,
          borderRadius: itemRadius,
          child: child,
        ),
        child: child,
      ),
      itemBuilder: (_, i) {
        final idx = getIndex();
        setIndex(idx + 1);
        return KeyedSubtree(
          key: ValueKey('reorder_${sectionIdx}_$i'),
          child: _buildItemTree(
            items[i],
            primary,
            cs,
            itemRadius,
            idx,
            0,
            onIndex: setIndex,
            bg: bg,
          ),
        );
      },
    );
  }

  // ─── Mini/rail mode ───────────────────────────────────────

  Widget _buildMiniContent(ColorScheme cs, Color primary, bool isDark) {
    final itemRadius = _rs.itemBorderRadius;

    return Column(
      children: [
        const SizedBox(height: DrawerDefaults.headerVPad),
        // Expand button
        if (widget.onExpandMini != null)
          Padding(
            padding: const EdgeInsets.only(bottom: DrawerDefaults.hPad),
            child: GlobalIconButton(
              iconData: Icons.menu_rounded,
              onPressed: widget.onExpandMini,
              tooltip: DrawerStrings.expand,
              style: ButtonStateStyle(foregroundColor: _rs.iconColor),
            ),
          ),
        // Items as icon-only
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: DrawerDefaults.itemVPad,
            ),
            children: [
              for (final section in widget.sections)
                for (final item in section.items)
                  if (item.icon != null || item.avatar != null)
                    GlobalTooltip(
                      message: item.title,
                      style: const TooltipStyle(
                        waitDuration: DrawerDefaults.miniTooltipWait,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: DrawerDefaults.compactVPad,
                        ),
                        child: Material(
                          color: item.selected
                              ? primary.withValues(alpha: _rs.selectedBgOpacity)
                              : Colors.transparent,
                          borderRadius: itemRadius,
                          child: InkWell(
                            borderRadius: itemRadius,
                            onTap: () {
                              if (_rs.enableHaptic) {
                                HapticFeedback.selectionClick();
                              }
                              widget.onClose?.call();
                              item.onTap?.call();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(
                                DrawerDefaults.miniIconPad,
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (item.avatar != null)
                                    Center(
                                      child: SizedBox(
                                        width: _rs.iconSize,
                                        height: _rs.iconSize,
                                        child: item.avatar,
                                      ),
                                    )
                                  else
                                    Center(
                                      child: Icon(
                                        item.icon,
                                        size: _rs.iconSize,
                                        color: item.selected
                                            ? primary
                                            : _rs.iconColor,
                                      ),
                                    ),
                                  // The rail's own badge and dot used to
                                  // live here as a THIRD set of numbers,
                                  // different again from the row version
                                  // twenty lines away. Both are corner
                                  // overlays, which is exactly what
                                  // `GlobalBadge` wraps.
                                  if (item.showDot)
                                    PositionedDirectional(
                                      top: DrawerDefaults.miniDotOffset,
                                      end: DrawerDefaults.miniDotOffset,
                                      child: GlobalBadge.standalone(
                                        style: BadgeStyle(
                                          backgroundColor:
                                              item.dotColor ?? primary,
                                        ),
                                      ),
                                    ),
                                  if (item.badge != null)
                                    PositionedDirectional(
                                      top: DrawerDefaults.miniBadgeTopOffset,
                                      end: DrawerDefaults.miniBadgeEndOffset,
                                      child: GlobalBadge.standalone(
                                        label: item.badge,
                                        style: BadgeStyle(
                                          backgroundColor: primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
        // Footer
        if (widget.footer != null)
          Padding(
            padding: const EdgeInsets.all(DrawerDefaults.itemVPad),
            child: widget.footer,
          ),
      ],
    );
  }

  // ─── Loading skeleton ─────────────────────────────────────

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: DrawerDefaults.hPad),
      itemCount: widget.skeletonCount,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: DrawerDefaults.itemVPad),
        child: Row(
          children: [
            GlobalShimmer.circle(size: DrawerDefaults.skeletonIconSize),
            const SizedBox(width: DrawerDefaults.iconSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlobalShimmer.text(
                  width: DrawerDefaults.skeletonTitleWidth,
                  height: DrawerDefaults.skeletonItemHeight,
                ),
                const SizedBox(height: DrawerDefaults.skeletonGap),
                GlobalShimmer.text(
                  width: DrawerDefaults.skeletonSubtitleWidth,
                  height: DrawerDefaults.skeletonSubHeight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Radius resolution ────────────────────────────────────

  BorderRadius _resolveRadius() {
    if (_rs.borderRadius != null) return _rs.borderRadius!;

    if (_rs.useDeviceRadius && DeviceRadius.hasRoundedCorners) {
      return DeviceRadius.borderRadiusPadded;
    }

    return BorderRadius.circular(DrawerDefaults.fallbackRadius);
  }

  // ─── Background / border builder ──────────────────────────

  Widget _buildBackground(
    Widget content,
    Color bg,
    BorderRadius borderRadius,
    bool isDark,
  ) {
    final hasBorderGradient = _rs.borderGradient != null;
    final hasBorder = _rs.border != null;

    if (hasBorderGradient) {
      return Container(
        decoration: BoxDecoration(
          gradient: _rs.borderGradient,
          borderRadius: borderRadius,
          boxShadow: _rs.floating
              ? [
                  BoxShadow(
                    color: context.overlayColors.scrim.withValues(
                      alpha: isDark
                          ? DrawerDefaults.shadowOpacityDark
                          : DrawerDefaults.shadowOpacityLight,
                    ),
                    blurRadius: DrawerDefaults.shadowBlur,
                  ),
                ]
              : null,
        ),
        child: Container(
          margin: EdgeInsets.all(_rs.borderWidth),
          decoration: BoxDecoration(
            color: _rs.backgroundGradient == null ? bg : null,
            gradient: _rs.backgroundGradient,
            borderRadius: borderRadius.subtract(
              BorderRadius.all(Radius.circular(_rs.borderWidth)),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(child: content),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _rs.backgroundGradient == null ? bg : null,
        gradient: _rs.backgroundGradient,
        borderRadius: borderRadius,
        border: hasBorder ? _rs.border : null,
        boxShadow: _rs.floating
            ? [
                BoxShadow(
                  color: context.overlayColors.scrim.withValues(
                    alpha: isDark
                        ? DrawerDefaults.shadowOpacityDark
                        : DrawerDefaults.shadowOpacityLight,
                  ),
                  blurRadius: DrawerDefaults.shadowBlur,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(child: content),
    );
  }

  // ─── Section divider ─────────────────────────────────────

  Widget _buildSectionDivider(int sectionIndex) {
    final sectionDivider = widget.sections[sectionIndex].divider;
    if (sectionDivider != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: DrawerDefaults.itemVPad),
        child: sectionDivider,
      );
    }

    if (_rs.sectionDivider != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: DrawerDefaults.itemVPad),
        child: _rs.sectionDivider!,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _rs.dividerIndent),
      child: const GlobalDivider(
        style: DividerStyle(spacing: DrawerDefaults.dividerHeight),
      ),
    );
  }

  // ─── Section title ────────────────────────────────────────

  Widget _buildSectionTitle(String title, ColorScheme cs, [int? itemCount]) {
    final color = _rs.muted(DrawerDefaults.sectionTitleOpacity);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        DrawerDefaults.itemHPad,
        DrawerDefaults.sectionTitlePad,
        DrawerDefaults.itemHPad,
        DrawerDefaults.itemVPad,
      ),
      child: Row(
        children: [
          GlobalText(
            title.toUpperCase(),
            textStyle: GlobalTextStyle(
              fontSize: DrawerDefaults.sectionTitleFontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: color,
            ),
          ),
          if (itemCount != null) ...[
            const SizedBox(width: DrawerDefaults.itemCountGap),
            GlobalText(
              '($itemCount)',
              textStyle: GlobalTextStyle(
                fontSize: DrawerDefaults.itemCountFontSize,
                fontWeight: FontWeight.w600,
                color: _rs.muted(DrawerDefaults.itemCountOpacity),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Item tree (supports children) ────────────────────────

  Widget _buildItemTree(
    DrawerItem item,
    Color primary,
    ColorScheme cs,
    BorderRadius radius,
    int index,
    int depth, {
    void Function(int)? onIndex,
    Color? bg,
  }) {
    onIndex?.call(index + 1);
    Widget itemWidget;

    if (item.hasChildren) {
      itemWidget = _ExpandableItem(
        item: item,
        primary: primary,
        cs: cs,
        radius: radius,
        style: _rs,
        depth: depth,
        onClose: widget.onClose,
        buildChild: (child, childIndex) => _buildItemTree(
          child,
          primary,
          cs,
          radius,
          index + childIndex + 1,
          depth + 1,
          bg: bg,
        ),
      );
    } else if (item.hasSwipeActions) {
      itemWidget = _SwipeableItem(
        style: _rs,
        actions: item.swipeActions!,
        backgroundColor: bg ?? Theme.of(context).scaffoldBackgroundColor,
        child: _buildItem(item, primary, cs, radius, depth),
      );
    } else {
      itemWidget = _buildItem(item, primary, cs, radius, depth);
    }

    if (_entranceCtrl != null && _totalItemCount > 0) {
      final start =
          (index * DrawerDefaults.entranceStaggerFraction / _totalItemCount)
              .clamp(0.0, 1.0);
      final end =
          (start +
                  (1.0 -
                      DrawerDefaults.entranceStaggerFraction *
                          (_totalItemCount - 1) /
                          _totalItemCount))
              .clamp(start, 1.0);
      final animation = CurvedAnimation(
        parent: _entranceCtrl!,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
      return AnimatedBuilder(
        animation: animation,
        builder: (_, child) => Transform.translate(
          offset: Offset(-30 * (1 - animation.value), 0),
          child: Opacity(opacity: animation.value, child: child),
        ),
        child: itemWidget,
      );
    }

    return itemWidget;
  }

  // ─── Single item ──────────────────────────────────────────

  Widget _buildItem(
    DrawerItem item,
    Color primary,
    ColorScheme cs,
    BorderRadius radius,
    int depth,
  ) {
    final selected = item.selected;
    final fg = selected ? primary : _rs.titleColor;
    final indent = depth * DrawerDefaults.childIndent;
    final compact = _rs.compact;
    final vPad = compact
        ? DrawerDefaults.compactVPad
        : DrawerDefaults.itemVPad / 2;
    final itemVPad = compact
        ? DrawerDefaults.compactItemVPad
        : DrawerDefaults.itemVPad * 3;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: indent,
        top: vPad,
        bottom: vPad,
      ),
      child: Semantics(
        container: true,
        button: true,
        selected: selected,
        label: item.semanticLabel ?? item.spokenLabel(),
        excludeSemantics: true,
        child: Material(
          color: selected
              ? primary.withValues(alpha: _rs.selectedBgOpacity)
              : Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () {
              if (_rs.enableHaptic) HapticFeedback.selectionClick();
              widget.onClose?.call();
              item.onTap?.call();
            },
            onLongPress: item.onLongPress == null
                ? null
                : () {
                    if (_rs.enableHaptic) HapticFeedback.mediumImpact();
                    item.onLongPress!.call();
                  },
            child: Padding(
              padding: _rs.itemPadding.add(
                EdgeInsets.symmetric(vertical: itemVPad),
              ),
              child: Row(
                children: [
                  // Avatar takes priority over icon
                  if (item.avatar != null) ...[
                    SizedBox(
                      width: DrawerDefaults.avatarSize,
                      height: DrawerDefaults.avatarSize,
                      child: item.avatar,
                    ),
                    const SizedBox(width: DrawerDefaults.avatarSpacing),
                  ] else if (item.icon != null) ...[
                    Icon(item.icon, size: _rs.iconSize, color: fg),
                    const SizedBox(width: DrawerDefaults.iconSpacing),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlobalText(
                          item.title,
                          textStyle: GlobalTextStyle(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: fg,
                          ),
                        ),
                        if (item.subtitle != null)
                          GlobalText(
                            item.subtitle!,
                            textStyle: GlobalTextStyle(
                              fontSize: DrawerDefaults.subtitleFontSize,
                              color: fg.withValues(
                                alpha: DrawerDefaults.subtitleOpacity,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (item.showDot)
                    _GlobalDrawerState.buildDot(item.dotColor ?? primary),
                  if (item.badge != null)
                    _GlobalDrawerState.buildBadge(item.badge!, primary, _rs),
                  if (item.trailing != null) item.trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Badge + dot ──────────────────────────────────────────
  //
  // `GlobalBadge`, not a private pair of builders. The drawer used to
  // hand-roll both, and had drifted from the other three navigation
  // surfaces on every value — font 10 against 9, radius 10 against 8,
  // padding 8 against 5, dot 8 against 6 — so the same unread count was
  // a different size depending on which surface you were looking at.

  static Widget buildBadge(String text, Color color, ResolvedDrawerStyle rs) =>
      GlobalBadge.standalone(
        label: text,
        style: BadgeStyle(backgroundColor: color),
      );

  static Widget buildDot(Color color) => GlobalBadge.standalone(
    style: BadgeStyle(backgroundColor: color),
  );
}

// ═══════════════════════════════════════════════════════════════
// Swipeable item
// ═══════════════════════════════════════════════════════════════
