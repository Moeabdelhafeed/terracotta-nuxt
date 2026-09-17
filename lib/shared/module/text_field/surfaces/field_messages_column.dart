import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/tokens/extensions.dart';
import '../models/text_field_defaults.dart';
import '../models/text_field_messages.dart';

/// Standalone [FieldMessage] column — the same icon + status-color row
/// treatment the text field renders below itself, as a public widget for
/// surfaces that AREN'T a `GlobalTextFormField` (the dropdown's chip
/// trigger, custom composites).
///
/// Rows render sorted error → success → warning → info regardless of
/// list order; [errorText] (when non-null) is folded in as the leading
/// error row. Collapses to nothing when there is nothing to show.
class FieldMessagesColumn extends StatelessWidget {
  const FieldMessagesColumn({
    super.key,
    this.messages = const [],
    this.errorText,
  });

  final List<FieldMessage> messages;

  /// Validator/external error — rendered as the first error row.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final err = errorText;
    if (err == null && messages.isEmpty) return const SizedBox.shrink();

    final status = context.statusColors;
    Color colorFor(FieldMessageType t) => switch (t) {
      FieldMessageType.error => status.error,
      FieldMessageType.success => status.success,
      FieldMessageType.warning => status.warning,
      FieldMessageType.info => status.info,
    };

    Widget row(IconData icon, String text, Color color) => Padding(
      padding: EdgeInsets.only(top: context.spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Icon(
              icon,
              size: TextFieldDefaults.messageIconSize,
              color: color,
            ),
          ),
          SizedBox(width: context.spacing.xs),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (err != null)
          row(FieldMessageType.error.defaultIcon, err, status.error),
        for (final type in FieldMessageType.values)
          for (final m in messages.where((m) => m.type == type))
            row(m.icon ?? type.defaultIcon, m.text, colorFor(type)),
      ],
    );
  }
}
