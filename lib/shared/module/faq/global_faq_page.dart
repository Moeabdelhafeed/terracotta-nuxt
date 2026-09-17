import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/faq_strings.dart';
import '../../../core/navigation/transitions/route_transition.dart';
import '../../../data/blocs/faq_history/faq_history_cubit.dart';
import '../../../data/blocs/faq_history/faq_history_state.dart';
import '../../../data/repositories/faq/faq_repository.dart';
import '../../common/buttons/buttons.dart';
import '../../common/text_form_fields/text_form_fields.dart';
import '../app_bar/global_app_bar.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_icon_button.dart';
import '../chip/global_chip.dart';
import '../container/global_container.dart';
import '../markdown/global_markdown.dart';
import '../refreshable/global_refreshable.dart';
import '../scrollable/global_scrollable.dart';
import '../sheet/global_sheet.dart';
import '../text/global_text.dart';
import 'faq_entry_detail_page.dart';
import 'faq_models.dart';

export '../../../data/repositories/faq/faq_repository.dart';
export 'faq_entry_detail_page.dart';
export 'faq_models.dart';

/// Help center / FAQ surface. Drives a [FaqRepository] (typically
/// [TieredFaqRepository] for API → RC → static fallback). Renders:
///   * search bar (search-icon prefix + clear suffix)
///   * category chip-filter row + "Recent" + "All" chips
///   * scrollable list of entries — variant decides how the answer
///     opens (`accordion`, `detailRoute`, `bottomSheet`)
///   * pull-to-refresh + skeleton loader + error/empty banners
///   * persisted recently-viewed (via [FaqHistoryCubit])
///   * optional thumbs-up/down feedback (persisted + callback)
///   * optional contact-support CTA below the list
///   * deep-link target — pass `initialEntryId` to auto-open an
///     entry once data loads (typical use: `?id=xxx` from GoRouter)
class GlobalFaqPage extends StatefulWidget {
  const GlobalFaqPage({
    super.key,
    required this.repository,
    this.title,
    this.variant = FaqEntryVariant.accordion,
    this.initialEntryId,
    this.onFeedback,
    this.onContactSupport,
    this.includeAllChip = true,
    this.includeRecentChip = true,
    this.background,
    this.appBar,
  });

  final FaqRepository repository;
  final String? title;
  final FaqEntryVariant variant;

  /// Auto-opens this entry once the data loads (deep-link target).
  final String? initialEntryId;

  /// Fires when the user submits thumbs up/down. Local state is
  /// persisted via [FaqHistoryCubit] either way — this callback is
  /// for reporting back to your analytics / API.
  final Future<void> Function(FaqEntry entry, FaqFeedback feedback)? onFeedback;

  /// Shown at the bottom of the list. Typical wire: open email
  /// composer, push a contact form route, or show a chat.
  final VoidCallback? onContactSupport;

  final bool includeAllChip;
  final bool includeRecentChip;

  final Color? background;

  /// Override the default Scaffold appbar. Set to null + this page
  /// embeds without a Scaffold — caller wraps it.
  final PreferredSizeWidget? appBar;

  @override
  State<GlobalFaqPage> createState() => _GlobalFaqPageState();
}

class _GlobalFaqPageState extends State<GlobalFaqPage> {
  late Future<FaqData> _future;
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _selectedCategory = '__all__';
  bool _autoOpened = false;

  static const _allId = '__all__';
  static const _recentId = '__recent__';

