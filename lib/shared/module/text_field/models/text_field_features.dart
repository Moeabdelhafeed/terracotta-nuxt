import 'package:flutter/material.dart';

import 'text_field_suggestions.dart';

/// Maximum entries kept in the undo / redo history stacks.
const kTextFieldMaxUndoStackSize = 50;

// ---------------------------------------------------------------------------
// TextFieldFeatures — optional add-ons
// ---------------------------------------------------------------------------

@immutable
class TextFieldFeatures {
  const TextFieldFeatures({
    this.suggestions,
    this.chips,
    this.voice,
    this.enableUndoRedo = false,
    this.counters = const CountersConfig(),
    this.animations = const AnimationsConfig(),
    this.showClearButton = false,
    this.onClear,
    this.successText,
    this.showSuccess = false,
    this.suffixLoading = false,
    this.showObscureToggle = true,
    this.showPasswordGenerate = false,
    this.passwordGenerator,
    this.onPasswordGenerated,
    this.warnCapsLock = false,
  });

  final SuggestionsConfig? suggestions;
  final ChipsConfig? chips;
  final VoiceInputConfig? voice;
  final bool enableUndoRedo;
  final CountersConfig counters;
  final AnimationsConfig animations;
  final bool showClearButton;
  final VoidCallback? onClear;
  final String? successText;
  final bool showSuccess;
  final bool suffixLoading;

  /// Show the visibility (eye) toggle on obscured fields. Off for obscured
  /// inputs that shouldn't offer a reveal — PIN cells, where only the last
  /// cell (or none) carries the toggle.
  final bool showObscureToggle;

  /// Show a generate button next to the visibility toggle on obscured
  /// fields. Tapping fills the field via [passwordGenerator] (default:
  /// `PasswordGenerator.generate`), reveals the result (unless the screen
  /// is being captured) and fires `onChanged` + validation.
  final bool showPasswordGenerate;

  /// Custom generator for [showPasswordGenerate].
  final String Function()? passwordGenerator;

  /// Fired with the generated password after the generate button fills the
  /// field — e.g. to also fill a linked confirm field.
  final ValueChanged<String>? onPasswordGenerated;

  /// Show a warning message row while the field is focused and Caps Lock is
  /// on (hardware keyboards — desktop / web / tablets with keyboards).
  final bool warnCapsLock;

  TextFieldFeatures copyWith({
    SuggestionsConfig? suggestions,
    ChipsConfig? chips,
    VoiceInputConfig? voice,
    bool? enableUndoRedo,
    CountersConfig? counters,
    AnimationsConfig? animations,
    bool? showClearButton,
    VoidCallback? onClear,
    String? successText,
    bool? showSuccess,
    bool? suffixLoading,
    bool? showObscureToggle,
    bool? showPasswordGenerate,
    String Function()? passwordGenerator,
    ValueChanged<String>? onPasswordGenerated,
    bool? warnCapsLock,
  }) {
    return TextFieldFeatures(
      suggestions: suggestions ?? this.suggestions,
      chips: chips ?? this.chips,
      voice: voice ?? this.voice,
      enableUndoRedo: enableUndoRedo ?? this.enableUndoRedo,
      counters: counters ?? this.counters,
      animations: animations ?? this.animations,
      showClearButton: showClearButton ?? this.showClearButton,
      onClear: onClear ?? this.onClear,
      successText: successText ?? this.successText,
      showSuccess: showSuccess ?? this.showSuccess,
      suffixLoading: suffixLoading ?? this.suffixLoading,
      showObscureToggle: showObscureToggle ?? this.showObscureToggle,
      showPasswordGenerate: showPasswordGenerate ?? this.showPasswordGenerate,
      passwordGenerator: passwordGenerator ?? this.passwordGenerator,
      onPasswordGenerated: onPasswordGenerated ?? this.onPasswordGenerated,
      warnCapsLock: warnCapsLock ?? this.warnCapsLock,
    );
  }
}
