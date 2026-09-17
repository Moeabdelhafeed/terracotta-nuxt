// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';

import '../../../core/constants/sizes/app_sizes.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/button_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/painters/gradient_border_painter.dart';
import '../shimmer/global_shimmer.dart';
import '../tooltip/global_tooltip.dart';
import 'button_internals.dart';
import 'button_models.dart';

export 'button_models.dart';

// ---------------------------------------------------------------------------
// Constants (outlined-button-specific)
// ---------------------------------------------------------------------------

/// Default border width for the outlined button.
const _kDefaultBorderWidth = 1.5;

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

class GlobalOutlinedButton extends StatefulWidget {
  const GlobalOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.onLongPress,
    this.onHover,
    this.enabled = true,
    this.isLoading = false,
    this.autofocus = false,
    this.style,
    this.disabledStyle,
    this.loadingStyle,
    this.shrinkWidth = false,
    this.marqueeLabel,
    this.labelOverflow,
    this.enableBlur = false,
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
    this.size,
    this.enableHaptic,
    this.focusNode,
    this.onFocusChange,
    this.onDisabledPressed,
  });

  final String text;

  /// Convenience leading glyph, tinted with the resolved label
  /// colour (so it dims with disabled/loading states).
  /// `style.leading` wins when both are set.
  final IconData? icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHover;
  final bool enabled;
  final bool isLoading;
  final bool autofocus;
  final ButtonStateStyle? style;
  final ButtonStateStyle? disabledStyle;
  final ButtonLoadingStyle? loadingStyle;
  final bool shrinkWidth;

  /// Scroll the label instead of clipping it when it does not fit.
  ///
  /// Null (default) leaves overflow exactly as it was. Set
  /// `const MarqueeStyle()` for the defaults. Only does anything when
  /// the button's width is CONSTRAINED below its natural content width
  /// — fill-width in a narrow parent, or `shrinkWidth: true` inside an
  /// `Expanded`/`Flexible`. A button with loose constraints simply grows
  /// to fit, so there is nothing to scroll.
  ///
  /// Pause-on-hover/touch are forced off: they install gesture
  /// recognizers, and a pan recognizer inside a button competes with its
  /// own InkWell for taps.
  final MarqueeStyle? marqueeLabel;

  /// What the label does when the button is too narrow for it.
  /// Per-call > [GlobalButtonsTheme.labelOverflow] > marquee.
  final LabelOverflow? labelOverflow;

  final bool enableBlur;
  final String? tooltip;
  final Duration? debounceDuration;
  final Duration morphDuration;
  final Curve morphCurve;

  /// Whether to enforce a 48x48 minimum touch target for accessibility.
  /// The visual button can be smaller; the hit area expands transparently.
  /// Defaults to true.
  final bool enforceMinTouchTarget;

  /// The completion result to display after loading finishes.
  /// Set to [ButtonResult.success] or [ButtonResult.error] to briefly
  /// show a result indicator. Defaults to [ButtonResult.none].
  final ButtonResult result;

  /// How long to display the completion result before calling [onResultShown].
  /// Defaults to 1.5 seconds.
  final Duration completionDuration;

  /// Called after [completionDuration] elapses so the parent can
  /// reset [result] back to [ButtonResult.none].
  final VoidCallback? onResultShown;

  /// Style override for the success completion state.
  /// If null, uses a green-tinted container with a checkmark.
  final ButtonStateStyle? successStyle;

  /// Style override for the error completion state.
  /// If null, uses a red-tinted container with an X icon.
  final ButtonStateStyle? errorStyle;

  /// Size preset (sm/md/lg) — sets height + horizontal padding.
  /// Explicit `style.height` / `style.padding` win.
  final ButtonSize? size;

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
  State<GlobalOutlinedButton> createState() => _GlobalOutlinedButtonState();
}

