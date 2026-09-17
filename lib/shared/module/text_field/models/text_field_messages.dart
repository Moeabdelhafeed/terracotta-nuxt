import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Field messages — multi-state notes shown below the field
// ---------------------------------------------------------------------------

/// Severity of a [FieldMessage]. Declared in display order — a field's active
/// messages render sorted by `index`: error → success → warning → info.
enum FieldMessageType { error, success, warning, info }

/// Entrance animation for the message rows (the validator error row and every
/// [FieldMessage]). Configured via `AnimationsConfig.messageAnimation`
/// (`features.animations`); replays whenever a row's text changes.
///
/// `typed` reveals the text character-by-character (custom `errorBuilder`
/// rows fall back to [fade] — arbitrary widgets can't be typewritten).
/// Reduced-motion (`MediaQuery.disableAnimations`) skips straight to the end.
enum FieldMessageAnimation { none, fade, slide, typed }

/// Which edge a [FieldMessageAnimation.slide] row enters from.
/// [start] / [end] resolve against the ambient [Directionality].
enum FieldMessageSlideFrom { start, end, top, bottom }

extension FieldMessageTypeX on FieldMessageType {
  /// Default leading icon when a message doesn't override it.
  IconData get defaultIcon => switch (this) {
    FieldMessageType.error => Icons.error_outline,
    FieldMessageType.success => Icons.check_circle_outline,
    FieldMessageType.warning => Icons.warning_amber_rounded,
    FieldMessageType.info => Icons.info_outline,
  };
}

/// A single status note under a [GlobalTextFormField]. Pass a list via
/// `GlobalTextFormField(messages: [...])`; multiple can be active at once and
/// stack in a column sorted by [FieldMessageType] (error, success, warning,
/// info). Each row tints its icon + text with the matching
/// `context.statusColors` role.
///
/// This is separate from validation: the validator's error still drives the
/// field border + the `InputDecoration` error slot. Use messages for extra
/// success / warning / info feedback (and caller-supplied notes).
@immutable
class FieldMessage {
  const FieldMessage(this.type, this.text, {this.icon});

  const FieldMessage.error(this.text, {this.icon})
    : type = FieldMessageType.error;
  const FieldMessage.success(this.text, {this.icon})
    : type = FieldMessageType.success;
  const FieldMessage.warning(this.text, {this.icon})
    : type = FieldMessageType.warning;
  const FieldMessage.info(this.text, {this.icon})
    : type = FieldMessageType.info;

  final FieldMessageType type;
  final String text;

  /// Overrides [FieldMessageTypeX.defaultIcon]. Pass `null` in the message to
  /// keep the default; there is no "no icon" option here — omit the message
  /// instead.
  final IconData? icon;
}
