part of 'global_switch.dart';

class _GlobalSwitchState extends State<GlobalSwitch>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _animation;
  Curve? _appliedCurve;

  // Pulse animation
  AnimationController? _pulseController;

  // Pending CurvedAnimation disposal (avoids accumulation on rapid curve changes)
  CurvedAnimation? _pendingAnimationDisposal;

  // Debounce
  DateTime? _lastToggle;

  bool _isHovered = false;
  bool _isFocused = false;

  /// Resolved style — materialized once per build (see build()).
  late ResolvedSwitchStyle _rs;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    // Duration/curve sync to the resolved style at first build.
    _controller = AnimationController(
      duration: kSwitchDefaultAnimDuration,
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
    );
    _appliedCurve = Curves.easeInOut;
    _animation = CurvedAnimation(parent: _controller, curve: _appliedCurve!);
  }

  void _syncCurve(Curve curve) {
    if (_appliedCurve == curve) return;
    _appliedCurve = curve;
    // Dispose previous pending animation if curve changed again before
    // the frame completed.
    _pendingAnimationDisposal?.dispose();
    _pendingAnimationDisposal = _animation;
    _animation = CurvedAnimation(parent: _controller, curve: curve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingAnimationDisposal?.dispose();
      _pendingAnimationDisposal = null;
    });
  }

  @override
  void didUpdateWidget(GlobalSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      widget.value ? _controller.forward() : _controller.reverse();
    }
    // Handle pulse controller lifecycle changes
    if (widget.pulseOnMount && !oldWidget.pulseOnMount) {
      _pulseController?.dispose();
      _pulseController = AnimationController(
        duration: kSwitchPulseDuration,
        vsync: this,
      )..forward();
    } else if (!widget.pulseOnMount && oldWidget.pulseOnMount) {
      _pulseController?.dispose();
      _pulseController = null;
    }
  }

  @override
  void dispose() {
    _pendingAnimationDisposal?.dispose();
    _animation.dispose();
    _controller.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  bool get _isDisabled => !widget.enabled || widget.onChanged == null;

  void _handleToggle() {
    if (_isDisabled || widget.loading) return;

    // Debounce guard
    if (widget.debounce) {
      final now = DateTime.now();
      if (_lastToggle != null &&
          now.difference(_lastToggle!) < kSwitchDebounceDuration) {
        return;
      }
      _lastToggle = now;
    }

    if (_rs.enableHaptic) HapticFeedback.lightImpact();
    widget.onChanged!(!widget.value);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final isV = widget.isVertical;
    final mainAxis = isV ? _rs.height : _rs.width;
    final padSum = isV ? _rs.padding.vertical : _rs.padding.horizontal;
    final trackLength = mainAxis - _rs.thumbSize - padSum;
    if (trackLength <= 0) return;
    final delta = isV ? details.delta.dy : details.delta.dx;
    final newValue = (_controller.value + delta / trackLength).clamp(0.0, 1.0);
    _controller.value = newValue;
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isDisabled || widget.loading) return;

    // Snap to nearest end based on current position
    final shouldBeOn = _controller.value > kSwitchDragThreshold;
    if (shouldBeOn != widget.value) {
      _handleToggle();
    } else {
      // Snap back to current state
      widget.value ? _controller.forward() : _controller.reverse();
    }
  }

  // ─── Color resolution ──────────────────────────────────────

  Color get _trackColor => widget.value ? _rs.activeColor : _rs.inactiveColor;

  Color get _thumbColor {
    if (_rs.thumbColor != null) return _rs.thumbColor!;
    if (widget.value && _rs.activeThumbColor != null) {
      return _rs.activeThumbColor!;
    }
    if (!widget.value && _rs.inactiveThumbColor != null) {
      return _rs.inactiveThumbColor!;
    }
    return _rs.defaultThumbColor;
  }

  /// Whether the thumb uses the context default (drives the loading
  /// spinner contrast).
  bool get _thumbIsDefault =>
      _rs.thumbColor == null &&
      (widget.value ? _rs.activeThumbColor : _rs.inactiveThumbColor) == null;

  Color get _borderColor {
    if (_rs.borderColor != null) return _rs.borderColor!;
    if (widget.value && _rs.activeBorderColor != null) {
      return _rs.activeBorderColor!;
    }
    if (!widget.value && _rs.inactiveBorderColor != null) {
      return _rs.inactiveBorderColor!;
    }
    return Colors.transparent;
  }

  Gradient? get _trackGradient {
    if (widget.value && _rs.activeGradient != null) return _rs.activeGradient;
    if (!widget.value && _rs.inactiveGradient != null) {
      return _rs.inactiveGradient;
    }
    return _rs.gradient;
  }

  Gradient? get _thumbGradient {
    if (widget.value && _rs.activeThumbGradient != null) {
      return _rs.activeThumbGradient;
    }
    if (!widget.value && _rs.inactiveThumbGradient != null) {
      return _rs.inactiveThumbGradient;
    }
    return _rs.thumbGradient;
  }

  Gradient? get _borderGradient {
    if (widget.value && _rs.activeBorderGradient != null) {
      return _rs.activeBorderGradient;
    }
    if (!widget.value && _rs.inactiveBorderGradient != null) {
      return _rs.inactiveBorderGradient;
    }
    return _rs.borderGradient;
  }

  // ─── Resolved dimensions ───────────────────────────────────

  double get _thumbDiameter {
    if (!_rs.animateThumbSize) return _rs.thumbSize;
    return widget.value ? _rs.thumbSize + kSwitchM3ThumbGrowth : _rs.thumbSize;
  }

  BorderRadius get _effectiveTrackBorderRadius {
    if (_rs.customTrackBorderRadius != null) {
      return _rs.customTrackBorderRadius!;
    }
    if (_rs.borderRadius != null && _rs.borderRadius! >= 0) {
      return BorderRadius.circular(_rs.borderRadius!);
    }
    return BorderRadius.circular(switch (_rs.trackShape) {
      TrackShape.pill => _rs.height / 2,
      TrackShape.roundedRect => _rs.height * 0.25,
      TrackShape.rectangle => 4.0,
    });
  }

  BorderRadius get _effectiveThumbBorderRadius {
    if (_rs.customThumbBorderRadius != null) {
      return _rs.customThumbBorderRadius!;
    }
    return switch (_rs.thumbShape) {
      ThumbShape.circle => BorderRadius.circular(_thumbDiameter / 2),
      ThumbShape.roundedRect => BorderRadius.circular(_thumbDiameter * 0.25),
      ThumbShape.squircle => BorderRadius.circular(_thumbDiameter * 0.35),
    };
  }

  // Track dimensions — swapped for vertical mode
  double get _trackWidth => widget.isVertical ? _rs.height : _rs.width;
  double get _trackHeight => widget.isVertical ? _rs.width : _rs.height;

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Materialize the themeable bag once per build (resolved-style
    // invariant) + register the locale dependency (the semantics label
    // resolves via Tr/S — static reads).
    _rs = widget.style.resolve(context, size: widget.size);
    Localizations.maybeLocaleOf(context);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _controller.duration = _reduceMotion
        ? Duration.zero
        : _rs.animationDuration;
    _syncCurve(_rs.animationCurve);

    final isDisabled = _isDisabled;
    final borderRadius = _effectiveTrackBorderRadius;
    final canDrag = widget.enableDrag && !isDisabled && !_reduceMotion;

    Widget switchWidget = GestureDetector(
      onTap: isDisabled ? null : _handleToggle,
      onHorizontalDragUpdate: canDrag && !widget.isVertical
          ? _onDragUpdate
          : null,
      onHorizontalDragEnd: canDrag && !widget.isVertical ? _onDragEnd : null,
      onVerticalDragUpdate: canDrag && widget.isVertical ? _onDragUpdate : null,
      onVerticalDragEnd: canDrag && widget.isVertical ? _onDragEnd : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isDisabled ? kSwitchDefaultDisabledOpacity : 1.0,
        child: widget.isVertical
            ? _buildVertical(borderRadius)
            : _buildHorizontal(borderRadius),
      ),
    );

    // Hover / focus overlay + keyboard activation (Enter/Space).
    switchWidget = Actions(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _handleToggle();
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
                  switchWidget,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedContainer(
                        duration: AppDurations.fast,
                        decoration: BoxDecoration(
                          color: _isFocused ? _rs.focusColor : _rs.hoverColor,
                          borderRadius: borderRadius,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : switchWidget,
      ),
    );

    // Tooltip — disabled tooltip takes priority when switch is disabled
    final effectiveTooltip = (isDisabled && widget.disabledTooltip != null)
        ? widget.disabledTooltip
        : widget.tooltip;
    if (effectiveTooltip != null) {
      switchWidget = GlobalTooltip(
        message: effectiveTooltip,
        child: switchWidget,
      );
    }

    return Semantics(
      label:
          widget.semanticLabel ??
          (widget.value ? SwitchStrings.on : SwitchStrings.off),
      toggled: widget.value,
      enabled: !isDisabled,
      onTap: isDisabled ? null : _handleToggle,
      excludeSemantics: true,
      child: switchWidget,
    );
  }

  // ─── Horizontal layout ─────────────────────────────────────

  Widget _buildHorizontal(BorderRadius borderRadius) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabels && widget.inactiveLabel != null) ...[
          _buildSideLabel(
            widget.inactiveLabel!,
            widget.value ? kSwitchInactiveLabelOpacity : 1.0,
          ),
          const SizedBox(width: kSwitchLabelSpacing),
        ],
        AnimatedBuilder(
          animation: _animation,
          builder: (context, _) => _buildTrack(borderRadius),
        ),
        if (widget.showLabels && widget.activeLabel != null) ...[
          const SizedBox(width: kSwitchLabelSpacing),
          _buildSideLabel(
            widget.activeLabel!,
            widget.value ? 1.0 : kSwitchInactiveLabelOpacity,
          ),
        ],
      ],
    );
  }

  // ─── Vertical layout ───────────────────────────────────────

  Widget _buildVertical(BorderRadius borderRadius) {
    final track = AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => _buildTrack(borderRadius),
    );

    if (!widget.showLabels ||
        (widget.activeLabel == null && widget.inactiveLabel == null)) {
      return track;
    }

    // Vertical labels — inactive on top, active on bottom
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.inactiveLabel != null) ...[
          _buildSideLabel(
            widget.inactiveLabel!,
            widget.value ? kSwitchInactiveLabelOpacity : 1.0,
          ),
          const SizedBox(height: kSwitchLabelSpacing),
        ],
        track,
        if (widget.activeLabel != null) ...[
          const SizedBox(height: kSwitchLabelSpacing),
          _buildSideLabel(
            widget.activeLabel!,
            widget.value ? 1.0 : kSwitchInactiveLabelOpacity,
          ),
        ],
      ],
    );
  }

  // ─── Side label ────────────────────────────────────────────

  Widget _buildSideLabel(String text, double opacity) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: _controller.duration!,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style:
            _rs.labelStyle ??
            const TextStyle(
              fontSize: kSwitchDefaultLabelFontSize,
              fontWeight: kSwitchDefaultLabelFontWeight,
            ),
      ),
    );
  }

  // ─── Track ─────────────────────────────────────────────────

  Widget _buildTrack(BorderRadius borderRadius) {
    final trackColor = _trackColor;
    final trackGradient = _trackGradient;
    final borderGradient = _borderGradient;
    final hasBorderGradient = borderGradient != null;
    final hasSolidBorder = _rs.borderWidth > 0 && !hasBorderGradient;

    // Check if we need gradient cross-fade (both active and inactive gradients set)
    final hasGradientTransition =
        _rs.activeGradient != null && _rs.inactiveGradient != null;

    final shadow = _rs.elevation > 0
        ? [
            BoxShadow(
              color: (_rs.shadowColor ?? trackColor).withValues(
                alpha: kSwitchDefaultTrackShadowAlpha,
              ),
              blurRadius: _rs.elevation,
              offset: Offset(0, _rs.elevation / 2),
            ),
          ]
        : null;

    final border = hasSolidBorder
        ? Border.all(color: _borderColor, width: _rs.borderWidth)
        : null;

    final content = Padding(
      padding: _rs.padding,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (widget.activeTrackLabel != null ||
              widget.inactiveTrackLabel != null)
            _buildTrackLabels(),
          _buildThumb(),
        ],
      ),
    );

    Widget track;

    if (hasGradientTransition) {
      track = SizedBox(
        width: _trackWidth,
        height: _trackHeight,
        child: Stack(
          children: [
            // Inactive gradient layer
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: _rs.inactiveGradient,
                  borderRadius: borderRadius,
                  border: border,
                  boxShadow: shadow,
                ),
              ),
            ),
            // Active gradient layer — fades in/out with animation
            Positioned.fill(
              child: Opacity(
                opacity: _controller.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _rs.activeGradient,
                    borderRadius: borderRadius,
                    border: border,
                  ),
                ),
              ),
            ),
            content,
          ],
        ),
      );
    } else {
      // Standard solid color / single gradient track
      track = AnimatedContainer(
        duration: _controller.duration!,
        curve: Curves.easeInOut,
        width: _trackWidth,
        height: _trackHeight,
        decoration: BoxDecoration(
          color: trackGradient == null ? trackColor : null,
          gradient: trackGradient,
          borderRadius: borderRadius,
          border: border,
          boxShadow: shadow,
        ),
        child: content,
      );
    }

    if (hasBorderGradient && _rs.borderWidth > 0) {
      track = CustomPaint(
        foregroundPainter: GradientBorderPainter(
          gradient: borderGradient,
          borderRadius: borderRadius,
          borderWidth: _rs.borderWidth,
        ),
        child: track,
      );
    }

    return track;
  }

  // ─── Track labels ──────────────────────────────────────────

  Widget _buildTrackLabels() {
    final defaultStyle =
        _rs.trackLabelStyle ??
        TextStyle(
          fontSize: _trackHeight * 0.32,
          fontWeight: FontWeight.w700,
          color: _rs.onPrimary.withValues(alpha: 0.8),
        );

    final isV = widget.isVertical;
    final activeLabel = AnimatedOpacity(
      opacity: widget.value ? 1.0 : 0.0,
      duration: _controller.duration!,
      child: Center(
        child: Padding(
          padding: isV
              ? EdgeInsets.only(bottom: _rs.thumbSize / 2)
              : EdgeInsets.only(right: _rs.thumbSize / 2),
          child: Text(
            widget.activeTrackLabel ?? '',
            style: defaultStyle,
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ),
      ),
    );

    final inactiveLabel = AnimatedOpacity(
      opacity: widget.value ? 0.0 : 1.0,
      duration: _controller.duration!,
      child: Center(
        child: Padding(
          padding: isV
              ? EdgeInsets.only(top: _rs.thumbSize / 2)
              : EdgeInsets.only(left: _rs.thumbSize / 2),
          child: Text(
            widget.inactiveTrackLabel ?? '',
            style: defaultStyle,
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ),
      ),
    );

    return Positioned.fill(
      child: isV
          ? Column(
              children: [
                Expanded(child: inactiveLabel),
                Expanded(child: activeLabel),
              ],
            )
          : Row(
              children: [
                Expanded(child: activeLabel),
                Expanded(child: inactiveLabel),
              ],
            ),
    );
  }

  // ─── Thumb ─────────────────────────────────────────────────

  Widget _buildThumb() {
    final thumbColor = _thumbColor;
    final thumbGradient = _thumbGradient;
    // Resolve thumb shape — use custom radius if provided, otherwise use enum
    final useCircle =
        _rs.thumbShape == ThumbShape.circle &&
        _rs.customThumbBorderRadius == null;
    final thumbDecoration = BoxDecoration(
      color: thumbGradient == null ? thumbColor : null,
      gradient: thumbGradient,
      shape: useCircle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: useCircle ? null : _effectiveThumbBorderRadius,
      boxShadow: _rs.thumbShadow
          ? [
              // Neutral elevation shadow — black by Material convention.
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: kSwitchDefaultThumbShadowAlpha,
                ),
                blurRadius: kSwitchDefaultThumbShadowBlur,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );

    // Thumb content: loading > icon > thumb text > empty
    Widget thumbContent;
    if (widget.loading) {
      thumbContent = SizedBox(
        width: _rs.thumbSize * 0.5,
        height: _rs.thumbSize * 0.5,
        child: GlobalProgress.loading(
          type: ProgressType.circular,
          style: ProgressStyle(
            thickness: 2,
            color: _thumbIsDefault ? _rs.activeColor : thumbColor,
          ),
        ),
      );
    } else if (widget.activeIcon != null || widget.inactiveIcon != null) {
      thumbContent = AnimatedSwitcher(
        duration: _controller.duration!,
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: widget.value
            ? (widget.activeIcon ?? const SizedBox.shrink())
            : (widget.inactiveIcon ?? const SizedBox.shrink()),
      );
    } else if (widget.activeThumbText != null ||
        widget.inactiveThumbText != null) {
      final thumbText = widget.value
          ? widget.activeThumbText
          : widget.inactiveThumbText;
      thumbContent = AnimatedSwitcher(
        duration: _controller.duration!,
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: Text(
          thumbText ?? '',
          key: ValueKey(thumbText),
          style:
              _rs.thumbTextStyle ??
              TextStyle(
                fontSize: _rs.thumbSize * kSwitchThumbTextFontSizeFactor,
                fontWeight: FontWeight.w700,
                color: widget.value ? _rs.activeColor : _rs.secondaryText,
              ),
        ),
      );
    } else {
      thumbContent = const SizedBox.shrink();
    }

    Widget thumb = AnimatedContainer(
      duration: _controller.duration!,
      curve: _rs.animationCurve,
      width: _thumbDiameter,
      height: _thumbDiameter,
      decoration: thumbDecoration,
      child: Center(child: thumbContent),
    );

    // Pulse animation on mount — uses OverflowBox so the ring can exceed
    // thumb bounds. Skipped under reduced motion.
    if (widget.pulseOnMount && !_reduceMotion) {
      _pulseController ??= AnimationController(
        duration: kSwitchPulseDuration,
        vsync: this,
      )..forward();
      final pulseSize =
          _rs.thumbSize * 1.8; // enough room for the expanding ring
      thumb = SizedBox(
        width: _thumbDiameter,
        height: _thumbDiameter,
        child: OverflowBox(
          maxWidth: pulseSize,
          maxHeight: pulseSize,
          child: AnimatedBuilder(
            animation: _pulseController!,
            builder: (context, child) {
              final t = _pulseController!.value;
              final ringScale = 1.0 + t * 0.6;
              final ringOpacity = (1.0 - t).clamp(0.0, 1.0);
              final pulseC = _rs.pulseColor;
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: _rs.thumbSize * ringScale,
                    height: _rs.thumbSize * ringScale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pulseC.withValues(alpha: ringOpacity * 0.3),
                      border: Border.all(
                        color: pulseC.withValues(alpha: ringOpacity * 0.9),
                        width: 3,
                      ),
                    ),
                  ),
                  child!,
                ],
              );
            },
            child: thumb,
          ),
        ),
      );
    }

    // Use _controller.value directly so drag moves the thumb in real-time.
    // AnimatedBuilder in _buildTrack already listens to _animation.
    // AlignmentDirectional — RTL flips the travel direction.
    final alignment = widget.isVertical
        ? AlignmentGeometry.lerp(
            Alignment.topCenter,
            Alignment.bottomCenter,
            _controller.value,
          )!
        : AlignmentGeometry.lerp(
            AlignmentDirectional.centerStart,
            AlignmentDirectional.centerEnd,
            _controller.value,
          )!;

    return Align(
      alignment: alignment,
      child: thumb,
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient border painter
// ---------------------------------------------------------------------------
