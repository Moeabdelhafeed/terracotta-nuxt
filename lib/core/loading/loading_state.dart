import 'package:flutter/foundation.dart';

import 'loading_token.dart';

/// Snapshot of the loading stack at any moment.
///
/// The overlay reads `visible` (whether to render anything at all)
/// and `top` (the topmost active token, used to pick label / spinner
/// / style / cancel callback). Active count drives a small badge in
/// the showcase / debug.
@immutable
class LoadingState {
  const LoadingState({
    this.visible = false,
    this.tokens = const [],
  });

  /// Whether the overlay is rendered. Lags behind [tokens] thanks to
  /// `appearAfter` (debounce) and `minVisible` (anti-flicker).
  final bool visible;

  /// Active tokens in show-order. The newest is at the end.
  final List<LoadingToken> tokens;

  /// Topmost token — its options drive the rendered UI.
  LoadingToken? get top => tokens.isEmpty ? null : tokens.last;

  int get count => tokens.length;
  bool get hasTokens => tokens.isNotEmpty;

  LoadingState copyWith({
    bool? visible,
    List<LoadingToken>? tokens,
  }) {
    return LoadingState(
      visible: visible ?? this.visible,
      tokens: tokens ?? this.tokens,
    );
  }
}