  @override
  void initState() {
    super.initState();
    _future = widget.repository.load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.repository.load();
    });
    await _future;
  }

  List<FaqEntry> _filter(FaqData data, List<String> recent) {
    final lowerQ = _query.trim().toLowerCase();
    bool matchQuery(FaqEntry e) {
      if (lowerQ.isEmpty) return true;
      return e.question.toLowerCase().contains(lowerQ) ||
          e.answerMarkdown.toLowerCase().contains(lowerQ) ||
          e.tags.any((t) => t.toLowerCase().contains(lowerQ));
    }

    var filtered = data.entries.where(matchQuery);

    if (_selectedCategory == _allId) {
      // pass through
    } else if (_selectedCategory == _recentId) {
      final order = {for (var i = 0; i < recent.length; i++) recent[i]: i};
      filtered = filtered.where((e) => order.containsKey(e.id));
      final list = filtered.toList()
        ..sort((a, b) => order[a.id]!.compareTo(order[b.id]!));
      return list;
    } else {
      filtered = filtered.where((e) => e.categoryId == _selectedCategory);
    }
    return filtered.toList();
  }

  void _open(FaqEntry entry) {
    getIt<FaqHistoryCubit>().markViewed(entry.id);
    switch (widget.variant) {
      case FaqEntryVariant.accordion:
        // ExpansionTile handles open/close inline — nothing to do.
        break;
      case FaqEntryVariant.detailRoute:
        Navigator.of(context).push(
          RouteTransition.route<void>(
            context: context,
            name: 'faq-entry',
            child: FaqEntryDetailPage(
              entry: entry,
              onFeedback: widget.onFeedback,
              onContactSupport: widget.onContactSupport,
            ),
          ),
        );
      case FaqEntryVariant.bottomSheet:
        _openSheet(entry);
    }
  }

  Future<void> _openSheet(FaqEntry entry) async {
    await GlobalBottomSheet.show<void>(
      context: context,
      title: entry.question,
      icon: Icons.help_outline_rounded,
      style: const SheetStyle(floating: true),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlobalMarkdown(data: entry.answerMarkdown),
          const SizedBox(height: 16),
          _FeedbackRow(entry: entry, onFeedback: widget.onFeedback),
        ],
      ),
    );
  }

  void _maybeAutoOpen(FaqData data) {
    if (_autoOpened) return;
    final target = widget.initialEntryId;
    if (target == null) return;
    final match = data.entries.where((e) => e.id == target).firstOrNull;
    if (match == null) return;
    _autoOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open(match);
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.appBar == null && widget.background == null) {
      // Embedded mode — caller wraps in their own Scaffold.
      return body;
    }
    return Scaffold(
      appBar:
          widget.appBar ??
          GlobalAppBar.simple(widget.title ?? FaqStrings.helpCenter),
      backgroundColor: widget.background,
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<FaqHistoryCubit, FaqHistoryState>(
      bloc: getIt<FaqHistoryCubit>(),
      builder: (context, historyState) {
        return FutureBuilder<FaqData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _SkeletonList();
            }
            if (snap.hasError || !snap.hasData) {
              return _ErrorBanner(
                error: snap.error,
                onRetry: _refresh,
              );
            }
            final data = snap.data!;
            if (data.isEmpty) {
              return _EmptyBanner(onRetry: _refresh);
            }
            _maybeAutoOpen(data);
            final filtered = _filter(data, historyState.recent);
            // Through the MODULE: the FAQ's pull is the same gesture
            // as every other one in the app, and raw it had none of
            // what `GlobalRefreshable` does — including the Cupertino
            // spinner on an iPhone.
            return GlobalRefreshable(
              onRefresh: _refresh,
              child: GlobalScrollable.custom(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: SearchTextField(
                        controller: _searchCtrl,
                        hint: FaqStrings.searchHint,
                        onChanged: (v) => setState(() => _query = v),
                        // Instant local-list filter (was per-keystroke
                        // before the sweep; the 250ms default also left a
                        // stale-clear race with the module clear button).
                        debounce: Duration.zero,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _CategoryRow(
                      categories: data.categories,
                      selected: _selectedCategory,
                      includeAll: widget.includeAllChip,
                      includeRecent:
                          widget.includeRecentChip &&
                          historyState.recent.isNotEmpty,
                      onSelected: (id) =>
                          setState(() => _selectedCategory = id),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
                        child: Center(
                          child: Text(
                            FaqStrings.noMatchingAnswers,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final entry = filtered[i];
                        return _EntryTile(
                          entry: entry,
                          query: _query,
                          variant: widget.variant,
                          onTap: () => _open(entry),
                          onFeedback: widget.onFeedback,
                        );
                      },
                    ),
                  if (widget.onContactSupport != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: GlobalFilledButton(
                          text: CommonStrings.contactSupport,
                          onPressed: widget.onContactSupport,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Category chip row ───────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categories,
    required this.selected,
    required this.includeAll,
    required this.includeRecent,
    required this.onSelected,
  });

  final List<FaqCategory> categories;
  final String selected;
  final bool includeAll;
  final bool includeRecent;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: GlobalScrollable(
        scrollDirection: Axis.horizontal,
        // An elevated chip paints its shadow OUTSIDE its own box, and
        // a scroll view clips to its viewport by default — so the
        // selected chip's shadow came off flat against the bottom edge.
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            if (includeAll)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GlobalChip(
                  label: FaqStrings.all,
                  selected: selected == '__all__',
                  onSelected: (_) => onSelected('__all__'),
                ),
              ),
            if (includeRecent)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GlobalChip(
                  avatar: const Icon(Icons.history_rounded),
                  label: FaqStrings.recent,
                  selected: selected == '__recent__',
                  onSelected: (_) => onSelected('__recent__'),
                ),
              ),
            for (final cat in categories)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GlobalChip(
                  avatar: cat.icon != null ? Icon(cat.icon) : null,
                  label: cat.name,
                  selected: selected == cat.id,
                  onSelected: (_) => onSelected(cat.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── List entry tile ──────────────────────────────────────────────

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.query,
    required this.variant,
    required this.onTap,
    this.onFeedback,
  });

  final FaqEntry entry;
  final String query;
  final FaqEntryVariant variant;
  final VoidCallback onTap;
  final Future<void> Function(FaqEntry, FaqFeedback)? onFeedback;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = _highlight(context, entry.question, query);

    if (variant == FaqEntryVariant.accordion) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: GlobalExpandableContainer(
          style: ContainerStyle(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.all(16),
            shadow: const [],
          ),
          header: title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlobalMarkdown(data: entry.answerMarkdown),
              const SizedBox(height: 8),
              _FeedbackRow(entry: entry, onFeedback: onFeedback),
            ],
          ),
        ),
      );
    }

    // detailRoute + bottomSheet — tap routes the open elsewhere.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GlobalContainer.tile(
        leading: Icon(Icons.help_outline_rounded, color: cs.primary),
        // The question is a HIGHLIGHTED span, not a plain string.
        titleWidget: title,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
        style: const ContainerStyle(
          shadow: [],
          backgroundColor: Color(0x00000000),
        ),
      ),
    );
  }

  Widget _highlight(BuildContext context, String text, String q) {
    if (q.isEmpty) {
      // Questions are authored/backend content: an Arabic entry in an
      // English-locale app must still render RTL, so derive direction
      // from the STRING rather than the ambient Directionality.
      return GlobalText(
        text,
        autoDetectDirection: true,
        textStyle: const GlobalTextStyle(fontWeight: FontWeight.w600),
      );
    }
    final lower = text.toLowerCase();
    final needle = q.toLowerCase();
    final idx = lower.indexOf(needle);
    if (idx < 0) {
      return GlobalText(
        text,
        autoDetectDirection: true,
        textStyle: const GlobalTextStyle(fontWeight: FontWeight.w600),
      );
    }
    final cs = Theme.of(context).colorScheme;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + q.length),
            style: TextStyle(
              backgroundColor: cs.primary.withValues(alpha: 0.25),
              color: cs.onSurface,
            ),
          ),
          TextSpan(text: text.substring(idx + q.length)),
        ],
      ),
    );
  }
}

