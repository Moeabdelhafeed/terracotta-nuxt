// Dart imports:
import 'dart:async';
import 'dart:math' show sin;
import 'dart:ui' show ImageFilter;

// Flutter imports:
import 'package:flutter/foundation.dart' show kDebugMode, listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/a11y/semantics_extensions.dart';
import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/bidi.dart';
import '../../../core/localization/strings/text_field_strings.dart';
import '../../../core/localization/tr.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/utils/loggers/logger.dart';
import '../../../core/utils/password_generator.dart';
import '../../../shared/module/dialog/global_dialog.dart';
import '../../../shared/module/popup/popup.dart';
import '../buttons/global_icon_button.dart';
import '../chip/global_chip.dart';
import '../divider/global_divider.dart';
import '../image/index.dart';
import '../progress/global_progress.dart';
import '../scrollable/global_edge_fade.dart';
import '../scrollable/scrollable_style.dart' show EdgeFadeStyle;
import 'controller/caret_watchdog.dart';
import 'controller/field_validation_controller.dart';
import 'controller/inline_ghost_controller.dart';
import 'controller/instant_obscure_controller.dart';
import 'controller/suggestion_filter.dart';
import 'controller/undo_redo_stack.dart';
import 'input_formatters/text_field_input_formatters.dart';
import 'models/text_field_models.dart';

export 'input_formatters/text_field_input_formatters.dart';
export 'models/text_field_models.dart';
export 'surfaces/color_preview.dart';
export 'surfaces/field_messages_column.dart';

part 'controller/text_field_state.dart';
part 'controller/text_field_state_features.dart';
part 'surfaces/text_field_state_panels.dart';

// ---------------------------------------------------------------------------
// GlobalTextFormField
// ---------------------------------------------------------------------------

/// Composable text input. State + behaviour grouped into eight configs:
///
/// * [TextFieldStyle] — colors, radius, height, blur, border
/// * [TextFieldBehavior] — keyboard, formatters, mask, RTL, debounce
/// * [TextFieldValidation] — mode, validator, requirements, strength bar
/// * [TextFieldFeatures] — suggestions, chips, voice, undo/redo, counters,
///   animations, clear button, success state, loading suffix
/// * [TextFieldSlots] — prefix/suffix icon/text/widget, info label
/// * [TextFieldCallbacks] — onChanged, onSubmitted, onTap, onTapOutside
/// * [TextFieldSizing] — height/width constraints, density flags,
///   fit-width-to-content
/// * [FieldMessage] list ([messages]) — extra success / warning / info /
///   error notes stacked under the field
///
/// For purpose-shaped fields (email, password, phone, OTP, card, …) use the
/// app-owned wrappers in `lib/shared/common/text_form_fields/` — each composes
/// these configs for a common shape. For custom needs, instantiate directly:
///
/// ```dart
/// GlobalTextFormField(
///   controller: c,
///   hint: 'Email',
///   style: TextFieldStyle(border: TextFieldBorderStyle(base: TextFieldBorderSide(color: Colors.purple))),
///   behavior: const TextFieldBehavior(keyboardType: TextInputType.emailAddress),
///   validation: TextFieldValidation(validator: Validators.validateEmail),
/// );
/// ```
class GlobalTextFormField extends StatefulWidget {
  const GlobalTextFormField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.identifier,
    this.required = false,
    this.focusNode,
    this.style = const TextFieldStyle(),
    this.behavior = const TextFieldBehavior(),
    this.validation = const TextFieldValidation(),
    this.features = const TextFieldFeatures(),
    this.slots = const TextFieldSlots(),
    this.callbacks = const TextFieldCallbacks(),
    this.sizing = const TextFieldSizing(),
    this.messages = const [],
  });

  // ─── Core identity ─────────────────────────────────────────
  final TextEditingController controller;
  final String hint;

  /// Inline label inside the field (Material floating label when
  /// [AnimationsConfig.floatingLabel] is true).
  final String? label;

  /// Fallback for [label] — NOT a header.
  ///
  /// It reads as one because it used to be one, but nothing renders it
  /// above the field: its only effects are standing in for [label] as
  /// the floating label INSIDE the box when `floatingLabel` is on, and
  /// deciding where the `required` star goes. A caller wanting a static
  /// header above the field has to draw it.
  final String? identifier;

  /// Marks the field required — appends a `*` to the [hint] inside the
  /// field when there is no [identifier] to carry it.
  /// Purely a visual affordance; the actual rule stays in the validator.
  final bool required;

  final FocusNode? focusNode;

  // ─── Grouped configs ───────────────────────────────────────
  final TextFieldStyle style;
  final TextFieldBehavior behavior;
  final TextFieldValidation validation;
  final TextFieldFeatures features;
  final TextFieldSlots slots;
  final TextFieldCallbacks callbacks;

  /// Box geometry — height / width constraints + the Material density flags
  /// (`isDense` / `isCollapsed`) that make them take effect. See
  /// [TextFieldSizing].
  final TextFieldSizing sizing;

  /// Extra status notes shown under the field — success / warning / info (and
  /// error). Multiple stack in a column sorted by [FieldMessageType]. Separate
  /// from validation (the validator still drives the border + error slot). See
  /// [FieldMessage].
  final List<FieldMessage> messages;

  @override
  State<GlobalTextFormField> createState() => _GlobalTextFormFieldState();
}
