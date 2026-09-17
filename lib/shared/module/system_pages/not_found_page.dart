import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/a11y/semantics_extensions.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/nav_strings.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/tokens/extensions.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_outlined_button.dart';
import '../buttons/global_text_button.dart';
import '../container/global_container.dart';
import '../scrollable/global_scrollable.dart';
import '../toast/global_toast.dart';
import 'system_page_parts.dart';

/// Themed 404 page. Used both as a standalone route (`/not-found`)
/// and as the GoRouter `errorBuilder` fallback.
///
/// [path] is the missing route. Shown as a chip and copyable for
/// support tickets — it is `matchedLocation`, so it carries no query
/// string and nothing sensitive.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({this.path, super.key});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final btn = context.buttonsColors;
    final spacing = context.spacing;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final hasPath = (path ?? '').isNotEmpty;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: SystemPageAppBar(title: NavStrings.pageNotFound),
      body: SafeArea(
        child: GlobalContainer.prose(
          child: Center(
            // Scrollable: the block is tall, and at the 1.4 text-scale
            // ceiling (or in landscape) a fixed Column overflowed.
            child: GlobalScrollable(
              padding: EdgeInsets.all(spacing.lg),
              child: SystemPageEntrance(
                enabled: !reduceMotion,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SystemPageBadge(
                      icon: Icons.travel_explore_rounded,
                      color: btn.primary,
                    ),
                    SizedBox(height: spacing.lg),
                    // "404" and the title say the same thing — announce
                    // them as ONE heading instead of two fragments.
                    MergeSemantics(
                      child: Column(
                        children: [
                          Text(
                            '404',
                            style: context.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: tx.primary,
                              letterSpacing: -2,
                              height: 1,
                            ),
                          ),
                          SizedBox(height: spacing.sm),
                          Text(
                            NavStrings.pageNotFound,
                            textAlign: TextAlign.center,
                            style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: tx.primary,
                            ),
                          ),
                        ],
                      ),
                    ).asHeader(),
                    SizedBox(height: spacing.sm),
                    Text(
                      NavStrings.pageNotFoundBody,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: tx.secondary,
                      ),
                    ),
                    if (hasPath) ...[
                      SizedBox(height: spacing.md),
                      _PathChip(path: path!),
                    ],
                    SizedBox(height: spacing.lg + spacing.xs),
                    // Primary action carries full width on its own; the
                    // secondary pair shares a row. Three equal-weight
                    // full-width bars read as three primary choices.
                    GlobalFilledButton(
                      text: NavStrings.goHome,
                      onPressed: () => context.go(AppRoutes.splash.path),
                      icon: Icons.home_rounded,
                    ),
                    if (canPop || hasPath) ...[
                      SizedBox(height: spacing.sm + spacing.xs),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: spacing.sm + spacing.xs,
                        runSpacing: spacing.sm,
                        children: [
                          if (canPop)
                            GlobalOutlinedButton(
                              text: NavStrings.goBack,
                              onPressed: () => Navigator.of(context).pop(),
                              shrinkWidth: true,
                              // Back points the other way in RTL.
                              icon: isRtl
                                  ? Icons.arrow_forward_rounded
                                  : Icons.arrow_back_rounded,
                            ),
                          // Only offered when there IS a path to copy —
                          // the handler used to no-op silently otherwise.
                          if (hasPath)
                            GlobalTextButton(
                              text: NavStrings.copyUrl,
                              onPressed: () => _copyPath(context),
                              shrinkWidth: true,
                              icon: Icons.copy_rounded,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyPath(BuildContext context) async {
    if ((path ?? '').isEmpty) return;
    await Clipboard.setData(ClipboardData(text: path!));
    if (!context.mounted) return;
    GlobalToast.success(NavStrings.pathCopied);
  }
}

class _PathChip extends StatelessWidget {
  const _PathChip({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final bg = context.backgroundColors;
    final tx = context.textColors;
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm + spacing.xs,
        vertical: spacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bg.outlineVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(context.radii.full),
        border: Border.all(color: bg.outlineVariant),
      ),
      // Selectable so the path can be grabbed on web/desktop where the
      // copy button is less discoverable than a drag-select.
      child: SelectableText(
        path,
        style: context.textTheme.labelSmall?.copyWith(
          color: tx.secondary,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
