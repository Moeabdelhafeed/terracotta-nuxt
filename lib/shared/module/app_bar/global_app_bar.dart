import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/a11y/semantics_extensions.dart';
import '../../../core/animations/entrance.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/field_strings.dart';
import '../buttons/global_icon_button.dart';
import '../text/global_text.dart';
import '../text_field/global_text_field.dart';
import 'app_bar_models.dart';
import 'theme/app_bar_theme.dart';

export '../../../core/animations/entrance.dart' show EntranceKind;
export 'app_bar_models.dart';
export 'theme/app_bar_theme.dart';

/// A highly customizable app bar with support for gradient backgrounds,
/// search mode, subtitle, leading/trailing widgets, dynamic height,
/// and transparent overlay style.
class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  // ─── Fields ────────────────────────────────────────────────
  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final IconData? icon;
  final Widget? leading;
  final bool showBack;

  /// Wraps the BACK affordance this bar builds for itself.
  ///
  /// The one thing a caller cannot do with `leading:`: take the bar's
  /// own back button — its icon, its tooltip, its `_canPop` decision,
  /// its styling — and put something around it. Handing `leading:` a
  /// replacement means rebuilding all of that, and then owning it.
  ///
  /// Terracotta uses it to fly the chevron between pages, so the one
  /// control that is in the same place on every pushed screen holds
  /// still while the page travels under it. Not applied to the drawer
  /// button or to an explicit `leading`: those are different controls,
  /// and a shared element has to be the same thing at both ends.
  final Widget Function(Widget back)? wrapBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? flexibleSpace;
  final AppBarVariant variant;
  final AppBarStyle style;
  final bool searchMode;

  /// Replaces the built-in search field while [searchMode] is on —
  /// `titleWidget` for search.
  ///
  /// The built-in field is deliberately bare: `app_bar` is a PRIMITIVE
  /// module and may not import `shared/common/`, so debounce, recents,
  /// suggestions and scopes cannot live here. Pass `SearchTextField`
  /// through this slot for those, or use `SearchAppBar`
  /// (`shared/common/app_bars/`), which does exactly that.
  final Widget? searchField;

  final TextEditingController? searchController;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const GlobalAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.icon,
    this.leading,
    this.showBack = true,
    this.wrapBack,
    this.onBack,
    this.actions,
    this.bottom,
    this.flexibleSpace,
    this.variant = AppBarVariant.standard,
    this.style = const AppBarStyle(),
    this.searchMode = false,
    this.searchField,
    this.searchController,
    this.searchHint,
    this.onSearchChanged,
    this.onSearchClear,
    this.systemOverlayStyle,
  });

  /// Reported to the Scaffold WITHOUT a context, so only the caller's
  /// own `toolbarHeight` can be honoured here — see
  /// [AppBarStyle.toolbarHeight].
  @override
  Size get preferredSize => Size.fromHeight(
    style.preferredToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  // ─── Convenience factories ─────────────────────────────────

  factory GlobalAppBar.simple(
    String title, {
    Key? key,
    bool centerTitle = true,
    List<Widget>? actions,
  }) => GlobalAppBar(
    key: key,
    title: title,
    style: AppBarStyle(centerTitle: centerTitle),
    actions: actions,
  );

  factory GlobalAppBar.transparent(
    String title, {
    Key? key,
    Color foregroundColor = Colors.white,
    List<Widget>? actions,
  }) => GlobalAppBar(
    key: key,
    title: title,
    variant: AppBarVariant.transparent,
    style: AppBarStyle(foregroundColor: foregroundColor, centerTitle: true),
    actions: actions,
  );

  factory GlobalAppBar.gradient(
    String title, {
    Key? key,
    required Gradient gradient,
    Color foregroundColor = Colors.white,
    List<Widget>? actions,
  }) => GlobalAppBar(
    key: key,
    title: title,
    variant: AppBarVariant.gradient,
    style: AppBarStyle(
      gradient: gradient,
      foregroundColor: foregroundColor,
      centerTitle: true,
    ),
    actions: actions,
  );

  factory GlobalAppBar.search({
    Key? key,
    TextEditingController? controller,
    String? hint,
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
    List<Widget>? actions,
    Widget? field,
  }) => GlobalAppBar(
    key: key,
    searchMode: true,
    searchField: field,
    searchController: controller,
    searchHint: hint,
    onSearchChanged: onChanged,
    onSearchClear: onClear,
    actions: actions,
    showBack: true,
  );

  factory GlobalAppBar.withSubtitle(
    String title,
    String subtitle, {
    Key? key,
    IconData? icon,
    List<Widget>? actions,
  }) => GlobalAppBar(
    key: key,
    title: title,
    subtitle: subtitle,
    icon: icon,
    actions: actions,
    style: const AppBarStyle(centerTitle: false),
  );

  /// Wraps this app bar in a [HideOnScrollAppBar]: it slides away as the
  /// page scrolls down and returns the instant it scrolls up.
  ///
  /// [controller] is only needed outside a [Scaffold] — see
  /// [HideOnScrollAppBar].
  HideOnScrollAppBar hideOnScroll({ScrollController? controller}) =>
      HideOnScrollAppBar(appBar: this, scrollController: controller);

  /// Wraps the bar in an ARRIVAL, played when its page opens and
  /// backwards when the page leaves.
  ///
  /// Off unless asked for: a bar that animates in on every route change
  /// is a bar that is late on every route change. Same
  /// [EntranceKind] the bottom nav uses, so the two ends of a screen
  /// can be told to arrive together.
  EntranceAppBar entrance(
    EntranceKind kind, {
    Duration? duration,
    Curve? curve,
    bool reverseOnExit = true,
  }) => EntranceAppBar(
    appBar: this,
    kind: kind,
    duration: duration,
    curve: curve,
    reverseOnExit: reverseOnExit,
  );

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Materialized ONCE per build: every helper below reads `rs` rather
    // than re-deriving `style.x ?? cs.y` at each use, so there is one
    // place where a value can be wrong.
    final rs = style.resolve(context, variant: variant);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleContent = _resolveTitleContent(context, rs);
    final leadingWidget = _resolveLeading(context, rs);
    final drawerAction = _drawerAction(context, rs);
    final barActions = drawerAction == null
        ? actions
        : [...?actions, drawerAction];
    final hasActions = barActions != null && barActions.isNotEmpty;
    final hasLeading = leadingWidget != null;
    // A centred title is centred in the band BETWEEN leading and
    // actions. With a back button and nothing on the other side that
    // band starts 56dp in, so the title lands right of the bar's real
    // centre. Reserve the same width at the end.
    final needsBalance =
        rs.balanceCenteredTitle && rs.centerTitle && hasLeading && !hasActions;
    final effectiveActions = needsBalance
        ? const [SizedBox(width: AppBarDefaults.leadingSlotWidth)]
        : barActions;

    if (rs.dynamicHeight) {
      return _buildDynamicHeight(context, rs, titleContent, leadingWidget);
    }

    Widget appBar = AppBar(
      title: _wrapTitle(rs, titleContent, hasActions, hasLeading),
      centerTitle: rs.centerTitle,
      leading: leadingWidget,
      automaticallyImplyLeading: false,
      actions: effectiveActions,
      actionsPadding: needsBalance
          ? EdgeInsets.zero
          : const EdgeInsetsDirectional.only(
              end: AppBarDefaults.actionEndPad,
            ),
      titleSpacing: 0,
      bottom: bottom,
      elevation: rs.elevation,
      shadowColor: rs.shadowColor,
      // An opaque AppBar would paint OVER the flexibleSpace that carries
      // the gradient / rounded / gradient-stroked background.
      backgroundColor: rs.paintsOwnBackground
          ? Colors.transparent
          : rs.backgroundColor,
      foregroundColor: rs.foregroundColor,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: rs.toolbarHeight,
      flexibleSpace: flexibleSpace ?? _buildFlexibleBackground(rs),
      systemOverlayStyle: systemOverlayStyle ?? _resolveOverlayStyle(isDark),
      shape: null,
    );

    if (rs.borderRadius != null) {
      appBar = ClipRRect(borderRadius: rs.borderRadius!, child: appBar);
    }

    // RETREAT as the page is read — by DEFAULT on a short window.
    //
    // A landscape phone is 402 points tall and the bar takes 56 of
    // them, fourteen per cent of the axis there is none of. `resolve`
    // turns `style.hideOnScroll: null` into "the window is short", so
    // this is on for a rotated phone and off for a tablet, a desktop and
    // every portrait screen. `hideOnScroll: false` pins it off.
    //
    // The height never changes — see `_HideOnScroll`, which translates.
    // So `preferredSize` stays honest and the `Scaffold` is not being
    // told one number while another is laid out.
    if (rs.hideOnScroll && !_HideOnScrollScope.isActive(context)) {
      appBar = _HideOnScroll(
        preferredHeight: preferredSize.height,
        child: appBar,
      );
    }

    return appBar;
  }

  // ─── Resolvers ─────────────────────────────────────────────

  SystemUiOverlayStyle _resolveOverlayStyle(bool isDark) {
    return (variant == AppBarVariant.transparent ||
            variant == AppBarVariant.gradient)
        ? SystemUiOverlayStyle.light
        : isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
  }

  Widget? _resolveTitleContent(BuildContext context, ResolvedAppBarStyle rs) {
    if (searchMode) return _buildSearchField(context);
    if (titleWidget != null) return titleWidget;
    if (title != null) return _buildTitle(rs);
    return null;
  }

  /// What sits in the leading slot: an explicit widget, a drawer button,
  /// a back button, or nothing.
  ///
  /// This bar passes `automaticallyImplyLeading: false` — it has to,
  /// since it builds its own back affordance — which also turned off
  /// Material's automatic hamburger, leaving a `Scaffold` with a drawer
  /// no way to open it but a swipe from the screen edge.
  ///
  /// Material's answer is to prefer the drawer, because it assumes a
  /// drawer lives at the ROOT of a stack. On a PUSHED route that reads
  /// as "no way back", which is the worse failure of the two — so back
  /// keeps the leading slot whenever there is somewhere to go, and the
  /// drawer moves to the trailing side rather than being dropped. See
  /// [_drawerAction].
  ///
  /// Only the LEADING side needed any of this. `automaticallyImplyLeading`
  /// does not govern the trailing one, so Material still adds its own
  /// END-drawer button whenever `actions` is empty.
  Widget? _resolveLeading(BuildContext context, ResolvedAppBarStyle rs) {
    if (leading != null) return leading;

    final canPop = showBack && _canPop(context);
    if (!canPop && _hasDrawer(context)) {
      return _barButton(
        context,
        rs,
        icon: Icons.menu_rounded,
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        onPressed: Scaffold.of(context).openDrawer,
      );
    }

    if (!canPop) return null;
    final back = _barButton(
      context,
      rs,
      icon: Icons.arrow_back_ios_rounded,
      // A chevron with no accessible name is announced as "button" and
      // nothing else. Flutter already translates this string for every
      // supported locale, so there is nothing to add to the ARB.
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onBack ?? () => _pop(context),
    );
    return wrapBack?.call(back) ?? back;
  }

  static bool _hasDrawer(BuildContext context) =>
      Scaffold.maybeOf(context)?.hasDrawer ?? false;

  /// Whether there is anything to go back TO.
  ///
  /// Asks the ROUTER first. `Navigator.canPop` answers for the
  /// navigator's own page list, which under GoRouter is rebuilt from a
  /// match list the navigator does not own — and the two disagree, most
  /// visibly right after a `go()` replaces the stack. The bar drew a
  /// back button on a single-page stack, and pressing it tripped
  /// GoRouter's `currentConfiguration.isNotEmpty` assertion and left
  /// the app with no page at all.
  ///
  /// Falls back to the navigator where there is no router above — this
  /// bar is also mounted in tests and on the pre-router error page.
  static bool _canPop(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) return router.canPop();
    return Navigator.of(context).canPop();
  }

  /// Pops through whichever of the two owns the stack.
  ///
  /// Re-checks before popping rather than trusting the flag build time
  /// computed: a tap arrives a frame or more later, and by then the
  /// route may already be going.
  static void _pop(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      if (router.canPop()) router.pop();
      return;
    }
    final navigator = Navigator.maybeOf(context);
    if (navigator?.canPop() ?? false) navigator!.pop();
  }

  /// The drawer's affordance when the back button has taken the leading
  /// slot, appended AFTER the caller's own actions.
  ///
  /// Appended rather than skipped when actions exist: a crowded bar is a
  /// smaller problem than a drawer with no button, and the caller can
  /// still take the slot outright with `leading:`.
  Widget? _drawerAction(BuildContext context, ResolvedAppBarStyle rs) {
    if (leading != null) return null;
    if (!_hasDrawer(context)) return null;
    if (!(showBack && _canPop(context))) return null;
    return _barButton(
      context,
      rs,
      icon: Icons.menu_rounded,
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      onPressed: Scaffold.of(context).openDrawer,
    );
  }

  Widget _barButton(
    BuildContext context,
    ResolvedAppBarStyle rs, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Align(
      // START, not centred. Material centres the leading widget in its
      // slot; pinning it puts the button exactly `leadingStartPad` in,
      // which is where an action sits at the other end.
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: AppBarDefaults.leadingStartPad,
        ),
        child: GlobalIconButton(
          iconData: icon,
          onPressed: onPressed,
          tooltip: tooltip,
          iconSize: rs.backIconSize,
          style: ButtonStateStyle(
            foregroundColor: rs.foregroundColor,
            backgroundColor: rs.buttonBackgroundColor,
            // Sized to the touch target by default, so the painted box
            // is not centred inside a larger hit box and pushed away
            // from the bar's edge — see AppBarDefaults.backButtonSize.
            width: rs.backButtonSize,
            borderRadius: BorderRadius.circular(
              AppBarDefaults.backButtonRadius,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Title builders ────────────────────────────────────────

  Widget _wrapTitle(
    ResolvedAppBarStyle rs,
    Widget? content,
    bool hasActions,
    bool hasLeading,
  ) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        // `titleSpacing: 0` strips Material's own 16dp middle spacing so
        // a title that FOLLOWS a leading widget sits tight against it.
        // With no leading there is nothing to sit against, and a
        // start-aligned title would touch the bar's edge — so put the
        // inset back, aligned with where an action's glyph lands.
        start: hasLeading || rs.centerTitle ? 0 : AppBarDefaults.titleStartPad,
        // Search mode gets none: the field spans the bar, and any end
        // pad pushes its clear button inward from the edge that the
        // action icons sit against.
        end: hasActions || !rs.centerTitle || searchMode
            ? 0
            : AppBarDefaults.titlePadCenter,
      ),
      child: content,
    );
  }

  Widget _buildTitle(ResolvedAppBarStyle rs) {
    final fg = rs.foregroundColor;
    final titleText = _titleText(
      rs,
      title!,
      GlobalTextStyle(
        // A caller/theme title style contributes its own fields; the
        // colour falls back to the resolved foreground so a partial
        // override (weight only, say) cannot make the title invisible.
        fontWeight: rs.titleStyle?.fontWeight ?? FontWeight.w700,
        color: rs.titleStyle?.color ?? fg,
        fontSize: rs.titleStyle?.fontSize,
      ),
    );

    // The title names the page, so it is the landmark assistive tech
    // jumps to. Only the TITLE is a header — the subtitle is detail,
    // and two headers in one bar make the landmark useless.
    if (subtitle == null && icon == null) return titleText.asHeader();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppBarDefaults.iconSize, color: fg),
          const SizedBox(width: AppBarDefaults.iconSpacing),
        ],
        Flexible(
          child: subtitle != null
              ? Column(
                  crossAxisAlignment: rs.centerTitle
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    titleText.asHeader(),
                    _titleText(
                      rs,
                      subtitle!,
                      GlobalTextStyle(
                        fontSize:
                            rs.subtitleStyle?.fontSize ??
                            AppBarDefaults.subtitleFontSize,
                        color:
                            rs.subtitleStyle?.color ??
                            fg.withValues(
                              alpha: AppBarDefaults.subtitleOpacity,
                            ),
                        fontWeight: rs.subtitleStyle?.fontWeight,
                      ),
                    ),
                  ],
                )
              : titleText.asHeader(),
        ),
      ],
    );
  }

  /// A title or subtitle that scrolls rather than truncating.
  ///
  /// An app bar carries exactly ONE title and it names the page, so an
  /// ellipsis there is unreadable with no way to reveal the rest — the
  /// same argument that made button labels marquee. The marquee gates
  /// itself on real overflow and degrades to truncation under reduced
  /// motion, so a short title is unaffected.
  Widget _titleText(
    ResolvedAppBarStyle rs,
    String text,
    GlobalTextStyle style,
  ) {
    if (rs.titleOverflow == LabelOverflow.ellipsis) {
      return GlobalText(text, textStyle: style);
    }
    return GlobalText(
      text,
      textStyle: style,
      marquee: (rs.marqueeTitle ?? const MarqueeStyle()).copyWith(
        // Pause recognizers would compete with the bar's own gestures.
        pauseOnHover: false,
        pauseOnTouch: false,
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      // Zero on the trailing side so the clear button's TOUCH BOX ends
      // flush with the bar, putting its glyph where an action icon's
      // glyph sits. The box itself stays 40dp — the gap the user sees
      // is a tap target, and shrinking it would trade a11y for looks.
      padding: EdgeInsets.zero,
      child:
          searchField ??
          _AppBarSearchField(
            controller: searchController,
            hint: searchHint ?? FieldStrings.searchHint,
            onChanged: onSearchChanged,
            onClear: onSearchClear,
          ),
    );
  }

  // ─── Background builder ────────────────────────────────────

  Widget? _buildFlexibleBackground(ResolvedAppBarStyle rs) {
    final hasGradient =
        variant == AppBarVariant.gradient && rs.gradient != null;
    final hasRadius = rs.borderRadius != null;
    final hasBorderGradient = rs.borderGradient != null;
    final hasBorder = rs.border != null;

    if (!hasGradient && !hasRadius && !hasBorderGradient && !hasBorder) {
      return null;
    }

    if (hasBorderGradient) {
      // BoxDecoration cannot STROKE a gradient, so the stroke is an
      // outer box and the fill is an inset one.
      return Container(
        decoration: BoxDecoration(
          gradient: rs.borderGradient,
          borderRadius: rs.borderRadius,
        ),
        child: Container(
          margin: EdgeInsets.all(rs.borderWidth),
          decoration: BoxDecoration(
            color: hasGradient ? null : rs.backgroundColor,
            gradient: hasGradient ? rs.gradient : null,
            borderRadius: rs.borderRadius?.subtract(
              BorderRadius.all(Radius.circular(rs.borderWidth)),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: hasGradient ? null : (hasRadius ? rs.backgroundColor : null),
        gradient: hasGradient ? rs.gradient : null,
        borderRadius: rs.borderRadius,
        border: rs.border,
      ),
    );
  }

  // ─── Dynamic height ────────────────────────────────────────

  Widget _buildDynamicHeight(
    BuildContext context,
    ResolvedAppBarStyle rs,
    Widget? titleContent,
    Widget? leadingWidget,
  ) {
    final safePad = MediaQuery.of(context).padding;
    return Container(
      decoration: BoxDecoration(
        color: rs.gradient != null ? null : rs.backgroundColor,
        gradient: rs.gradient,
        borderRadius: rs.borderRadius,
        border: rs.border,
        // This layout replaces Material's AppBar, so it has to paint its
        // own shadow rather than pass an elevation to one.
        boxShadow: rs.elevation > 0
            ? [
                BoxShadow(
                  color: rs.shadowColor ?? context.overlayColors.scrim,
                  blurRadius:
                      rs.elevation * AppBarDefaults.dynamicShadowBlurFactor,
                ),
              ]
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppBarDefaults.dynamicHPad,
            safePad.top > 0 ? 0 : AppBarDefaults.dynamicTopPadNoSafeArea,
            AppBarDefaults.dynamicHPad,
            AppBarDefaults.dynamicVPad,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: rs.centerTitle
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ?leadingWidget,
                  if (leadingWidget != null)
                    const SizedBox(width: AppBarDefaults.leadingGap),
                  Expanded(child: titleContent ?? const SizedBox.shrink()),
                  if (actions != null) ...actions!,
                ],
              ),
              ?bottom,
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Search field (owns a fallback controller when the caller passes none)
// ═══════════════════════════════════════════════════════════════

/// The search field rendered by [GlobalAppBar]'s search mode.
///
/// Owns a fallback [TextEditingController] when [controller] is null —
/// the previous inline `TextEditingController()` was recreated on every
/// build and never disposed.
class _AppBarSearchField extends StatefulWidget {
  const _AppBarSearchField({
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onClear,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  State<_AppBarSearchField> createState() => _AppBarSearchFieldState();
}

class _AppBarSearchFieldState extends State<_AppBarSearchField> {
  TextEditingController? _fallback;

  TextEditingController get _effectiveController =>
      widget.controller ?? (_fallback ??= TextEditingController());

  @override
  void dispose() {
    _fallback?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalTextFormField(
      controller: _effectiveController,
      hint: widget.hint,
      // The field IS the bar's content, so it must not paint a second
      // surface on top of the bar or box the text while it is being
      // typed. `focused` is zeroed BY NAME because the defaults and the
      // app-wide theme both set it, and a state-specific side always
      // overlays `base`.
      style: const TextFieldStyle(
        fillColor: Colors.transparent,
        border: TextFieldBorderStyle(
          base: TextFieldBorderSide(color: Colors.transparent, width: 0),
          focused: TextFieldBorderSide(color: Colors.transparent, width: 0),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: AppBarDefaults.searchFieldPadding,
        ),
      ),
      behavior: const TextFieldBehavior(
        textInputAction: TextInputAction.search,
      ),
      features: TextFieldFeatures(
        showClearButton: true,
        onClear: widget.onClear,
      ),
      callbacks: TextFieldCallbacks(onChanged: widget.onChanged),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Hide-on-scroll wrapper for any PreferredSizeWidget
// ═══════════════════════════════════════════════════════════════

/// Wraps a [PreferredSizeWidget] and slides it away as the page scrolls
/// DOWN, bringing it back the moment the page scrolls UP.
///
/// ## Scrubbed, not triggered
///
/// The bar's offset tracks the scroll delta one-to-one: a slow drag
/// moves it slowly, a flick takes it away at once. It is the content's
/// own gesture continued, not an animation the gesture happens to
/// start — which is why there is no "how fast should it hide" knob.
/// Letting go settles it to whichever edge is nearer, so the bar is
/// never left half-drawn.
///
/// ## Nothing to wire
///
/// [scrollController] is optional. Inside a [Scaffold] — where an app
/// bar lives — Flutter already mounts a `ScrollNotificationObserver`
/// above both the body and the bar, which is the same channel Material's
/// own `AppBar` uses for its scrolled-under elevation. Listening there
/// means the body's scrolling reaches the bar with no controller passed
/// through the page, and it keeps working when the scrollable is
/// replaced or nested.
///
/// Pass a controller only OUTSIDE a Scaffold, where that observer does
/// not exist.
///
/// **The Scaffold needs `extendBodyBehindAppBar: true`.** A
/// `PreferredSizeWidget`'s size is read once per layout and cannot
/// animate: a bar that shrank its own height would relayout the body on
/// every frame, and the body would move at twice the scroll rate — the
/// exact artefact that made this look like the bar was lagging. So the
/// bar TRANSLATES out of a box that keeps its height, and the body has
/// to be behind it, or the space it vacates simply sits there empty.
///
/// ```dart
/// Scaffold(
///   extendBodyBehindAppBar: true,
///   appBar: GlobalAppBar.simple('Title').hideOnScroll(),
///   body: ListView(...),
/// )
/// ```
class HideOnScrollAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const HideOnScrollAppBar({
    required this.appBar,
    super.key,
    this.scrollController,
  });

  /// The app bar to wrap.
  final PreferredSizeWidget appBar;

  /// Only needed outside a [Scaffold]; otherwise the ambient
  /// `ScrollNotificationObserver` supplies the scrolling.
  final ScrollController? scrollController;

  @override
  Size get preferredSize => appBar.preferredSize;

  @override
  Widget build(BuildContext context) => _HideOnScroll(
    preferredHeight: appBar.preferredSize.height,
    scrollController: scrollController,
    // The bar inside would otherwise hide ITSELF as well, on a window
    // short enough for the automatic case — two translations of the
    // same height, so the bar leaves at twice the scroll rate.
    child: _HideOnScrollScope(child: appBar),
  );
}

/// Marks that something ABOVE is already doing the hiding.
class _HideOnScrollScope extends InheritedWidget {
  const _HideOnScrollScope({required super.child});

  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HideOnScrollScope>() != null;

  @override
  bool updateShouldNotify(_HideOnScrollScope oldWidget) => false;
}

/// The retreat itself, over any child.
///
/// Split out of [HideOnScrollAppBar] because [GlobalAppBar] now does
/// this by DEFAULT in a short window, and two copies of a scroll-driven
/// controller is two places for the settle to be wrong.
class _HideOnScroll extends StatefulWidget {
  const _HideOnScroll({
    required this.preferredHeight,
    required this.child,
    this.scrollController,
  });

  /// What the bar reports to the `Scaffold`. The height it OCCUPIES is
  /// this plus the status-bar inset — see `_barHeight`.
  final double preferredHeight;

  final ScrollController? scrollController;
  final Widget child;

  @override
  State<_HideOnScroll> createState() => _HideOnScrollState();
}

class _HideOnScrollState extends State<_HideOnScroll>
    with SingleTickerProviderStateMixin {
  /// 1 = fully shown, 0 = fully hidden. Driven directly by scroll delta
  /// rather than by `forward()` / `reverse()`.
  late AnimationController _ctrl;
  ScrollNotificationObserverState? _observer;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppBarDefaults.hideOnScrollDuration,
      value: 1,
    );
    widget.scrollController?.addListener(_onControllerScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _topInset = MediaQuery.paddingOf(context).top;
    // Only the SETTLE is animated; the scrub is the user's own gesture
    // and is never something `disableAnimations` should freeze.
    _ctrl.duration = _reduceMotion
        ? Duration.zero
        : AppBarDefaults.hideOnScrollDuration;

    if (widget.scrollController != null) return;
    final observer = ScrollNotificationObserver.maybeOf(context);
    if (observer == _observer) return;
    _observer?.removeListener(_onNotification);
    _observer = observer?..addListener(_onNotification);
  }

  @override
  void didUpdateWidget(_HideOnScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onControllerScroll);
      widget.scrollController?.addListener(_onControllerScroll);
    }
  }

  @override
  void dispose() {
    _observer?.removeListener(_onNotification);
    widget.scrollController?.removeListener(_onControllerScroll);
    _ctrl.dispose();
    super.dispose();
  }

  /// The height the bar actually OCCUPIES, which is not its
  /// `preferredSize`: `Scaffold` renders an app bar at
  /// `preferredSize.height + MediaQuery.padding.top`, and the bar draws
  /// its toolbar below that inset. Normalising the scrub against the
  /// smaller number would retreat slower than the finger by exactly the
  /// status bar, and translating by it would leave the notch strip
  /// behind on screen.
  double get _barHeight => widget.preferredHeight + _topInset;

  double _topInset = 0;

  // ─── Input ─────────────────────────────────────────────────

  void _onNotification(ScrollNotification notification) {
    // depth 0 only: an inner horizontal carousel or a nested list must
    // not drive the page's own chrome.
    if (notification.depth != 0) return;
    if (notification.metrics.axis != Axis.vertical) return;

    // A page that cannot afford to lose the bar keeps it. See
    // `_canHide`.
    if (!_canHide(notification.metrics)) {
      if (_ctrl.value != 1) _ctrl.forward();
      return;
    }

    if (notification is ScrollUpdateNotification) {
      _applyDelta(notification.scrollDelta ?? 0, notification.metrics.pixels);
    } else if (notification is ScrollEndNotification) {
      _settle();
    }
  }

  double _lastOffset = 0;

  /// Whether there is enough content that hiding the bar does not
  /// strand the reader.
  ///
  /// Hiding frees the bar's own height. On a page with barely more
  /// content than fits, that is enough to make the page unscrollable —
  /// so the bar hides, the scroll ends, and no gesture remains that
  /// could bring it back. Requiring the content to be able to lose the
  /// bar's height and still scroll is the whole guard.
  bool _canHide(ScrollMetrics metrics) {
    if (!metrics.hasContentDimensions) return false;
    return metrics.maxScrollExtent >=
        _barHeight * AppBarDefaults.hideMinExtentFactor;
  }

  void _onControllerScroll() {
    final controller = widget.scrollController!;
    final offset = controller.offset;
    if (controller.hasClients && !_canHide(controller.position)) {
      _lastOffset = offset;
      if (_ctrl.value != 1) _ctrl.forward();
      return;
    }
    _applyDelta(offset - _lastOffset, offset);
    _lastOffset = offset;
  }

  /// Positive [delta] means the content moved UP — the reader is going
  /// down the page — so the bar retreats by the same amount.
  void _applyDelta(double delta, double pixels) {
    if (_barHeight <= 0) return;
    // Pinned open at the very top, including while a bounce overscroll
    // carries pixels negative: a bar hidden above the first item has
    // nothing to reveal.
    if (pixels <= 0) {
      _ctrl.value = 1;
      return;
    }
    _ctrl.value = (_ctrl.value - delta / _barHeight).clamp(0.0, 1.0);
  }

  /// Finish to whichever edge is nearer, so the bar is never abandoned
  /// part-way out.
  void _settle() {
    if (_ctrl.value <= 0 || _ctrl.value >= 1) return;
    if (_ctrl.value >= 0.5) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => ClipRect(
        // TRANSLATE, and keep the laid-out height CONSTANT.
        //
        // It used to shrink by `heightFactor`, and `Scaffold` hands the
        // app bar's rendered height to the body as MediaQuery top
        // padding — so every pixel the bar collapsed also pulled the
        // body up a pixel, on top of the scroll. Content moved at twice
        // the scroll rate for as long as the bar was retreating, which
        // reads as the bar lagging behind the page. The bar was 1:1
        // with the finger either way; it was the BODY that was fast.
        //
        // A FRACTION of the child's own height, not a pixel count off
        // `preferredSize`: the rendered bar is taller than that by the
        // status bar inset, so a `SizedBox(height: preferredSize)` here
        // squashed the toolbar out of existence on any device with a
        // notch — and measured nothing on a test view, which has none.
        child: FractionalTranslation(
          translation: Offset(0, -(1 - _ctrl.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Entrance
// ═══════════════════════════════════════════════════════════════

/// Plays an [EntranceKind] over an app bar when its page opens, and
/// backwards when the page leaves.
///
/// A top bar arrives from ABOVE — `slide` is negative here where the
/// bottom nav's is positive, because "in from its own edge" is a
/// different direction at each end of the screen.
class EntranceAppBar extends StatefulWidget implements PreferredSizeWidget {
  const EntranceAppBar({
    required this.appBar,
    required this.kind,
    super.key,
    this.duration,
    this.curve,
    this.reverseOnExit = true,
  });

  final PreferredSizeWidget appBar;
  final EntranceKind kind;
  final Duration? duration;
  final Curve? curve;

  /// A bar that makes a point of arriving and then vanishes with its
  /// page reads as a cut.
  final bool reverseOnExit;

  @override
  Size get preferredSize => appBar.preferredSize;

  @override
  State<EntranceAppBar> createState() => _EntranceAppBarState();
}

class _EntranceAppBarState extends State<EntranceAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration ?? AppBarDefaults.entranceDuration,
  );

  Animation<double>? _routeAnimation;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (_ctrl.status == AnimationStatus.dismissed) {
      // Reduce motion sets the value rather than zeroing the duration:
      // a zero-length entrance still rebuilds every frame on its way to
      // nowhere.
      if (_reduceMotion || widget.kind == EntranceKind.none) {
        _ctrl.value = 1;
      } else {
        _ctrl.forward();
      }
    }

    if (!widget.reverseOnExit) return;
    final route = ModalRoute.of(context)?.animation;
    if (identical(route, _routeAnimation)) return;
    _routeAnimation?.removeListener(_onRouteTick);
    _routeAnimation = route?..addListener(_onRouteTick);
  }

  /// FOLLOWS the route's animation rather than reacting to its status.
  ///
  /// A predictive-back drag drives that animation from the finger, so a
  /// listener that only heard "reverse" and then ran its own controller
  /// on its own clock played a fixed departure over a gesture the user
  /// was still holding — and had nothing to say when they let go and
  /// came back. Tracking the value scrubs with the drag, reverses as it
  /// goes and returns if it is cancelled, for free.
  ///
  /// The FIRST arrival is still ours: the entrance has its own duration
  /// and curve, which the route transition does not. Following starts
  /// once that has settled.
  void _onRouteTick() {
    if (!mounted || _reduceMotion || widget.kind == EntranceKind.none) return;
    final route = _routeAnimation;
    if (route == null) return;

    // ARM only once the ROUTE has finished arriving, not once our own
    // entrance has. The entrance is shorter than the page transition,
    // so following from the moment it finished snapped the bar back to
    // wherever the route had got to — a jump backwards and then a jump
    // to rest, which is the flash at the end of the slide.
    if (!_armed) {
      if (route.status != AnimationStatus.completed) return;
      _armed = true;
      return;
    }
    _ctrl.value = route.value.clamp(0.0, 1.0);
  }

  /// Following starts when the page has settled, not when the bar has.
  bool _armed = false;

  @override
  void dispose() {
    _routeAnimation?.removeListener(_onRouteTick);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kind == EntranceKind.none) return widget.appBar;

    final t = CurvedAnimation(
      parent: _ctrl,
      curve: widget.curve ?? AppBarDefaults.entranceCurve,
    );

    return AnimatedBuilder(
      animation: t,
      builder: (_, child) {
        final away = 1 - t.value;
        return switch (widget.kind) {
          EntranceKind.none => child!,
          EntranceKind.fade => Opacity(opacity: t.value, child: child),
          // NEGATIVE: a top bar arrives from above.
          EntranceKind.slide => FractionalTranslation(
            translation: Offset(0, -away * AppBarDefaults.entranceSlide),
            child: child,
          ),
          EntranceKind.scale => Transform.scale(
            scale: lerpDouble(
              AppBarDefaults.entranceScaleFrom,
              1,
              t.value,
            )!,
            child: child,
          ),
          // A bar has one row, not a row of peers, so there is nothing
          // to stagger. It arrives as one thing rather than pretending.
          EntranceKind.slideFade ||
          EntranceKind.staggered ||
          EntranceKind.slideFadeStaggered => Opacity(
            opacity: t.value,
            child: FractionalTranslation(
              translation: Offset(0, -away * AppBarDefaults.entranceSlide),
              child: child,
            ),
          ),
        };
      },
      child: widget.appBar,
    );
  }
}
