// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';

import '../../../core/constants/sizes/app_sizes.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/button_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/painters/gradient_border_painter.dart';
import '../image/index.dart';
import '../shimmer/global_shimmer.dart';
import '../tooltip/global_tooltip.dart';
import 'button_internals.dart';
import 'button_models.dart';

export 'button_models.dart';

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

class GlobalIconButton extends StatefulWidget {
  const GlobalIconButton({
    super.key,
    this.iconData,
    this.iconPath,
    this.iconWidget,
    this.iconSize = 24,
    this.onPressed,
    this.onLongPress,
    this.onHover,
    this.enabled = true,
    this.isLoading = false,
    this.autofocus = false,
    this.style,
    this.disabledStyle,
    this.loadingStyle,
    this.tooltip,
    this.debounceDuration,
    this.morphDuration = kMorphDuration,
    this.morphCurve = kMorphCurve,
    this.enforceMinTouchTarget = true,
    this.result = ButtonResult.none,
    this.completionDuration = kCompletionDuration,
    this.onResultShown,
    this.successStyle,
    this.errorStyle,
    this.isFollowingDirectionality = true,
    this.scrollController,
    this.transitionOffset,
    this.overlayColor,
    this.semanticLabel,
    this.size,
    this.isSelected,
    this.selectedStyle,
    this.enableBlur = false,
    this.enableHaptic,
    this.focusNode,
    this.onFocusChange,
    this.onDisabledPressed,
  });

  /// Icon specified as [IconData].
  final IconData? iconData;

  /// Icon specified as an asset path (rendered via [GlobalImage.a]).
  final String? iconPath;

  /// Icon specified as an arbitrary widget.
  final Widget? iconWidget;

  /// Size of the icon. Defaults to 24.
  final double iconSize;

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHover;
  final bool enabled;
  final bool isLoading;
  final bool autofocus;

  /// Base style for the icon button.
  final ButtonStateStyle? style;

  /// Style override when the button is disabled.
  final ButtonStateStyle? disabledStyle;

  /// Style override when the button is loading.
  final ButtonLoadingStyle? loadingStyle;

  final String? tooltip;
  final Duration? debounceDuration;
  final Duration morphDuration;
  final Curve morphCurve;

  /// Whether to enforce a 48x48 minimum touch target for accessibility.
  final bool enforceMinTouchTarget;

  /// The completion result to display after loading finishes.
  final ButtonResult result;

  /// How long to display the completion result before calling [onResultShown].
  final Duration completionDuration;

  /// Called after [completionDuration] elapses so the parent can
  /// reset [result] back to [ButtonResult.none].
  final VoidCallback? onResultShown;

  /// Style override for the success completion state.
  final ButtonStateStyle? successStyle;

  /// Style override for the error completion state.
  final ButtonStateStyle? errorStyle;

  /// Whether the icon asset should follow text directionality (RTL flip).
  final bool isFollowingDirectionality;

  /// When provided, the button listens to this controller and fades its icon
  /// color toward [overlayColor] as the scroll offset approaches
  /// [transitionOffset].
  final ScrollController? scrollController;

  /// The scroll offset at which the transition completes (opacity = 0).
  final double? transitionOffset;

  /// The color to lerp toward during scroll-based transition.
  /// Defaults to the surface color if null.
  final Color? overlayColor;

  /// Screen-reader label. Most icon buttons ship no [tooltip] (the
  /// design often does not want one), and without this they all
  /// announce the same generic string.
  final String? semanticLabel;

  /// Size preset (sm/md/lg) — sets the square side. Explicit
  /// `style.width` / `style.height` win.
  final ButtonSize? size;

  /// Toggle state (favorite / bookmark / mute). Null = not a toggle.
  /// When true, [selectedStyle] merges over a soft primary-tint
  /// default, and the state is exposed via `Semantics(selected:)`.
  final bool? isSelected;

