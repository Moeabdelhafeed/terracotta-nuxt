import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/a11y/semantics_extensions.dart';
import '../buttons/global_icon_button.dart';
import '../image/global_image.dart';
import '../text/global_text.dart';
import 'app_bar_models.dart';
import 'theme/app_bar_theme.dart';

/// A customizable sliver app bar for use in CustomScrollView/NestedScrollView.
class GlobalSliverAppBar extends StatelessWidget {
  // ─── Fields ────────────────────────────────────────────────
  final String? title;
  final String? expandedTitle;
  final Widget? expandedTitleWidget;
  final Widget? titleWidget;
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? background;
  final Widget? flexibleSpace;
  final AppBarStyle style;
  final double expandedHeight;
  final double? collapsedHeight;
  final bool floating;
  final bool pinned;
  final bool snap;
  final bool stretch;
  final CollapseMode collapseMode;
  final StretchMode stretchMode;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const GlobalSliverAppBar({
    super.key,
    this.title,
    this.expandedTitle,
    this.expandedTitleWidget,
    this.titleWidget,
    this.leading,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.bottom,
    this.background,
    this.flexibleSpace,
    this.style = const AppBarStyle(),
    this.expandedHeight = AppBarDefaults.defaultExpandedHeight,
    this.collapsedHeight,
    this.floating = false,
    this.pinned = true,
    this.snap = false,
    this.stretch = false,
    this.collapseMode = CollapseMode.parallax,
    this.stretchMode = StretchMode.zoomBackground,
    this.systemOverlayStyle,
  });

  // ─── Factories ─────────────────────────────────────────────

  factory GlobalSliverAppBar.simple(
    String title, {
    Key? key,
    double expandedHeight = AppBarDefaults.defaultExpandedHeight,
    bool pinned = true,
    bool floating = false,
    bool stretch = false,
  }) => GlobalSliverAppBar(
    key: key,
    expandedTitle: title,
    expandedHeight: expandedHeight,
    pinned: pinned,
    floating: floating,
    stretch: stretch,
  );

  factory GlobalSliverAppBar.gradient(
    String title, {
    Key? key,
    required Gradient gradient,
    double expandedHeight = 220,
    List<Widget>? actions,
    bool pinned = true,
    bool stretch = false,
  }) => GlobalSliverAppBar(
    key: key,
    expandedTitle: title,
    expandedHeight: expandedHeight,
    actions: actions,
    pinned: pinned,
    stretch: stretch,
    background: Container(decoration: BoxDecoration(gradient: gradient)),
    style: const AppBarStyle(foregroundColor: Colors.white),
  );

  factory GlobalSliverAppBar.image(
    String title, {
    Key? key,
    required ImageProvider image,
    double expandedHeight = 250,
    List<Widget>? actions,
    BoxFit fit = BoxFit.cover,
    bool pinned = true,
    bool stretch = false,
  }) => GlobalSliverAppBar(
    key: key,
    expandedTitle: title,
    expandedHeight: expandedHeight,
    actions: actions,
    pinned: pinned,
    stretch: stretch,
    background: GlobalImage.p(
      image,
      width: double.infinity,
      height: double.infinity,
      style: ImageStyle(fit: fit),
    ),
    style: const AppBarStyle(foregroundColor: Colors.white),
  );

  factory GlobalSliverAppBar.custom(
    String title, {
    Key? key,
    required Widget background,
    double expandedHeight = AppBarDefaults.defaultExpandedHeight,
    List<Widget>? actions,
    AppBarStyle style = const AppBarStyle(),
    bool pinned = true,
    bool stretch = false,
  }) => GlobalSliverAppBar(
    key: key,
    expandedTitle: title,
    expandedHeight: expandedHeight,
    background: background,
    actions: actions,
    style: style,
    pinned: pinned,
    stretch: stretch,
  );

  // ─── Build ─────────────────────────────────────────────────

