import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/common/buttons/actions/action_button_base.dart';
import '../../shared/common/buttons/actions/cancel_button.dart';
import '../localization/strings/common_strings.dart';
import 'loading_cubit.dart';
import 'loading_options.dart';
import 'loading_state.dart';
import 'loading_style.dart';
import 'loading_surface.dart';
import 'loading_token.dart';
import 'theme/loading_theme.dart';

/// Wraps the app and renders the centered overlay (or top bar) over
/// [child] whenever any token is active.
///
/// Mount once near the root inside `MaterialApp.builder`, between
/// other gates and the routed content.
///
/// All styling is driven by [LoadingOptions] (app-level) overlaid
/// with the topmost token's [LoadingShowOptions] (per-show). Provide
/// [options] when mounting to customize globally; pass overrides per
/// `cubit.show(...)` call to customize one-off.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    required this.child,
    this.options,
    this.style = const LoadingStyle(),
    super.key,
  });

  final Widget child;

  /// Optional override for [LoadingCubit.options]. When passed, the
  /// cubit's internal options are updated to match before the first
  /// build. Lets callers configure once at mount-time.
  final LoadingOptions? options;

  /// How it LOOKS. Themeable through `GlobalLoadingTheme`, which is
  /// the point: the overlay is mounted ONCE, so before the bag its
  /// appearance could only be set here.
  final LoadingStyle style;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoadingCubit, LoadingState>(
      builder: (context, state) {
        final cubit = context.read<LoadingCubit>();
        if (options != null) cubit.updateOptions(options!);
        final opts = cubit.options;
        final top = state.top;
        // ONE resolve per build, handed down.
        final rs = style.resolve(context);
        // A `show()` may name its own surface; otherwise the bag's.
        final surface = top?.options.style ?? rs.surface;

        // Is the app BLOCKED right now? Not just "is a scrim painted"
        // — a `topBar` never blocks, and a token can opt out.
        final blocking =
            state.visible &&
            (surface == LoadingSurface.scrim ||
                surface == LoadingSurface.dim) &&
            (top?.options.blockInput ?? true);

        // `blockInput` meant "block TAPS", which is one of the three
        // ways into this app.
        //
        //  - `ExcludeSemantics` takes the blocked UI out of the
        //    semantics tree. A scrim stops a finger and does nothing
        //    to a screen reader, so with VoiceOver or TalkBack you
        //    could swipe through every button under a modal "Saving…"
        //    and press them.
        //  - `Focus` stops traversal. `AbsorbPointer` is exactly what
        //    its name says: TAB still walked the blocked form and
        //    Enter still submitted it.
        //
        // Both are on the CONTENT, not on the overlay — the overlay is
        // that content's sibling in this Stack, so wrapping itself
        // would have blocked nothing.
        final blocked = blocking
            ? ExcludeSemantics(
                child: Focus(
                  canRequestFocus: false,
                  descendantsAreFocusable: false,
                  descendantsAreTraversable: false,
                  child: child,
                ),
              )
            : child;

        return PopScope(
          // And the third way in. A blocking save could be popped away
          // mid-flight: the token survives the route, and the overlay
          // comes back on a screen the reader has already left.
          canPop: !blocking,
          child: Stack(
            children: [
              Positioned.fill(child: blocked),
              // Top-bar variant — non-blocking, and it clears the
              // STATUS BAR. It used to be pinned to absolute zero so it
              // hugged the screen edge; with edge-to-edge on, three
              // pixels at y=0 are behind the clock, and a progress bar
              // nobody can see is not a progress bar. Desktop and web
              // have no inset, so they get the flush look regardless.
              if (state.visible && surface == LoadingSurface.topBar)
                Positioned(
                  left: 0,
                  right: 0,
                  top: rs.topBarClearsStatusBar
                      ? MediaQuery.paddingOf(context).top
                      : 0,
                  child: _TopBar(progress: top?.options.progress, rs: rs),
                ),
              // Scrim / dim variants — blocking
              if (state.visible &&
                  (surface == LoadingSurface.scrim ||
                      surface == LoadingSurface.dim))
                Positioned.fill(
                  child: _BlockingLayer(
                    options: opts,
                    state: state,
                    style: surface,
                    rs: rs,
                    top: top,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Blocking layer (scrim / dim)
// ─────────────────────────────────────────────────────────────

class _BlockingLayer extends StatelessWidget {
  const _BlockingLayer({
    required this.options,
    required this.state,
    required this.style,
    required this.top,
    required this.rs,
  });

  final LoadingOptions options;
  final LoadingState state;
  final LoadingSurface style;
  final LoadingToken? top;

  /// The resolved look, passed DOWN — one read per build.
  final ResolvedLoadingStyle rs;

  @override
  Widget build(BuildContext context) {
    final scrim = rs.scrimColor;
    final alpha = style == LoadingSurface.dim ? rs.dimOpacity : rs.scrimOpacity;
    final blockInput = top?.options.blockInput ?? true;

    // Background painted layer — scrim color + optional blur. Wraps
    // ONLY the painted area, not the centerpiece, so the centerpiece
    // (with its Cancel button) is free to receive taps even while
    // the rest of the screen is input-blocked.
    Widget background = AnimatedOpacity(
      opacity: state.visible ? 1.0 : 0.0,
      duration: rs.fadeDuration,
      child: ColoredBox(color: scrim.withValues(alpha: alpha)),
    );
    if (rs.enableBackdropBlur) {
      background = ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: rs.backdropBlurSigma,
            sigmaY: rs.backdropBlurSigma,
          ),
          child: background,
        ),
      );
    }
    // Wrap the BACKGROUND only with input rules. Cancel button sits
    // on top in a separate Stack child and stays interactive.
    if (!blockInput) {
      background = IgnorePointer(child: background);
    } else if (options.barrierDismissible) {
      background = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => top?.dispose(),
        child: background,
      );
    } else {
      background = AbsorbPointer(child: background);
    }

    final centerpiece = style == LoadingSurface.dim
        ? const SizedBox.shrink()
        : AnimatedOpacity(
            opacity: state.visible ? 1.0 : 0.0,
            duration: rs.fadeDuration,
            child: Center(
              child: _Centerpiece(options: options, top: top, rs: rs),
            ),
          );

    return Semantics(
      liveRegion: true,
      label: top?.options.label ?? CommonStrings.loading,
      excludeSemantics: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          background,
          if (style != LoadingSurface.dim) centerpiece,
        ],
      ),
    );
  }
}

class _Centerpiece extends StatelessWidget {
  const _Centerpiece({
    required this.options,
    required this.top,
    required this.rs,
  });

  final LoadingOptions options;
  final LoadingToken? top;
  final ResolvedLoadingStyle rs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perTokenSpinner = top?.options.spinner;
    final label = top?.options.label;
    final cancel = top?.options.cancellable;

    // Raw CircularProgressIndicator by DESIGN — this overlay is the
    // base loader beneath everything else, and core must not import
    // shared/module (GlobalProgress). Custom looks come in via
    // options.spinnerBuilder or the per-token spinner override.
    WidgetBuilder defaultSpinner = (ctx) => SizedBox(
      width: rs.spinnerSize,
      height: rs.spinnerSize,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(rs.spinnerColor),
      ),
    );
    if (rs.spinnerBuilder != null) {
      defaultSpinner = rs.spinnerBuilder!;
    }
    if (perTokenSpinner != null) {
      defaultSpinner = (_) => perTokenSpinner;
    }

    if (options.contentBuilder != null) {
      return options.contentBuilder!(
        context,
        label,
        cancel == null
            ? null
            : () {
                cancel();
                top?.dispose();
              },
        defaultSpinner,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  defaultSpinner(context),
                  if ((label ?? '').isNotEmpty) ...[
                    SizedBox(height: rs.labelGap),
                    Text(
                      label!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (cancel != null) ...[
              const SizedBox(height: 12),
              // House cancel action — localized label baked in. The
              // style override keeps the original floating-pill look
              // over the scrim (surface bg + pill radius).
              CancelButton(
                variant: CommonButtonVariant.tonal,
                shrinkWidth: true,
                onPressed: () {
                  cancel();
                  top?.dispose();
                },
                style: ButtonStateStyle(
                  backgroundColor: theme.colorScheme.surface.withValues(
                    alpha: 0.85,
                  ),
                  foregroundColor: theme.colorScheme.onSurface,
                  borderRadius: BorderRadius.circular(999),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top-bar variant (non-blocking)
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.rs, this.progress});

  final ResolvedLoadingStyle rs;

  /// When non-null, switches the bar from indeterminate sweep to a
  /// determinate fill driven by the listenable.
  final ValueListenable<double>? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (progress == null) {
      // Raw LinearProgressIndicator by DESIGN — base indeterminate
      // loader; core must not import shared/module (GlobalProgress).
      return SizedBox(
        height: rs.barHeight,
        child: LinearProgressIndicator(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(rs.spinnerColor),
          minHeight: rs.barHeight,
        ),
      );
    }
    return ValueListenableBuilder<double>(
      valueListenable: progress!,
      builder: (_, value, _) => _GlowingProgressBar(
        value: value.clamp(0.0, 1.0),
        color: rs.spinnerColor,
        trackColor: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

/// Determinate top bar with a glowing tip + leading marker. Used when
/// the caller passes [LoadingShowOptions.progress]. Slightly taller
/// than the indeterminate variant (8px reserved) so the glow has
/// vertical breathing room without clipping under the SafeArea.
class _GlowingProgressBar extends StatelessWidget {
  const _GlowingProgressBar({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    // Container height matches the bar exactly. The tip's halo paints
    // outside via `clipBehavior: Clip.none`, so the row reserves no
    // extra vertical space — the bar hugs the very top edge.
    return SizedBox(
      height: 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final fillWidth = (width * value).clamp(0.0, width);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Track ----------------------------------------------
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              // Fill -----------------------------------------------
              // Width comes straight from the caller's listenable —
              // no AnimatedContainer here, otherwise the fill lerps
              // on its own clock and the tip drifts ahead while the
              // bar catches up. Caller drives smoothness via the
              // CurvedAnimation passed to LoadingShowOptions.progress.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: fillWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.85),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 6,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
              // Tip glow + pointer (only when actually filled) -----
              // Centered on the bar's centerline (y=1.5). Tip is 12px
              // tall, so top = 1.5 - 6 = -4.5. Halo paints above and
              // below the row; `Clip.none` on the parent Stack lets
              // it through.
              if (value > 0.001)
                Positioned(
                  left: (fillWidth - 6).clamp(0.0, width),
                  top: -4.5,
                  child: IgnorePointer(
                    child: _Tip(color: color),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft outer glow halo -----------------------------------
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.55),
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Bright leading point — same height as the 3px line so
          // the tip reads as a continuation of the bar, not a floating
          // bead. Halo above keeps the glow visible.
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: color,
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