// ─── Feedback row (inline / sheet) ────────────────────────────────

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({required this.entry, this.onFeedback});

  final FaqEntry entry;
  final Future<void> Function(FaqEntry, FaqFeedback)? onFeedback;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<FaqHistoryCubit, FaqHistoryState>(
      bloc: getIt<FaqHistoryCubit>(),
      builder: (context, _) {
        final cubit = getIt<FaqHistoryCubit>();
        final current = cubit.feedbackFor(entry.id);
        return Row(
          children: [
            Text(
              current == null
                  ? FaqStrings.wasThisHelpful
                  : current == FaqFeedback.helpful
                  ? FaqStrings.markedHelpful
                  : FaqStrings.feedbackRecorded,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GlobalIconButton(
              tooltip: FaqStrings.helpful,
              iconData: current == FaqFeedback.helpful
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_up_alt_outlined,
              isSelected: current == FaqFeedback.helpful,
              onPressed: () {
                cubit.setFeedback(entry.id, FaqFeedback.helpful);
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
                cubit.setFeedback(entry.id, FaqFeedback.notHelpful);
                onFeedback?.call(entry, FaqFeedback.notHelpful);
              },
            ),
          ],
        );
      },
    );
  }
}

// ─── Skeleton + error / empty banners ────────────────────────────

class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: 6,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GlobalContainer(
          style: ContainerStyle(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.all(16),
            shadow: const [],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      color: cs.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 180,
                      color: cs.surfaceContainerHighest,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: cs.error),
            const SizedBox(height: 12),
            Text(
              FaqStrings.loadFailed,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$error',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            GlobalFilledButton(
              text: CommonStrings.retry,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBanner extends StatelessWidget {
  const _EmptyBanner({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 40,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              FaqStrings.noArticlesYet,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            RefreshButton(
              variant: CommonButtonVariant.outlined,
              showIcon: true,
              shrinkWidth: true,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
