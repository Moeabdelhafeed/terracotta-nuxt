import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'text_field_enums.dart';

// ---------------------------------------------------------------------------
// TextFieldBehavior — input behavior
// ---------------------------------------------------------------------------

@immutable
class TextFieldBehavior {
  const TextFieldBehavior({
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.revealed,
    this.enablePaste = true,
    this.enableCopy = true,
    this.trimOnSubmit = false,
    this.autoDetectDirection = true,
    this.textDirection,
    this.textAlign,
    this.inputMask,
    this.onChangedDelay = Duration.zero,
    this.showCounter = false,
    this.unfocusOnScroll = false,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.instantObscure = false,
    this.revealMode = TextFieldRevealMode.toggle,
    this.revealTimeout,
  });

  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;

  /// Whether this field is a PASSWORD field at all.
  ///
  /// It gates the visibility toggle, the instant-obscure path and the
  /// autofill hints — it is a declaration about the field, not a live
  /// state. Use [revealed] to say whether the text is currently shown.
  final bool obscureText;

  /// Whether the text is currently SHOWN, for a caller that wants to
  /// own that choice.
  ///
  /// Null leaves it to the module, which is right almost everywhere:
  /// the field starts hidden and its own eye flips it.
  ///
  /// Set it only to carry the reader's choice somewhere the module
  /// cannot see — across two screens, say. Turning [obscureText] off to
  /// achieve the same thing does NOT work: that says the field is not a
  /// password field, and takes the eye away with it.
  final bool? revealed;
  final bool enablePaste;
  final bool enableCopy;
  final bool trimOnSubmit;
  final bool autoDetectDirection;

  /// Pin the EDITOR's text direction regardless of the ambient locale —
  /// wins over [autoDetectDirection]. Structured LTR notations (dates,
  /// phone digits) set `TextDirection.ltr` so bidi can't visually
  /// reorder segments under an RTL locale. The hint keeps its own
  /// (ambient) direction.
  final TextDirection? textDirection;

  final TextAlign? textAlign;
  final String? inputMask;
  final Duration onChangedDelay;

  /// Show the built-in Material counter (`X/maxLength`). Independent of
  /// [CountersConfig.showCharCount] which renders a custom counter row.
  final bool showCounter;

  /// When `false` (default), scrolling the page — a pointer drag that
  /// moves past `kTouchSlop` before lifting — keeps the field focused;
  /// only a genuine tap outside dismisses focus. Set `true` for the
  /// legacy "any pointer-down outside unfocuses" behavior.
  final bool unfocusOnScroll;

  /// Platform autofill hints (e.g. `[AutofillHints.email]`,
  /// `[AutofillHints.password]`) — enables OS keychain / password-manager
  /// suggestions.
  final List<String>? autofillHints;

  /// Software-keyboard auto-capitalization (`words` for name fields,
  /// `sentences` for prose). Advisory — the OS keyboard applies it, no
  /// text is transformed.
  final TextCapitalization textCapitalization;

  /// Obscure INSTANTLY: never show the just-typed character (the platform
  /// default briefly reveals it). For screen-share / recording protection —
  /// see `ScreenCaptureService`. Only meaningful with [obscureText]; while
  /// active the field renders its own bullets (autocorrect + suggestions
  /// forced off).
  final bool instantObscure;

  /// How the visibility toggle reveals an [obscureText] field —
  /// tap-to-toggle (default) or press-and-hold.
  final TextFieldRevealMode revealMode;

  /// In [TextFieldRevealMode.toggle], auto re-obscure this long after a
  /// reveal (toggle or password-generate). Null → stays revealed until
  /// toggled back.
  final Duration? revealTimeout;

  TextFieldBehavior copyWith({
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    int? maxLines,
    int? minLines,
    bool? enabled,
    bool? readOnly,
    bool? autofocus,
    bool? obscureText,
    bool? revealed,
    bool? enablePaste,
    bool? enableCopy,
    bool? trimOnSubmit,
    bool? autoDetectDirection,
    TextDirection? textDirection,
    TextAlign? textAlign,
    String? inputMask,
    Duration? onChangedDelay,
    bool? showCounter,
    bool? unfocusOnScroll,
    List<String>? autofillHints,
    TextCapitalization? textCapitalization,
    bool? instantObscure,
    TextFieldRevealMode? revealMode,
    Duration? revealTimeout,
  }) {
    return TextFieldBehavior(
      keyboardType: keyboardType ?? this.keyboardType,
      textInputAction: textInputAction ?? this.textInputAction,
      inputFormatters: inputFormatters ?? this.inputFormatters,
      maxLength: maxLength ?? this.maxLength,
      maxLines: maxLines ?? this.maxLines,
      minLines: minLines ?? this.minLines,
      enabled: enabled ?? this.enabled,
      readOnly: readOnly ?? this.readOnly,
      autofocus: autofocus ?? this.autofocus,
      obscureText: obscureText ?? this.obscureText,
      revealed: revealed ?? this.revealed,
      enablePaste: enablePaste ?? this.enablePaste,
      enableCopy: enableCopy ?? this.enableCopy,
      trimOnSubmit: trimOnSubmit ?? this.trimOnSubmit,
      autoDetectDirection: autoDetectDirection ?? this.autoDetectDirection,
      textDirection: textDirection ?? this.textDirection,
      textAlign: textAlign ?? this.textAlign,
      inputMask: inputMask ?? this.inputMask,
      onChangedDelay: onChangedDelay ?? this.onChangedDelay,
      showCounter: showCounter ?? this.showCounter,
      unfocusOnScroll: unfocusOnScroll ?? this.unfocusOnScroll,
      autofillHints: autofillHints ?? this.autofillHints,
      textCapitalization: textCapitalization ?? this.textCapitalization,
      instantObscure: instantObscure ?? this.instantObscure,
      revealMode: revealMode ?? this.revealMode,
      revealTimeout: revealTimeout ?? this.revealTimeout,
    );
  }
}
