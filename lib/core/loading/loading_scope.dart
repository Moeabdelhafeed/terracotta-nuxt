import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'loading_cubit.dart';
import 'loading_options.dart';
import 'loading_state.dart';
import 'loading_style.dart';
import 'loading_token.dart';
import 'theme/loading_theme.dart';

/// Per-subtree loading scope. Use when the global overlay would feel
/// too heavy for a localized async op (single page, single section).
///
/// Provides its own [LoadingCubit] (independent from the global one)
/// and renders the same overlay UI scoped to [child]'s box.
///
/// ```dart
/// LoadingScope(
///   child: MyForm(),
///   options: const LoadingOptions(defaultStyle: LoadingSurface.dim),
///   builder: (ctx, scope, child) => Stack(
///     children: [
///       child,
///       if (scope.isVisible) const Center(child: CircularProgressIndicator()),
///     ],
///   ),
/// )
/// ```
///
/// Most callers don't need [builder] — pass [child] alone and the
/// default centered scrim is rendered.
class LoadingScope extends StatefulWidget {
  const LoadingScope({
    required this.child,
    this.options = const LoadingOptions(),
    this.style = const LoadingStyle(),
    this.builder,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final LoadingOptions options;

  /// How it LOOKS — the same bag the fullscreen overlay takes.
  final LoadingStyle style;

  /// Clips the overlay to match a rounded container behind it. When
  /// the [child] is wrapped in a `Container` / `ClipRRect` with
  /// rounded corners, pass the same radius so the scrim doesn't
  /// spill into the corners. Null = no clipping.
  final BorderRadius? borderRadius;

  /// Total override for the rendered tree. Receives the scoped cubit
  /// so the caller can read state directly. When null, the default
  /// scrim layout from [LoadingOverlay] is reused.
  final Widget Function(
    BuildContext context,
    LoadingCubit scoped,
    Widget child,
  )?
  builder;

  /// Read the scoped cubit from anywhere inside the scope.
  static LoadingCubit of(BuildContext context) {
    return context.read<LoadingCubit>();
  }

  @override
  State<LoadingScope> createState() => _LoadingScopeState();
}

class _LoadingScopeState extends State<LoadingScope> {
  late final LoadingCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = LoadingCubit(options: widget.options);
  }

  @override
  void didUpdateWidget(LoadingScope old) {
    super.didUpdateWidget(old);
    if (widget.options != old.options) {
      _cubit.updateOptions(widget.options);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoadingCubit>.value(
      value: _cubit,
      child: BlocBuilder<LoadingCubit, LoadingState>(
        builder: (context, state) {
          if (widget.builder != null) {
            return widget.builder!(context, _cubit, widget.child);
          }
          // The scope wears the SAME bag as the fullscreen overlay —
          // a scoped loader that scrims a card differently from the
          // one that scrims the app is two loading states in one
          // product.
          final rs = widget.style.resolve(context);
          final overlay = ColoredBox(
            color: rs.scrimColor.withValues(alpha: rs.backdropOpacity),
            child: Center(child: _ScopedSpinner(rs: rs)),
          );
          return Stack(
            children: [
              widget.child,
              if (state.visible)
                Positioned.fill(
                  child: widget.borderRadius == null
                      ? overlay
                      : ClipRRect(
                          borderRadius: widget.borderRadius!,
                          child: overlay,
                        ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ScopedSpinner extends StatelessWidget {
  const _ScopedSpinner({required this.rs});

  final ResolvedLoadingStyle rs;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LoadingCubit>().state;
    final top = state.top;
    // Raw CircularProgressIndicator by DESIGN — base fallback loader;
    // core must not import shared/module (GlobalProgress). Pass
    // options.spinnerBuilder / a per-token spinner for custom looks.
    final builder = top?.options.spinner != null
        ? (_) => top!.options.spinner!
        : rs.spinnerBuilder ??
              (ctx) => SizedBox(
                width: rs.spinnerSize,
                height: rs.spinnerSize,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(rs.spinnerColor),
                ),
              );
    return Builder(builder: builder);
  }
}

extension LoadingTokenScope on LoadingScope {
  /// Sugar for `LoadingScope.of(context).show(...)`.
  static LoadingToken show(
    BuildContext context, {
    String? label,
  }) {
    return LoadingScope.of(context).show();
  }
}
