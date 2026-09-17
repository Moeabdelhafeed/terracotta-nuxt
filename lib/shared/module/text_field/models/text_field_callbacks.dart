import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// TextFieldCallbacks
// ---------------------------------------------------------------------------

@immutable
class TextFieldCallbacks {
  const TextFieldCallbacks({
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onTapOutside,
    this.onObscureToggled,
  });

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final ValueChanged<PointerDownEvent>? onTapOutside;

  /// Fired whenever the obscure state flips (eye toggle, hold-to-reveal,
  /// reveal-timeout re-hide) with the NEW obscured value. Lets a composite
  /// (e.g. the OTP PIN cells) mirror one field's reveal onto its siblings.
  final ValueChanged<bool>? onObscureToggled;

  TextFieldCallbacks copyWith({
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onTap,
    ValueChanged<PointerDownEvent>? onTapOutside,
    ValueChanged<bool>? onObscureToggled,
  }) {
    return TextFieldCallbacks(
      onChanged: onChanged ?? this.onChanged,
      onSubmitted: onSubmitted ?? this.onSubmitted,
      onTap: onTap ?? this.onTap,
      onTapOutside: onTapOutside ?? this.onTapOutside,
      onObscureToggled: onObscureToggled ?? this.onObscureToggled,
    );
  }
}
