import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/consent_strings.dart';
import '../../../module/checkbox/global_checkbox.dart';

/// The registration staple: "I agree to the **Terms of Service** and
/// **Privacy Policy**" with tappable link spans and must-accept
/// validation baked in (localized, en + ar). Wraps
/// [GlobalCheckboxFormField], so it participates in a `Form` with the
/// standard [ValidationMode] semantics.
///
/// The sentence assembles from whichever handlers are present:
/// both → "Terms and Privacy", terms only, or privacy only
/// ("I agree to the Privacy Policy"). At least one is required.
///
/// ```dart
/// ConsentCheckboxField(
///   onTermsTap: () => context.pushNamed('legal'),
///   onPrivacyTap: () => context.pushNamed('privacy'),
/// )
/// ```
class ConsentCheckboxField extends StatefulWidget {
  const ConsentCheckboxField({
    super.key,
    this.initialValue = false,
    this.onChanged,
    this.onTermsTap,
    this.onPrivacyTap,
    this.validation,
    this.style = const CheckboxStyle(),
    this.enabled = true,
    this.semanticLabel,
  }) : assert(
         onTermsTap != null || onPrivacyTap != null,
         'Provide onTermsTap and/or onPrivacyTap.',
       );

  /// Seeds the FormField ONCE (standard Flutter semantics).
  final bool initialValue;

  final ValueChanged<bool>? onChanged;

  /// Opens the terms document (route push / sheet / url). Null →
  /// privacy-only sentence.
  final VoidCallback? onTermsTap;

  /// Opens the privacy policy. Null → terms-only sentence.
  final VoidCallback? onPrivacyTap;

  /// Override the default must-accept rule (localized
  /// `ConsentStrings.required`, `onSubmit` mode).
  final CheckboxValidation<bool>? validation;

  final CheckboxStyle style;
  final bool enabled;
  final String? semanticLabel;

  @override
  State<ConsentCheckboxField> createState() => _ConsentCheckboxFieldState();
}

class _ConsentCheckboxFieldState extends State<ConsentCheckboxField> {
  // Recognizers must be disposed — they hold gesture-arena resources.
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => widget.onTermsTap?.call();
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => widget.onPrivacyTap?.call();
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  /// The sentence as flat text for semantics — same segment assembly
  /// as the rich label.
  String _plainSentence() {
    final b = StringBuffer(ConsentStrings.prefix);
    if (widget.onTermsTap != null) b.write(ConsentStrings.terms);
    if (widget.onTermsTap != null && widget.onPrivacyTap != null) {
      b.write(ConsentStrings.and);
    }
    if (widget.onPrivacyTap != null) b.write(ConsentStrings.privacy);
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Locale dependency — segments resolve via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    final base = context.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w500,
      color: widget.enabled ? null : context.textColors.disabled,
    );
    final link = base?.copyWith(
      color: context.textColors.link,
      decoration: TextDecoration.underline,
      decorationColor: context.textColors.link,
    );

    return GlobalCheckboxFormField(
      initialValue: widget.initialValue,
      onChanged: widget.onChanged,
      validation:
          widget.validation ??
          CheckboxValidation<bool>(
            validator: (v) => v == true ? null : ConsentStrings.required,
          ),
      style: widget.style,
      enabled: widget.enabled,
      semanticLabel: widget.semanticLabel ?? _plainSentence(),
      labelWidget: Text.rich(
        TextSpan(
          style: base,
          children: [
            TextSpan(text: ConsentStrings.prefix),
            if (widget.onTermsTap != null)
              TextSpan(
                text: ConsentStrings.terms,
                style: link,
                recognizer: _termsRecognizer,
              ),
            if (widget.onTermsTap != null && widget.onPrivacyTap != null)
              TextSpan(text: ConsentStrings.and),
            if (widget.onPrivacyTap != null)
              TextSpan(
                text: ConsentStrings.privacy,
                style: link,
                recognizer: _privacyRecognizer,
              ),
          ],
        ),
      ),
    );
  }
}
