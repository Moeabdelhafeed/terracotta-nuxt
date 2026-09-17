import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Shortcut wrappers for [Semantics] — one-liner replacements for the
/// long-form `Semantics(...)` dance. Wrap any widget with a role and an
/// optional label / hint / custom actions, and screen readers will
/// announce it the way you'd expect.
///
/// ```dart
/// Icon(Icons.star).asImage(label: 'Favorite')
/// GestureDetector(onTap: ..., child: ...).asButton(label: 'Sign in', onTap: ...)
/// Text('Settings').asHeader()
/// counter.asLiveRegion()                         // re-announced on change
/// InkWell(onTap: launch, child: Text('Docs')).asLink(label: 'Open docs')
/// ```
///
/// Each helper returns a new [Widget] — they're non-mutating and safe to
/// chain (though usually one role is enough).
extension SemanticsX on Widget {
  /// Mark this widget as a button.
  ///
  /// Pass [onTap] to expose a tap action to screen readers (they'll
  /// announce "double tap to activate"). If your underlying widget
  /// already handles taps, you can leave [onTap] null — this extension
  /// only affects the a11y label, not actual gesture handling.
  Widget asButton({
    required String label,
    String? hint,
    String? value,
    VoidCallback? onTap,
    bool enabled = true,
  }) => Semantics(
    button: true,
    enabled: enabled,
    label: label,
    hint: hint,
    value: value,
    onTap: onTap,
    child: this,
  );

  /// Mark this widget as a tappable link.
  Widget asLink({required String label, String? hint, VoidCallback? onTap}) =>
      Semantics(
        link: true,
        label: label,
        hint: hint,
        onTap: onTap,
        child: this,
      );

  /// Mark this widget as a section header. TalkBack / VoiceOver expose a
  /// "next/previous header" gesture that jumps between these.
  Widget asHeader({String? label}) =>
      Semantics(header: true, label: label, child: this);

  /// Mark this widget as a non-decorative image. Without this, pure
  /// `Icon` / `Image` widgets announce as "image" with no context.
  Widget asImage({required String label, String? hint}) =>
      Semantics(image: true, label: label, hint: hint, child: this);

  /// Announce updates whenever this subtree's semantic value changes.
  /// Use for counters, status badges, toast-like inline messages.
  Widget asLiveRegion({bool enabled = true}) =>
      Semantics(liveRegion: enabled, child: this);

  /// Mark this as a text field. Pairs well with a custom input widget
  /// that doesn't extend [TextField] / [TextFormField] directly.
  Widget asTextField({
    String? label,
    String? hint,
    String? value,
    bool obscured = false,
    bool multiline = false,
  }) => Semantics(
    textField: true,
    obscured: obscured,
    multiline: multiline,
    label: label,
    hint: hint,
    value: value,
    child: this,
  );

  /// Mark this as a toggle (checkbox / switch). Pass [checked] so the
  /// state is announced correctly.
  Widget asToggle({
    required String label,
    required bool checked,
    String? hint,
    VoidCallback? onTap,
  }) => Semantics(
    toggled: checked,
    label: label,
    hint: hint,
    onTap: onTap,
    child: this,
  );

  /// Mark this as a single-selection item (radio button, segmented
  /// button). [selected] is announced as "selected" / "not selected".
  Widget asSelectable({
    required String label,
    required bool selected,
    String? hint,
    VoidCallback? onTap,
  }) => Semantics(
    selected: selected,
    label: label,
    hint: hint,
    onTap: onTap,
    child: this,
  );

  /// Mark this as a slider — pair with [value] as a user-readable string
  /// (`'40 percent'`) plus custom increase/decrease actions.
  Widget asSlider({
    required String label,
    required String value,
    String? increasedValue,
    String? decreasedValue,
    VoidCallback? onIncrease,
    VoidCallback? onDecrease,
    String? hint,
  }) {
    // Flutter asserts that a node which can be increased carries BOTH
    // `value` and `increasedValue` or neither, and it does so during
    // the semantics flush — a screen away from the widget that caused
    // it, once per frame, forever. The helper took the actions but had
    // nowhere to put the values, so its first caller with a keyboard
    // step produced a thousand-error storm on entering the page.
    assert(
      onIncrease == null || increasedValue != null,
      'asSlider: a slider that can be increased has to say what it '
      'would become — pass increasedValue beside onIncrease.',
    );
    assert(
      onDecrease == null || decreasedValue != null,
      'asSlider: a slider that can be decreased has to say what it '
      'would become — pass decreasedValue beside onDecrease.',
    );
    return Semantics(
      slider: true,
      label: label,
      value: value,
      increasedValue: increasedValue,
      decreasedValue: decreasedValue,
      hint: hint,
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      child: this,
    );
  }

  /// Hide this subtree from the accessibility tree. Use on purely
  /// decorative widgets (dividers, background images, duplicated icons
  /// next to a label).
  Widget excludeFromSemantics({bool excluding = true}) =>
      ExcludeSemantics(excluding: excluding, child: this);

  /// Drop all semantics produced by this subtree, then emit the given
  /// [label] / [hint] / [value] in its place. Useful when a complex
  /// composite widget has inner children you'd rather collapse into one
  /// announcement.
  Widget mergeSemantics({
    String? label,
    String? hint,
    String? value,
    bool button = false,
    bool header = false,
    VoidCallback? onTap,
  }) => Semantics(
    container: true,
    label: label,
    hint: hint,
    value: value,
    button: button,
    header: header,
    onTap: onTap,
    child: MergeSemantics(child: this),
  );

  /// Generic escape hatch — set any subset of semantic flags / actions
  /// without reaching for the full [Semantics] constructor.
  Widget semantics({
    String? label,
    String? hint,
    String? value,
    bool? button,
    bool? header,
    bool? image,
    bool? link,
    bool? textField,
    bool? readOnly,
    bool? enabled,
    bool? focused,
    bool? selected,
    bool? checked,
    bool? hidden,
    bool? liveRegion,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onIncrease,
    VoidCallback? onDecrease,
    TextDirection? textDirection,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: button,
      header: header,
      image: image,
      link: link,
      textField: textField,
      readOnly: readOnly,
      enabled: enabled,
      focused: focused,
      selected: selected,
      checked: checked,
      hidden: hidden,
      liveRegion: liveRegion,
      onTap: onTap,
      onLongPress: onLongPress,
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      textDirection: textDirection,
      child: this,
    );
  }
}

/// Announce [message] to assistive tech without any visible UI change.
/// Handy right after state transitions where there's no natural
/// live-region surface to update.
///
/// ```dart
/// await _saveDraft();
/// announceForAccessibility(context, 'Draft saved');
/// ```
void announceForAccessibility(
  BuildContext context,
  String message, {
  TextDirection? textDirection,
  Assertiveness assertiveness = Assertiveness.polite,
}) {
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    textDirection ?? Directionality.of(context),
    assertiveness: assertiveness,
  );
}
