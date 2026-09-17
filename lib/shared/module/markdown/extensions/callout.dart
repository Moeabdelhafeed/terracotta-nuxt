import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';

/// GitHub-style callout types: `> [!info]`, `> [!warning]`, `[!tip]`,
/// `[!danger]`, `[!note]`. The body of the blockquote is rendered as
/// the callout content.
enum CalloutType {
  info,
  warning,
  tip,
  danger,
  note;

  static CalloutType? fromTag(String raw) {
    final t = raw.toLowerCase();
    for (final v in CalloutType.values) {
      if (v.name == t) return v;
    }
    return null;
  }
}

/// Detects whether [text] starts with a `[!type]` GitHub callout tag.
/// Returns the matched type plus the body string (with the tag line
/// stripped). Returns null when no tag is found.
({CalloutType type, String body})? detectCallout(String text) {
  final firstLine = text.split('\n').first.trim();
  final pattern = RegExp(r'^\[!(\w+)\]\s*$');
  final m = pattern.firstMatch(firstLine);
  if (m == null) return null;
  final type = CalloutType.fromTag(m.group(1)!);
  if (type == null) return null;
  final body = text.substring(text.indexOf('\n') + 1).trim();
  return (type: type, body: body);
}

/// Default styled callout. Caller can override via
/// [MarkdownOptions.calloutBuilder].
class MarkdownCallout extends StatelessWidget {
  const MarkdownCallout({
    required this.type,
    required this.child,
    super.key,
  });

  final CalloutType type;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final st = context.statusColors;
    final tx = context.textColors;
    final bg = context.backgroundColors;

    final palette = switch (type) {
      CalloutType.info => _CalloutPalette(
        bar: st.info,
        icon: Icons.info_outline_rounded,
        label: 'Info',
      ),
      CalloutType.warning => _CalloutPalette(
        bar: st.warning,
        icon: Icons.warning_amber_rounded,
        label: 'Warning',
      ),
      CalloutType.tip => _CalloutPalette(
        bar: st.success,
        icon: Icons.lightbulb_outline_rounded,
        label: 'Tip',
      ),
      CalloutType.danger => _CalloutPalette(
        bar: st.error,
        icon: Icons.error_outline_rounded,
        label: 'Danger',
      ),
      CalloutType.note => _CalloutPalette(
        bar: tx.secondary,
        icon: Icons.sticky_note_2_outlined,
        label: 'Note',
      ),
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg.outlineVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: palette.bar, width: 3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(palette.icon, size: 16, color: palette.bar),
              const SizedBox(width: 6),
              Text(
                palette.label,
                style: TextStyle(
                  color: palette.bar,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          DefaultTextStyle.merge(
            style: TextStyle(color: tx.primary, fontSize: 14, height: 1.5),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _CalloutPalette {
  const _CalloutPalette({
    required this.bar,
    required this.icon,
    required this.label,
  });
  final Color bar;
  final IconData icon;
  final String label;
}