class _GlobalOutlinedButtonState extends State<GlobalOutlinedButton>
    with ButtonBehaviorMixin<GlobalOutlinedButton> {
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

  TextScaler _textScaler = TextScaler.noScaling;

  @override
  void initState() {
    super.initState();
    _syncResult();
  }

  @override
  void didUpdateWidget(GlobalOutlinedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result ||
        oldWidget.isLoading != widget.isLoading) {
      _syncResult();
    }
  }

  void _syncResult() => syncButtonResult(
    result: widget.result,
    isLoading: widget.isLoading,
    completionDuration: widget.completionDuration,
    onResultShown: widget.onResultShown,
  );

  @override
  void dispose() {
    disposeButtonBehavior();
    super.dispose();
  }

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
  // Completion result style
  // -------------------------------------------------------------------------

  ButtonStateStyle _defaultSuccessStyle() {
    final success = context.statusColors.success;
    return ButtonStateStyle(
      backgroundColor: Colors.transparent,
      foregroundColor: success,
      border: BorderSide(color: success, width: _kDefaultBorderWidth),
      leading: Icon(
        Icons.check_circle_rounded,
        size: kResultIconSize,
        color: success,
      ),
    );
  }

  ButtonStateStyle _defaultErrorStyle() {
    final error = context.statusColors.error;
    return ButtonStateStyle(
      backgroundColor: Colors.transparent,
      foregroundColor: error,
      border: BorderSide(color: error, width: _kDefaultBorderWidth),
      leading: Icon(
        Icons.cancel_rounded,
        size: kResultIconSize,
        color: error,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Style resolution
  // -------------------------------------------------------------------------

  LoadingType get _effectiveLoadingType =>
      _themedLoadingStyle?.loadingType ?? LoadingType.shimmer;

  ButtonStateStyle? _resolveStateStyle() {
    // Completion result takes priority over normal state (but not loading)
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
    return widget.enabled ? widget.style : _themedDisabledStyle;
  }

  ResolvedColors _resolveColors(
    BuildContext context,
    ThemeData theme,
    ButtonStateStyle? stateStyle,
  ) {
    final baseStyle = _base;

    final bgGradient =
        stateStyle?.backgroundGradient ?? baseStyle?.backgroundGradient;
    final bg =
        stateStyle?.backgroundColor ??
        baseStyle?.backgroundColor ??
        Colors.transparent;
    final fg =
        stateStyle?.foregroundColor ??
        baseStyle?.foregroundColor ??
        context.primaryColors.primary;

    final disabledBgGradient = _themedDisabledStyle?.backgroundGradient;
    final disabledBg =
        _themedDisabledStyle?.backgroundColor ?? Colors.transparent;
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

  ResolvedStyle _resolveStyle(
    BuildContext context,
    ThemeData theme,
    ResolvedColors colors,
    ButtonStateStyle? stateStyle,
  ) {
    final effectiveLoadingType = _effectiveLoadingType;
    final isEffectivelyEnabled = widget.enabled || showingResult;

    final fgForText = isEffectivelyEnabled
        ? (widget.isLoading
              ? (effectiveLoadingType == LoadingType.dots ||
                        effectiveLoadingType == LoadingType.circular ||
                        effectiveLoadingType == LoadingType.linear ||
                        effectiveLoadingType == LoadingType.border)
                    ? colors.foreground.withValues(alpha: 0.8)
                    : colors.foreground.withValues(alpha: 0.7)
              : colors.foreground)
        : colors.disabledForeground;

    final defaultTextStyle =
        theme.textTheme.bodyLarge?.copyWith(color: fgForText) ??
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: fgForText,
        );

    final baseStyle = _base;
    var effectiveStyle =
        // MERGE, do not replace: a caller passing a partial style (say
        // only a fontFamily) must keep the preset's size and weight.
        // Replacing dropped fontSize, which also silently disabled the
        // strut — AppTextStrut needs a size to anchor to.
        defaultTextStyle
            .merge(baseStyle?.textStyle)
            .merge(stateStyle?.textStyle);

    if (effectiveStyle.color == null) {
      effectiveStyle = effectiveStyle.copyWith(color: fgForText);
    }

    // Completion result text
    String effectiveText;
    if (showingResult) {
      effectiveText =
          stateStyle?.text ??
          (activeResult == ButtonResult.success
              ? ButtonStrings.resultSuccess
              : ButtonStrings.resultFailed);
    } else {
      effectiveText = stateStyle?.text ?? baseStyle?.text ?? widget.text;
    }

    return ResolvedStyle(textStyle: effectiveStyle, text: effectiveText);
  }

  ResolvedSize _resolveSize(
    ResolvedStyle resolvedStyle,
    ButtonStateStyle? stateStyle,
  ) {
    final baseStyle = _base;
    final wOverride = stateStyle?.width ?? baseStyle?.width;
    final hOverride = stateStyle?.height ?? baseStyle?.height;

    final finalWidth =
        wOverride ?? (widget.shrinkWidth ? null : double.infinity);

    var finalHeight = hOverride ?? widget.size?.height;
    if (finalHeight == null) {
      final measuredSize = textSize(
        resolvedStyle.text,
        resolvedStyle.textStyle,
        textScaler: _textScaler,
      );
      finalHeight = measuredSize.height * 2;
    }

    return ResolvedSize(width: finalWidth, height: finalHeight);
  }

  ResolvedDecoration _resolveDecoration(
    ThemeData theme,
    ButtonStateStyle? stateStyle,
  ) {
    final baseStyle = _base;
    final isEffectivelyEnabled = widget.enabled || showingResult;

    const defaultRadius = BorderRadius.all(
      Radius.circular(AppSizes.buttonRadiusMd),
    );
    final defaultPadding = EdgeInsets.symmetric(
      horizontal: widget.size?.horizontalPadding ?? kDefaultHorizontalPadding,
    );

    final radius =
        stateStyle?.borderRadius ?? baseStyle?.borderRadius ?? defaultRadius;
    final pad = stateStyle?.padding ?? baseStyle?.padding ?? defaultPadding;
    final elev = stateStyle?.elevation ?? baseStyle?.elevation ?? 0;
    final shadow = stateStyle?.shadowColor ?? baseStyle?.shadowColor;
    final bdrGradient = stateStyle?.borderGradient ?? baseStyle?.borderGradient;

    // Resolve border: default to primary border when enabled, disabled border
    // when disabled. Explicit style border always wins.
    var bdr = stateStyle?.border ?? baseStyle?.border;
    if (bdr == null && bdrGradient == null) {
      bdr = isEffectivelyEnabled
          ? BorderSide(
              color: context.primaryColors.primary,
              width: _kDefaultBorderWidth,
            )
          : BorderSide(
              color: context.buttonsColors.disabled,
              width: _kDefaultBorderWidth,
            );
    }

    return ResolvedDecoration(
      borderRadius: radius,
      padding: pad,
      elevation: elev,
      shadowColor: shadow,
      border: bdr,
      borderGradient: bdrGradient,
    );
  }

  ResolvedSlots _resolveSlots(
    ButtonStateStyle? stateStyle, {
    Widget? inlineLoadingIndicator,
    Color? defaultIconColor,
  }) {
    final baseStyle = _base;

    final effectiveLeading =
        stateStyle?.leading ??
        baseStyle?.leading ??
        (widget.icon == null
            ? null
            : Icon(widget.icon, size: 20, color: defaultIconColor));

    Widget? effectiveTrailing;
    if (widget.isLoading && inlineLoadingIndicator != null) {
      effectiveTrailing = stateStyle?.trailing ?? inlineLoadingIndicator;
    } else {
      effectiveTrailing = stateStyle?.trailing ?? baseStyle?.trailing;
    }

    return ResolvedSlots(
      trailing: effectiveTrailing,
      leading: effectiveLeading,
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final btnTheme = GlobalButtonsTheme.maybeOf(context);
    _btnTheme = btnTheme;
    final themeBase = btnTheme?.outlinedStyle;
    _base = themeBase == null ? widget.style : themeBase.merge(widget.style);
    _haptic = widget.enableHaptic ?? btnTheme?.enableHaptic ?? true;
    // Reduced motion collapses every morph/entrance tween.
    _morph = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : widget.morphDuration;
    // Box height derives from the measured label — measure at the
    // ambient scale or large-font users get clipped text.
    _textScaler = MediaQuery.textScalerOf(context);
    final stateStyle = _resolveStateStyle();
    final colors = _resolveColors(context, theme, stateStyle);
    final resolvedStyle = _resolveStyle(context, theme, colors, stateStyle);
    final size = _resolveSize(resolvedStyle, stateStyle);
    final decoration = _resolveDecoration(theme, stateStyle);

    final resolvedRadius = decoration.borderRadius.resolve(
      Directionality.of(context),
    );

    final inlineIndicator = widget.isLoading
        ? _buildInlineIndicator(colors.foreground)
        : null;
    final slots = _resolveSlots(
      stateStyle,
      inlineLoadingIndicator: inlineIndicator,
      defaultIconColor: resolvedStyle.textStyle.color,
    );

    final content = AnimatedButtonContent(
      slots: slots,
      style: resolvedStyle,
      morphDuration: _morph,
      morphCurve: widget.morphCurve,
      marquee: widget.marqueeLabel,
      labelOverflow:
          widget.labelOverflow ??
          btnTheme?.labelOverflow ??
          LabelOverflow.marquee,
    );

    // Debug-only contrast audit of the rendered text/background pair.
    assert(() {
      final active = widget.enabled || showingResult;
      final bg = active ? colors.background : colors.disabledBackground;
      final gradientActive =
          (active
              ? colors.backgroundGradient
              : colors.disabledBackgroundGradient) !=
          null;
      if (!gradientActive && bg != null) {
        debugCheckButtonContrast(
          widgetName: 'GlobalOutlinedButton',
          label: resolvedStyle.text,
          foreground: resolvedStyle.textStyle.color ?? colors.foreground,
          background: bg,
        );
      }
      return true;
    }());

    // Interaction is blocked during loading and result display
    final isInteractionBlocked = widget.isLoading || showingResult;

    // Base button — always in the tree so it can morph continuously
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
      content: content,
      enabled: surfaceEnabled,
      isLoading: isInteractionBlocked,
      onPressed: _debouncedOnPressed,
      onLongPress: _debouncedOnLongPress,
      onDisabledTap: disabledTap,
      onHover: widget.onHover,
      onFocusChange: widget.onFocusChange,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      padding: decoration.padding,
      morphDuration: _morph,
      morphCurve: widget.morphCurve,
    );

    // Loading overlay — layered on top so the base button stays in the tree
    // and can morph smoothly to the next state underneath.
    final loadingOverlay = _buildLoadingOverlay(
      colors: colors,
      decoration: decoration,
      resolvedRadius: resolvedRadius,
      resolvedStyle: resolvedStyle,
      slots: slots,
    );

    // Build border painter (rendered on top of everything including shimmer)
    final borderPainter = decoration.borderGradient != null
        ? GradientBorderPainter(
            gradient: decoration.borderGradient!,
            borderRadius: resolvedRadius,
            borderWidth: decoration.border?.width ?? _kDefaultBorderWidth,
          )
        : null;

    Widget button = AnimatedSize(
      duration: _morph,
      curve: widget.morphCurve,
      clipBehavior: Clip.none,
      child: SizedBox(
        width: size.width,
        height: size.height,
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
            // Gradient border on top of everything (including shimmer)
            if (borderPainter != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(foregroundPainter: borderPainter),
                ),
              ),
          ],
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = GlobalTooltip(message: widget.tooltip!, child: button);
    }

    final String semanticLabel;
    if (widget.isLoading) {
      // Distinct from the idle label, otherwise the live region
      // announces an identical string and conveys nothing.
      semanticLabel =
          _themedLoadingStyle?.text ??
          '${widget.text}, ${CommonStrings.loading}';
    } else if (showingResult) {
      semanticLabel = activeResult == ButtonResult.success
          ? ButtonStrings.resultSuccess
          : ButtonStrings.resultFailed;
    } else if (!widget.enabled) {
      semanticLabel = _themedDisabledStyle?.text ?? widget.text;
    } else {
      semanticLabel = widget.text;
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

  Widget? _buildInlineIndicator(Color color) {
    switch (_effectiveLoadingType) {
      case LoadingType.linear:
        return LinearIndicator(color: color.withValues(alpha: 0.8));
      case LoadingType.circular:
        return CircularIndicator(color: color.withValues(alpha: 0.8));
      case LoadingType.dots:
        return DotsIndicator(color: color.withValues(alpha: 0.8));
      case LoadingType.shimmer:
      case LoadingType.border:
      case LoadingType.none:
        return null;
    }
  }

  /// Builds a loading overlay widget, or null if no overlay is needed.
  Widget? _buildLoadingOverlay({
    required ResolvedColors colors,
    required ResolvedDecoration decoration,
    required BorderRadius resolvedRadius,
    required ResolvedStyle resolvedStyle,
    required ResolvedSlots slots,
  }) {
    if (!widget.isLoading) return null;

    switch (_effectiveLoadingType) {
      case LoadingType.shimmer:
        // Use gradient's dominant color if available for visual match
        final gradient = colors.backgroundGradient;
        final effectiveBg = gradient != null
            ? Color.lerp(gradient.colors.first, gradient.colors.last, 0.5)!
            : colors.foreground;
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
                  // Shimmer effect layer
                  GlobalShimmer.wrap(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    borderRadius: decoration.borderRadius,
                    period: period,
                    child: const SizedBox.expand(),
                  ),
                  // Content on top so it's visible above the shimmer
                  Padding(
                    padding: decoration.padding!.resolve(
                      Directionality.of(context),
                    ),
                    child: Center(
                      child: AnimatedButtonContent(
                        slots: slots,
                        style: resolvedStyle,
                        morphDuration: _morph,
                        morphCurve: widget.morphCurve,
                      ),
                    ),
                  ),
                ],
              ),
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

      case LoadingType.none:
      case LoadingType.linear:
      case LoadingType.circular:
      case LoadingType.dots:
        return null;
    }
  }
}
