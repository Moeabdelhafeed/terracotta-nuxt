import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/faq_strings.dart';
import '../../../data/blocs/faq_history/faq_history_cubit.dart';
import '../../../data/blocs/faq_history/faq_history_state.dart';
import '../app_bar/global_app_bar.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_icon_button.dart';
import '../chip/global_chip.dart';
import '../divider/global_divider.dart';
import '../markdown/global_markdown.dart';
import '../scrollable/global_scrollable.dart';
import 'faq_models.dart';

/// Full-screen detail route for [FaqEntryVariant.detailRoute] +
/// deep-link target for `?id=xxx`. Renders the markdown answer +
/// feedback chips + optional "Contact support" CTA.
class FaqEntryDetailPage extends StatelessWidget {
  const FaqEntryDetailPage({
    super.key,
    required this.entry,
    this.onFeedback,
    this.onContactSupport,
  });

  final FaqEntry entry;
  final Future<void> Function(FaqEntry entry, FaqFeedback feedback)? onFeedback;
  final VoidCallback? onContactSupport;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = getIt<FaqHistoryCubit>();
    // Mark viewed once when the route mounts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cubit.markViewed(entry.id);
    });

    return Scaffold(
      appBar: GlobalAppBar.simple(entry.question),
      body: GlobalScrollable(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (entry.tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in entry.tags) GlobalChip.tag(label: tag),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (entry.lastUpdated != null) ...[
              Text(
                'Last updated ${_fmtDate(entry.lastUpdated!)}',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
            ],
            GlobalMarkdown(data: entry.answerMarkdown),
            const SizedBox(height: 24),
            _FeedbackBar(entry: entry, onFeedback: onFeedback),
            if (onContactSupport != null) ...[
              const SizedBox(height: 24),
              const GlobalDivider(),
              const SizedBox(height: 16),
              Text(
                FaqStrings.stillNeedHelp,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              GlobalFilledButton(
                text: CommonStrings.contactSupport,
                onPressed: onContactSupport,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';
}

/// "Was this helpful?" prompt — thumbs up/down with persisted state.
class _FeedbackBar extends StatelessWidget {
  const _FeedbackBar({required this.entry, this.onFeedback});

  final FaqEntry entry;
  final Future<void> Function(FaqEntry entry, FaqFeedback feedback)? onFeedback;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<FaqHistoryCubit, FaqHistoryState>(
      bloc: getIt<FaqHistoryCubit>(),
      builder: (context, state) {
        final current = getIt<FaqHistoryCubit>().feedbackFor(entry.id);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  current == null
                      ? FaqStrings.wasThisHelpful
                      : current == FaqFeedback.helpful
                      ? FaqStrings.thanksMarkedHelpful
                      : FaqStrings.thanksFeedbackRecorded,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GlobalIconButton(
                tooltip: FaqStrings.helpful,
                iconData: current == FaqFeedback.helpful
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_up_alt_outlined,
                isSelected: current == FaqFeedback.helpful,
                onPressed: () {
                  getIt<FaqHistoryCubit>().setFeedback(
                    entry.id,
                    FaqFeedback.helpful,
                  );
                  onFeedback?.call(entry, FaqFeedback.helpful);
                },
              ),
              GlobalIconButton(
                tooltip: FaqStrings.notHelpful,
                iconData: current == FaqFeedback.notHelpful
                    ? Icons.thumb_down_alt_rounded
                    : Icons.thumb_down_alt_outlined,
                isSelected: current == FaqFeedback.notHelpful,
                // Keep the error-role reading of a "not helpful" vote —
                // the built-in selected default is a primary tint.
                selectedStyle: ButtonStateStyle(
                  backgroundColor: Color.alphaBlend(
                    context.statusColors.error.withValues(alpha: 0.14),
                    context.backgroundColors.surface,
                  ),
                  foregroundColor: context.statusColors.error,
                ),
                onPressed: () {
                  getIt<FaqHistoryCubit>().setFeedback(
                    entry.id,
                    FaqFeedback.notHelpful,
                  );
                  onFeedback?.call(entry, FaqFeedback.notHelpful);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
