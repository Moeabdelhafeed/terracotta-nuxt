import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/tokens/extensions.dart';
import '../../_shared/terracotta_widgets.dart';

/// A row in the account list — icon, label, chevron.
///
/// The chevron is `arrow_forward_rounded`, which Flutter mirrors with
/// the reading direction, so it points the way the customer is going in
/// both locales.
class ProfileRow extends StatelessWidget {
  const ProfileRow({
    required this.label,
    required this.icon,
    this.count,
    this.countTint,
    this.trailing,
    this.tint,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;

  /// HOW MANY are behind this row — «مفضلتي ٥».
  ///
  /// Null is UNKNOWN and draws nothing: the count has not arrived, or
  /// the call for it failed, and an invented zero would be a lie about
  /// the reader's own things. A real zero DOES draw, because "no
  /// orders yet" is worth reading before the page is opened.
  final int? count;

  /// The pill's colour. Null takes the row's own tint, which is the
  /// text colour — an unread badge passes the accent instead.
  final Color? countTint;

  final Widget? trailing;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? context.textColors.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.sm),
      child: TerracottaCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: context.iconSizes.md, color: color),
            SizedBox(width: context.spacing.md),
            Expanded(
              child: Text(
                label,
                style: context.textTheme.bodyLarge?.copyWith(color: color),
              ),
            ),
            if (count case final n?) ...[
              _CountPill(count: n, tint: countTint),
              SizedBox(width: context.spacing.sm),
            ],
            trailing ??
                Icon(
                  Icons.arrow_forward_rounded,
                  size: context.iconSizes.sm,
                  color: context.iconColors.primary,
                ),
          ],
        ),
      ),
    );
  }
}

/// A labelled section of account rows.
class ProfileSection extends StatelessWidget {
  const ProfileSection({required this.children, this.title, super.key});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (title != null) ...[
        SectionHeader(title: title!),
        SizedBox(height: context.spacing.sm),
      ],
      ...children,
      SizedBox(height: context.spacing.md),
    ],
  );
}

/// The number on a row. Reads as a quantity, not as an alert — a
/// tinted pill in the row's own ink, unless the caller names a colour.
///
/// Digits go through [AppNumbers.localizeDigits] like every other
/// number in the app: «٥», not "5", in the Arabic build.
class _CountPill extends StatelessWidget {
  const _CountPill({required this.count, this.tint});

  final int count;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? context.textColors.secondary;

    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: context.spacing.xs,
        vertical: 2,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.radii.full),
      ),
      child: Text(
        AppNumbers.localizeDigits('$count'),
        style: context.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