  /// Merged over the built-in selected look when [isSelected] is true.
  final ButtonStateStyle? selectedStyle;

  /// Frosted-glass surface — the standard treatment for icon buttons
  /// floating over imagery (app bars, carousels, video overlays).
  final bool enableBlur;

  /// Gates the tap/long-press haptic. Null defers to
  /// [GlobalButtonsTheme.enableHaptic], then `true`.
  final bool? enableHaptic;

  /// External focus node — lets a form move focus onto the button
  /// (the repo's a11y rules mandate FocusTraversalGroup for forms).
  final FocusNode? focusNode;

  /// Fired when the button gains or loses focus.
  final ValueChanged<bool>? onFocusChange;

  /// Fired when the button is tapped or keyboard-activated while
  /// [enabled] is false (and not loading / showing a result). Setting
  /// it makes the disabled button focusable + tappable — the classic
  /// "tap the dead submit to surface validation errors" hook. Null
  /// keeps the standard inert disabled behavior.
  final VoidCallback? onDisabledPressed;

  @override
  State<GlobalIconButton> createState() => _GlobalIconButtonState();
}

class _GlobalIconButtonState extends State<GlobalIconButton>
    with ButtonBehaviorMixin<GlobalIconButton> {
  /// Theme-merged base bag + effective haptic/motion (set each build).
  ButtonStateStyle? _base;
  bool _haptic = true;
  Duration _morph = kMorphDuration;
  GlobalButtonsTheme? _btnTheme;

  /// Per-state bags with the app-wide theme merged UNDER the per-call
  /// value, so a partial call-site override keeps the themed defaults.
  ButtonStateStyle? get _themedDisabledStyle => _btnTheme?.disabledStyle == null
      ? widget.disabledStyle
      : _btnTheme!.disabledStyle!.merge(widget.disabledStyle);

  ButtonLoadingStyle? get _themedLoadingStyle => _btnTheme?.loadingStyle == null
      ? widget.loadingStyle
      : _btnTheme!.loadingStyle!.merge(widget.loadingStyle);

  ButtonStateStyle? get _themedSuccessStyle => _btnTheme?.successStyle == null
      ? widget.successStyle
      : _btnTheme!.successStyle!.merge(widget.successStyle);

  ButtonStateStyle? get _themedErrorStyle => _btnTheme?.errorStyle == null
      ? widget.errorStyle
      : _btnTheme!.errorStyle!.merge(widget.errorStyle);

  Duration? get _effectiveDebounce =>
      widget.debounceDuration ?? _btnTheme?.debounceDuration;

  /// Scroll-based opacity (1 = fully visible, 0 = fully faded).
  double _scrollOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _syncResult();
    _attachScrollListener();
  }

  @override
  void didUpdateWidget(GlobalIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result ||
        oldWidget.isLoading != widget.isLoading) {
      _syncResult();
    }
    if (oldWidget.scrollController != widget.scrollController) {
      _detachScrollListener(oldWidget);
      _attachScrollListener();
    } else if (oldWidget.transitionOffset != widget.transitionOffset) {
      _syncScrollOpacity();
    }
  }

  @override
  void dispose() {
    disposeButtonBehavior();
    _detachScrollListener(widget);
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Scroll listener
  // -------------------------------------------------------------------------

  void _attachScrollListener() {
    widget.scrollController?.addListener(_onScroll);
    // Seed from the controller's CURRENT offset: a button mounted into
    // an app bar over an already-scrolled list used to render at full
    // opacity until the user happened to scroll.
    _syncScrollOpacity();
  }

  void _detachScrollListener(GlobalIconButton old) {
    old.scrollController?.removeListener(_onScroll);
  }

  void _onScroll() => _syncScrollOpacity();

  /// Recomputes the fade and rebuilds ONLY when it actually moved —
  /// past the transition offset the value is pinned, and an
  /// unconditional setState re-ran the full style resolution for every
  /// button in the app bar on every scroll frame.
  void _syncScrollOpacity() {
    final controller = widget.scrollController;
    final limit = widget.transitionOffset;
    if (controller == null || limit == null || limit <= 0) return;
    if (!controller.hasClients) return;
    final fraction = (controller.offset / limit).clamp(0.0, 1.0);
    final next = 1.0 - fraction;
    if ((next - _scrollOpacity).abs() < 0.001) return;
    if (!mounted) {
      _scrollOpacity = next;
      return;
    }
    setState(() => _scrollOpacity = next);
  }

  // -------------------------------------------------------------------------
  // Completion result
  // -------------------------------------------------------------------------

  void _syncResult() => syncButtonResult(
    result: widget.result,
    isLoading: widget.isLoading,
    completionDuration: widget.completionDuration,
    onResultShown: widget.onResultShown,
  );

  // -------------------------------------------------------------------------
  // Debounce
  // -------------------------------------------------------------------------

  VoidCallback? get _debouncedOnPressed => debouncedCallback(
    widget.onPressed,
    debounce: _effectiveDebounce,
    haptic: _haptic,
  );

  VoidCallback? get _debouncedOnLongPress => debouncedCallback(
    widget.onLongPress,
    debounce: _effectiveDebounce,
    haptic: _haptic,
    isLongPress: true,
  );

  // -------------------------------------------------------------------------
  // Completion result defaults
  // -------------------------------------------------------------------------

  ButtonStateStyle _defaultSuccessStyle() {
    final success = context.statusColors.success;
    return ButtonStateStyle(
      backgroundColor: success.withValues(alpha: 0.15),
      foregroundColor: success,
    );
  }

  ButtonStateStyle _defaultErrorStyle() {
    final error = context.statusColors.error;
    return ButtonStateStyle(
      backgroundColor: error.withValues(alpha: 0.15),
      foregroundColor: error,
    );
  }

  // -------------------------------------------------------------------------
  // Style resolution
  // -------------------------------------------------------------------------

  LoadingType get _effectiveLoadingType =>
      _themedLoadingStyle?.loadingType ?? LoadingType.shimmer;

  ButtonStateStyle? _resolveStateStyle() {
    if (widget.isLoading) return _themedLoadingStyle;
    if (showingResult) {
      switch (activeResult) {
        case ButtonResult.success:
          // Merge, not replace: `successStyle: ButtonStateStyle(
          // text: 'Saved!')` must keep the checkmark and colours.
          return _defaultSuccessStyle().merge(_themedSuccessStyle);
        case ButtonResult.error:
          return _defaultErrorStyle().merge(_themedErrorStyle);
        case ButtonResult.none:
          break;
      }
    }
    if (widget.enabled && (widget.isSelected ?? false)) {
      // Merge, not replace — a partial selectedStyle keeps the tint.
      return _defaultSelectedStyle().merge(widget.selectedStyle);
    }
    return widget.enabled ? widget.style : _themedDisabledStyle;
  }

  /// Soft role-aware primary tint + primary glyph — the M3 selected
  /// icon-toggle look. Opaque (alpha-blended over the surface) so the
  /// contrast audit still applies.
  ButtonStateStyle _defaultSelectedStyle() {
    final primary = context.primaryColors.primary;
    return ButtonStateStyle(
      backgroundColor: Color.alphaBlend(
        primary.withValues(alpha: 0.14),
        context.backgroundColors.surface,
      ),
      // High-contrast primary — the raw primary on its own tint can
      // fall below AA (guest pink measured 2.4:1 on the filled tonal).
      foregroundColor: context.primaryColors.primaryHighContrast,
    );
  }

  ResolvedColors _resolveColors(
    BuildContext context,
    ButtonStateStyle? stateStyle,
  ) {
    final baseStyle = _base;

    final bgGradient =
        stateStyle?.backgroundGradient ?? baseStyle?.backgroundGradient;
    // Blur needs a real tint to frost: a transparent base made the
    // 20%-alpha fill collapse to a black scrim.
    final bg =
        stateStyle?.backgroundColor ??
        baseStyle?.backgroundColor ??
        (widget.enableBlur
            ? context.backgroundColors.surface
            : Colors.transparent);
    final fg =
        stateStyle?.foregroundColor ??
        baseStyle?.foregroundColor ??
        context.iconColors.primary;

    final disabledBgGradient = _themedDisabledStyle?.backgroundGradient;
    // Only tint the disabled surface if the button actually HAS one.
    // The icon default is transparent, and falling back to the opaque
    // buttonsColors.disabled painted a grey block over the layout —
    // outlined and text buttons stay transparent in the same state.
    final disabledBg =
        _themedDisabledStyle?.backgroundColor ??
        (bg == Colors.transparent
            ? Colors.transparent
            : context.buttonsColors.disabled);
    final disabledFg =
        _themedDisabledStyle?.foregroundColor ?? context.textColors.disabled;

    final isEffectivelyEnabled = widget.enabled || showingResult;

    return ResolvedColors(
      background: bg,
      foreground: fg,
      disabledBackground: disabledBg,
      disabledForeground: disabledFg,
      backgroundGradient: isEffectivelyEnabled ? bgGradient : null,
      // Disabled: an explicit disabledStyle gradient paints exactly as
      // given (it used to be washed to 38% against the caller's
      // intent); a button with only a base gradient keeps it, dimmed,
      // instead of silently collapsing to a flat colour.
      disabledBackgroundGradient: isEffectivelyEnabled
          ? null
          : (disabledBgGradient ??
                (bgGradient == null
                    ? null
                    : applyAlphaToGradient(
                        bgGradient,
                        kDisabledGradientAlpha,
                      ))),
    );
  }

  ResolvedDecoration _resolveDecoration(ButtonStateStyle? stateStyle) {
    final baseStyle = _base;

    const defaultRadius = BorderRadius.all(
      Radius.circular(AppSizes.buttonRadiusMd),
    );

    final radius =
        stateStyle?.borderRadius ?? baseStyle?.borderRadius ?? defaultRadius;
    final elev = stateStyle?.elevation ?? baseStyle?.elevation ?? 0;
    final shadow = stateStyle?.shadowColor ?? baseStyle?.shadowColor;
    final bdr = stateStyle?.border ?? baseStyle?.border;
    final bdrGradient = stateStyle?.borderGradient ?? baseStyle?.borderGradient;
    final pad = stateStyle?.padding ?? baseStyle?.padding;

    return ResolvedDecoration(
      borderRadius: radius,
      padding: pad,
      elevation: elev,
      shadowColor: shadow,
      border: bdr,
      borderGradient: bdrGradient,
    );
  }

  // -------------------------------------------------------------------------
  // Icon building
  // -------------------------------------------------------------------------

  Widget _buildIcon(Color color) {
    if (widget.iconWidget != null) return widget.iconWidget!;
    if (widget.iconData != null) {
      return Icon(widget.iconData, size: widget.iconSize, color: color);
    }
    if (widget.iconPath != null) {
      return GlobalImage.a(
        widget.iconPath!,
        width: widget.iconSize,
        height: widget.iconSize,
        mirrorInRtl: widget.isFollowingDirectionality,
        style: ImageStyle(color: color, backgroundColor: Colors.transparent),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildResultIcon() {
    final isSuccess = activeResult == ButtonResult.success;
    // Merge over the defaults and route through the themed bags — the
    // same contract _resolveStateStyle uses. A partial
    // `successStyle: ButtonStateStyle(text: ...)` kept losing the
    // status colour here.
    final resultStyle = isSuccess
        ? _defaultSuccessStyle().merge(_themedSuccessStyle)
        : _defaultErrorStyle().merge(_themedErrorStyle);
    final iconColor = resultStyle.foregroundColor ?? context.iconColors.primary;

    return Icon(
      isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
      size: kResultIconSize,
      color: iconColor,
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final btnTheme = GlobalButtonsTheme.maybeOf(context);
    _btnTheme = btnTheme;
    final themeBase = btnTheme?.iconStyle;
    _base = themeBase == null ? widget.style : themeBase.merge(widget.style);
    _haptic = widget.enableHaptic ?? btnTheme?.enableHaptic ?? true;
    // Reduced motion collapses every morph/entrance tween.
    _morph = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : widget.morphDuration;
    final stateStyle = _resolveStateStyle();
    final colors = _resolveColors(context, stateStyle);
    final decoration = _resolveDecoration(stateStyle);

    final resolvedRadius = decoration.borderRadius.resolve(
      Directionality.of(context),
    );

    final isEffectivelyEnabled = widget.enabled || showingResult;

    // Determine icon foreground color
    final effectiveLoadingType = _effectiveLoadingType;
    Color fgColor;
    if (!isEffectivelyEnabled) {
      fgColor = colors.disabledForeground;
    } else if (widget.isLoading) {
      fgColor =
          (effectiveLoadingType == LoadingType.circular ||
              effectiveLoadingType == LoadingType.border)
          ? colors.foreground.withValues(alpha: 0.3)
          : colors.foreground.withValues(alpha: 0.7);
    } else {
      fgColor = colors.foreground;
    }

    // Apply scroll-based color interpolation
    if (widget.scrollController != null && widget.transitionOffset != null) {
      final effectiveOverlayColor =
          widget.overlayColor ?? context.backgroundColors.surface;
      fgColor =
          Color.lerp(effectiveOverlayColor, fgColor, _scrollOpacity) ?? fgColor;
    }

    // Build the icon content with AnimatedSwitcher for crossfade
    final Widget iconContent;
    if (showingResult && activeResult != ButtonResult.none) {
      iconContent = KeyedSubtree(
        key: ValueKey('result-${activeResult.name}'),
        child: _buildResultIcon(),
      );
    } else {
      // Keyed by WHICH glyph, not by the constant string 'icon'.
      //
      // With a fixed key the switcher could only ever animate between
      // the icon and a result badge — swapping `iconData` from play to
      // pause changed the child in place and crossfaded nothing, so
      // `morphDuration` and `morphCurve` were advertised knobs that
      // could not fire for the commonest case there is: a button whose
      // glyph toggles.
      iconContent = KeyedSubtree(
        key: ValueKey(
          widget.iconWidget != null
              // A caller-supplied widget carries its own identity; its
              // key is the only honest thing to switch on, and a null
              // one means "do not animate", which is the old behaviour.
              ? widget.iconWidget!.key
              : widget.iconData ?? widget.iconPath,
        ),
        child: _buildIcon(fgColor),
      );
    }

    final animatedIcon = AnimatedSwitcher(
      duration: _morph,
      switchInCurve: widget.morphCurve,
      switchOutCurve: widget.morphCurve,
      child: iconContent,
    );

    // Square size
    // Per-state overrides win, then the base bag, then the accessible
    // default. width/height used to be read from _base only, so
    // loadingStyle/successStyle/disabledStyle sizing silently did
    // nothing and style.height was ignored outright.
    final sideW =
        stateStyle?.width ??
        _base?.width ??
        widget.size?.iconSide ??
        kMinTouchTarget;
    final sideH = stateStyle?.height ?? _base?.height ?? sideW;

    // Debug-only contrast audit of the rendered icon/background pair.
    assert(() {
      final bg = isEffectivelyEnabled
          ? colors.background
          : colors.disabledBackground;
      final gradientActive =
          (isEffectivelyEnabled
              ? colors.backgroundGradient
              : colors.disabledBackgroundGradient) !=
          null;
      if (!gradientActive && bg != null) {
        debugCheckButtonContrast(
          widgetName: 'GlobalIconButton',
          label: widget.tooltip ?? 'icon',
          foreground: fgColor,
          background: bg,
        );
      }
      return true;
    }());

    // Interaction is blocked during loading and result display
    final isInteractionBlocked = widget.isLoading || showingResult;

    // One shared surface for every variant. `enabled` intentionally
    // includes showingResult so the success/error flash keeps its tint
    // (the blur path used to invert this and flash disabled grey).
    final surfaceEnabled = widget.enabled || showingResult;
    final surfaceGradient = surfaceEnabled
        ? colors.backgroundGradient
        : colors.disabledBackgroundGradient;
    // Disabled-but-actionable hook: routed into ButtonSurface's own
    // InkWell so the ripple paints ABOVE the opaque background — the
    // old external wrapper's transparency Material sat BEHIND it and
    // its splash was invisible.
    final disabledTap =
        (!widget.enabled &&
            !isInteractionBlocked &&
            widget.onDisabledPressed != null)
        ? debouncedCallback(
            widget.onDisabledPressed,
            debounce: _effectiveDebounce,
            haptic: _haptic,
          )
        : null;

    final baseButton = ButtonSurface(
      kind: widget.enableBlur
          ? ButtonSurfaceKind.blur
          : (surfaceGradient != null
                ? ButtonSurfaceKind.gradient
                : ButtonSurfaceKind.solid),
      colors: colors,
      decoration: decoration,
      resolvedRadius: resolvedRadius,
      content: animatedIcon,
      enabled: surfaceEnabled,
      isLoading: isInteractionBlocked,
      onPressed: _debouncedOnPressed,
      onLongPress: _debouncedOnLongPress,
      onDisabledTap: disabledTap,
      onHover: widget.onHover,
      onFocusChange: widget.onFocusChange,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      // null padding = centred icon.
      padding: null,
      morphDuration: _morph,
      morphCurve: widget.morphCurve,
    );

    // Loading overlay
    final loadingOverlay = _buildLoadingOverlay(
      colors: colors,
      decoration: decoration,
      resolvedRadius: resolvedRadius,
      fgColor: fgColor,
    );

    // Gradient border painter
    final borderPainter = decoration.borderGradient != null
        ? GradientBorderPainter(
            gradient: decoration.borderGradient!,
            borderRadius: resolvedRadius,
            borderWidth: decoration.border?.width ?? 1.5,
          )
        : null;

    Widget button = SizedBox(
      width: sideW,
      height: sideH,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          baseButton,
          // Always mounted: removing the switcher from the tree the
          // instant loading ends gave it nothing to animate out, so
          // the shimmer/border trace hard-cut. An empty child lets it
          // fade properly. RepaintBoundary because these loaders
          // repaint every frame — markNeedsPaint would otherwise
          // propagate to the nearest ancestor boundary, usually the
          // whole route.
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedSwitcher(
                  duration: _morph,
                  child:
                      loadingOverlay ??
                      const SizedBox.shrink(key: ValueKey('no-overlay')),
                ),
              ),
            ),
          ),
          if (borderPainter != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(foregroundPainter: borderPainter),
              ),
            ),
        ],
      ),
    );

    if (widget.tooltip != null) {
      button = GlobalTooltip(
        message: widget.tooltip!,
        // This widget's own Semantics re-exposes the tooltip below, and
        // excludes everything under it — so a second node here would be
        // the same string twice in the widget tree and dropped anyway.
        announceOnAnchor: false,
        child: button,
      );
    }

    // Semantics
    final String semanticLabel;
    if (widget.isLoading) {
      semanticLabel = CommonStrings.loading;
    } else if (showingResult) {
      semanticLabel = activeResult == ButtonResult.success
          ? ButtonStrings.resultSuccess
          : ButtonStrings.resultFailed;
    } else {
      semanticLabel =
          widget.semanticLabel ??
          widget.tooltip ??
          ButtonStrings.iconSemanticLabel;
    }

    // `enabled` must also account for a null onPressed — a button with
    // no callback used to announce itself as actionable.
    final canActivate =
        widget.enabled && !isInteractionBlocked && widget.onPressed != null;

    // Pad BEFORE annotating: with the padding outside, the
    // accessibility node reported the small painted rect and
    // screen-reader/switch targets stayed under 48dp.
    if (widget.enforceMinTouchTarget) {
      button = MinTouchTarget(
        minSize: const Size(kMinTouchTarget, kMinTouchTarget),
        child: button,
      );
    }

    button = Semantics(
      button: true,
      enabled: canActivate,
      selected: widget.isSelected,
      focusable: canActivate || disabledTap != null,
      label: semanticLabel,
      // The inner tree is excluded, so the tooltip's own semantics were
      // dropped entirely — re-expose the text here.
      tooltip: widget.tooltip,
      // Loading start and the completion flash change this node's label
      // for ~1.5s; without a live region a user whose focus sits
      // elsewhere never hears either.
      liveRegion: widget.isLoading || showingResult,
      // Expose activation to assistive tech: normal press when
      // enabled, the disabled hook otherwise.
      onTap: canActivate ? _debouncedOnPressed : disabledTap,
      child: ExcludeSemantics(child: button),
    );

    return button;
  }

  // -------------------------------------------------------------------------
  // Loading overlay
  // -------------------------------------------------------------------------

  Widget? _buildLoadingOverlay({
    required ResolvedColors colors,
    required ResolvedDecoration decoration,
    required BorderRadius resolvedRadius,
    required Color fgColor,
  }) {
    if (!widget.isLoading) return null;

    switch (_effectiveLoadingType) {
      case LoadingType.shimmer:
        final gradient = colors.backgroundGradient;
        final effectiveBg = gradient != null
            ? Color.lerp(gradient.colors.first, gradient.colors.last, 0.5)!
            : colors.background!;
        final baseColor =
            _themedLoadingStyle?.shimmerBaseColor ??
            Color.lerp(effectiveBg, Colors.black, 0.15)!;
        final highlightColor =
            _themedLoadingStyle?.shimmerHighlightColor ??
            Color.lerp(effectiveBg, Colors.white, 0.3)!;
        final period =
            _themedLoadingStyle?.shimmerPeriod ??
            const Duration(milliseconds: 1500);

        return KeyedSubtree(
          key: const ValueKey('shimmer-overlay'),
          child: SizedBox.expand(
            child: ClipRRect(
              borderRadius: resolvedRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GlobalShimmer.wrap(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    borderRadius: decoration.borderRadius,
                    period: period,
                    child: const SizedBox.expand(),
                  ),
                  Center(child: _buildIcon(fgColor)),
                ],
              ),
            ),
          ),
        );

      case LoadingType.circular:
        return KeyedSubtree(
          key: const ValueKey('circular-overlay'),
          child: Center(
            child: CircularIndicator(
              color: colors.foreground.withValues(alpha: 0.8),
            ),
          ),
        );

      case LoadingType.border:
        return KeyedSubtree(
          key: const ValueKey('border-overlay'),
          child: BorderLoadingOverlay(
            color: colors.foreground.withValues(alpha: 0.5),
            borderRadius: resolvedRadius,
          ),
        );

      case LoadingType.linear:
        return KeyedSubtree(
          key: const ValueKey('linear-overlay'),
          child: Center(
            child: LinearIndicator(
              color: colors.foreground.withValues(alpha: 0.8),
            ),
          ),
        );

      case LoadingType.dots:
        return KeyedSubtree(
          key: const ValueKey('dots-overlay'),
          child: Center(
            child: DotsIndicator(
              color: colors.foreground.withValues(alpha: 0.8),
            ),
          ),
        );

      case LoadingType.none:
        return null;
    }
  }
}
