import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Suffix sealed union
// ---------------------------------------------------------------------------

/// Trailing area of the field. Choose one explicitly via [TextFieldSlots.suffix],
/// or leave null to let the widget compose from features
/// (obscure toggle → clear → voice).
sealed class TextFieldSuffix {
  const TextFieldSuffix();

  /// Spinner — overrides everything else.
  const factory TextFieldSuffix.loading() = SuffixLoading;

  /// Material icon. [onTap] makes it tappable.
  const factory TextFieldSuffix.icon(IconData icon, {VoidCallback? onTap}) =
      SuffixIcon;

  /// Asset image (resolved via `GlobalImage.a(path)`).
  const factory TextFieldSuffix.asset(String path) = SuffixAsset;

  /// Caller-supplied widget.
  const factory TextFieldSuffix.widget(Widget child) = SuffixWidget;
}

class SuffixLoading extends TextFieldSuffix {
  const SuffixLoading();
}

class SuffixIcon extends TextFieldSuffix {
  const SuffixIcon(this.icon, {this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
}

class SuffixAsset extends TextFieldSuffix {
  const SuffixAsset(this.path);
  final String path;
}

class SuffixWidget extends TextFieldSuffix {
  const SuffixWidget(this.child);
  final Widget child;
}

// ---------------------------------------------------------------------------
// TextFieldSlots — prefix/suffix/info
// ---------------------------------------------------------------------------

@immutable
class TextFieldSlots {
  const TextFieldSlots({
    this.prefixIcon,
    this.suffix,
    this.prefixText,
    this.suffixText,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.infoLabel,
    this.onInfoLabelTap,
  });

  final Widget? prefixIcon;
  final TextFieldSuffix? suffix;
  final String? prefixText;
  final String? suffixText;

  /// Constraints for the [prefixIcon] box. **Null → size-to-content** (the
  /// field drops Material's 48×48 minimum so the slot hugs the child instead
  /// of inflating + centering it). Pass an explicit min — e.g.
  /// `BoxConstraints(minWidth: 48, minHeight: 48)` — to restore a fixed tap
  /// target. Wrap the child in `Padding` for a gap from the input.
  final BoxConstraints? prefixIconConstraints;

  /// Counterpart to [prefixIconConstraints] for the suffix box. Same
  /// size-to-content default.
  final BoxConstraints? suffixIconConstraints;

  /// Info icon button shown next to the identifier header. Tap = [onInfoLabelTap].
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;

  TextFieldSlots copyWith({
    Widget? prefixIcon,
    TextFieldSuffix? suffix,
    String? prefixText,
    String? suffixText,
    BoxConstraints? prefixIconConstraints,
    BoxConstraints? suffixIconConstraints,
    String? infoLabel,
    VoidCallback? onInfoLabelTap,
  }) {
    return TextFieldSlots(
      prefixIcon: prefixIcon ?? this.prefixIcon,
      suffix: suffix ?? this.suffix,
      prefixText: prefixText ?? this.prefixText,
      suffixText: suffixText ?? this.suffixText,
      prefixIconConstraints:
          prefixIconConstraints ?? this.prefixIconConstraints,
      suffixIconConstraints:
          suffixIconConstraints ?? this.suffixIconConstraints,
      infoLabel: infoLabel ?? this.infoLabel,
      onInfoLabelTap: onInfoLabelTap ?? this.onInfoLabelTap,
    );
  }
}