  @override
  SliverAppBar build(BuildContext context) {
    // Resolved with the STANDARD variant even when a custom background
    // is present: a sliver bar's background is a widget (`background:`),
    // not the gradient field, so the variant's transparent/white
    // treatment would be wrong here. The light-foreground case is
    // handled below instead.
    final rs = style.resolve(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = rs.foregroundColor;

    // A light foreground means the header art is carrying the contrast.
    // Once collapsed that art is gone, so the page surface would leave a
    // white title on white — hence the dark collapsed background.
    final hasCustomBg = background != null || rs.gradient != null;
    final isLightFg =
        fg.computeLuminance() > AppBarDefaults.lightForegroundThreshold;
    final bg =
        style.backgroundColor ??
        (hasCustomBg && isLightFg
            ? AppBarDefaults.darkCollapsedBackground
            : rs.backgroundColor);
    final hasExpandedTitle =
        expandedTitle != null || expandedTitleWidget != null;

    return SliverAppBar(
      // The toolbar title is only shown when nothing expands into the
      // flexible space — otherwise the two would stack.
      title: !hasExpandedTitle ? _buildToolbarTitle(rs) : null,
      centerTitle: rs.centerTitle,
      leading: _resolveLeading(context, rs),
      automaticallyImplyLeading: false,
      actions: actions,
      actionsPadding: const EdgeInsetsDirectional.only(
        end: AppBarDefaults.actionEndPad,
      ),
      titleSpacing: 0,
      elevation: rs.elevation,
      backgroundColor: bg,
      foregroundColor: fg,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: rs.toolbarHeight ?? kToolbarHeight,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      floating: floating,
      pinned: pinned,
      snap: snap,
      stretch: stretch,
      bottom: bottom,
      flexibleSpace: flexibleSpace ?? _buildFlexibleSpaceBar(rs),
      systemOverlayStyle:
          systemOverlayStyle ??
          (isDark || isLightFg
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────

  Widget? _buildToolbarTitle(ResolvedAppBarStyle rs) {
    if (titleWidget != null) return titleWidget;
    final text = title ?? expandedTitle;
    if (text == null) return null;
    return GlobalText(
      text,
      textStyle: GlobalTextStyle(
        fontWeight: rs.titleStyle?.fontWeight ?? FontWeight.w700,
        color: rs.titleStyle?.color ?? rs.foregroundColor,
        fontSize: rs.titleStyle?.fontSize,
      ),
    ).asHeader();
  }

  Widget? _resolveLeading(BuildContext context, ResolvedAppBarStyle rs) {
    if (leading != null) return leading;
    if (!showBack || !Navigator.of(context).canPop()) return null;
    return UnconstrainedBox(
      child: GlobalIconButton(
        iconData: Icons.arrow_back_ios_rounded,
        onPressed: onBack ?? () => Navigator.of(context).pop(),
        // See GlobalAppBar: a bare chevron announces as "button" only.
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        iconSize: rs.backIconSize,
        style: ButtonStateStyle(
          foregroundColor: rs.foregroundColor,
          // Sized to the touch target by default, so the painted box is
          // not centred inside a larger hit box and pushed away from the
          // bar's edge — see AppBarDefaults.backButtonSize.
          width: rs.backButtonSize,
          borderRadius: BorderRadius.circular(AppBarDefaults.backButtonRadius),
        ),
      ),
    );
  }

  FlexibleSpaceBar _buildFlexibleSpaceBar(ResolvedAppBarStyle rs) {
    final hasExpandedTitle =
        expandedTitle != null || expandedTitleWidget != null;
    final titleStyle = TextStyle(
      fontSize: rs.titleStyle?.fontSize ?? AppBarDefaults.expandedTitleFontSize,
      fontWeight: rs.titleStyle?.fontWeight ?? FontWeight.w700,
      color: rs.titleStyle?.color ?? rs.foregroundColor,
    );
    final bottomHeight = bottom?.preferredSize.height ?? 0;

    Widget? flexTitle;
    if (hasExpandedTitle) {
      flexTitle =
          expandedTitleWidget ?? Text(expandedTitle!, style: titleStyle);
    } else if (title != null) {
      flexTitle = Text(title!, style: titleStyle);
    }

    return FlexibleSpaceBar(
      title: flexTitle,
      centerTitle: rs.centerTitle,
      // With a bottom widget the title has to sit above it, or the two
      // overlap once collapsed.
      titlePadding: bottomHeight > 0
          ? EdgeInsetsDirectional.only(
              start: rs.centerTitle ? 0 : AppBarDefaults.titleStartPad,
              bottom: bottomHeight + AppBarDefaults.titleBottomPad,
            )
          : null,
      background: background,
      collapseMode: collapseMode,
      stretchModes: [stretchMode],
    );
  }
}
