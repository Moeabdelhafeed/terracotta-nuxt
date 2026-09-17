import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/legal/legal_content.dart';
import '../../../core/legal/legal_page.dart';
import '../../../core/legal/legal_repository.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/legal_strings.dart';
import '../../../data/services/remote_config_service.dart';
import '../app_bar/global_app_bar.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_icon_button.dart';
import '../chip/global_chip.dart';
import '../container/global_container.dart';
import '../html/global_html.dart';
import '../markdown/global_markdown.dart';
import '../progress/global_progress.dart';
import '../scrollable/global_scrollable.dart';
import 'legal_style.dart';
import 'theme/legal_theme.dart';

/// Renders any [LegalPage] using the resolved [LegalContent].
/// Picks Markdown vs HTML renderer based on [LegalContent.kind].
///
/// Uses `GlobalContainer.prose` for comfortable reading widths and
/// pulls colors / typography from the active theme so legal pages
/// always inherit dark mode + saturation choices.
class LegalScreen extends StatefulWidget {
  const LegalScreen({
    required this.page,
    this.repository,
    this.style = const LegalStyle(),
    super.key,
  });

  final LegalPage page;

  /// How the page LOOKS. Shared with the About hub through
  /// `GlobalLegalTheme` — the document and the list that links to it
  /// are one screen to a reader, and were two sets of numbers.
  final LegalStyle style;

  /// Override for tests / DI. Defaults to a fresh [LegalRepository]
  /// per screen — cheap, holds no state.
  final LegalRepository? repository;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  late final LegalRepository _repo;
  Future<LegalContent?>? _future;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? LegalRepository();
    _kick();
  }

  void _kick() {
    setState(() {
      _future = _repo.load(widget.page);
    });
  }

  @override
  Widget build(BuildContext context) {
    // ONE resolve per build, handed down.
    final style = widget.style.resolve(context);
    return Scaffold(
      appBar: GlobalAppBar(
        title: widget.page.title,
        actions: [
          GlobalIconButton(
            iconData: Icons.refresh_rounded,
            onPressed: _kick,
            tooltip: CommonStrings.refresh,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: GlobalContainer.prose(
          child: FutureBuilder<LegalContent?>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const _LoadingState();
              }
              final content = snap.data;
              if (content == null) {
                return _DisabledState(page: widget.page, onRetry: _kick);
              }
              return _LegalBody(content: content, style: style);
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlobalProgress.loading(type: ProgressType.circular),
      ),
    );
  }
}

class _DisabledState extends StatelessWidget {
  const _DisabledState({required this.page, required this.onRetry});

  final LegalPage page;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final disabled = !RemoteConfigService.legalEnabled(page.slug);
    final tx = context.textColors;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            disabled ? Icons.visibility_off_outlined : Icons.cloud_off_rounded,
            size: 64,
            color: tx.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            disabled
                ? LegalStrings.pageUnavailable(page.title)
                : LegalStrings.pageLoadFailed(page.title),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: tx.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            disabled
                ? LegalStrings.pageDisabledBody
                : LegalStrings.checkConnectionBody,
            style: context.textTheme.bodyMedium?.copyWith(color: tx.secondary),
            textAlign: TextAlign.center,
          ),
          if (!disabled) ...[
            const SizedBox(height: 20),
            GlobalFilledButton(
              text: CommonStrings.tryAgain,
              onPressed: onRetry,
              style: const ButtonStateStyle(
                leading: Icon(Icons.refresh_rounded),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Body — picks Markdown or HTML renderer
// ─────────────────────────────────────────────────────────────

class _LegalBody extends StatelessWidget {
  const _LegalBody({required this.content, required this.style});

  final LegalContent content;
  final ResolvedLegalStyle style;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kDebugMode)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: style.pagePadding),
            child: _OriginChip(origin: content.origin),
          ),
        Expanded(
          child: content.isHtml
              ? _HtmlBody(body: content.body, style: style)
              : _MarkdownBody(body: content.body, style: style),
        ),
      ],
    );
  }
}

/// Where this document came from — DEBUG only.
///
/// It answers one question while you are working on the content
/// pipeline: is this the copy shipped in the bundle, the one the
/// backend served, a remote markdown file, or something the cache
/// kept? Getting that wrong looks like "my edit did nothing".
///
/// It was a hand-rolled pill: a `Container` with its own fill and
/// corner around a raw `Text`, reading `source: bundled`. It is a
/// `GlobalChip` now, with a GLYPH — the four origins are told apart
/// at a glance rather than by reading a lowercase word — and the
/// labels say what they mean.
class _OriginChip extends StatelessWidget {
  const _OriginChip({required this.origin});

  final LegalContentOrigin origin;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (origin) {
      LegalContentOrigin.backend => (Icons.cloud_done_rounded, 'Backend HTML'),
      LegalContentOrigin.remoteMarkdown => (
        Icons.cloud_download_rounded,
        'Remote markdown',
      ),
      LegalContentOrigin.cache => (Icons.history_rounded, 'From cache'),
      LegalContentOrigin.bundled => (
        Icons.inventory_2_outlined,
        'Bundled copy',
      ),
    };
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: GlobalChip(
        label: label,
        avatar: Icon(icon),
        variant: ChipVariant.outlined,
        // A REPORT, not a control: no `onPressed`, so it takes no
        // focus and offers a screen reader nothing to do.
        semanticLabel: 'Content source: $label',
      ),
    );
  }
}

class _MarkdownBody extends StatelessWidget {
  const _MarkdownBody({required this.body, required this.style});

  final String body;
  final ResolvedLegalStyle style;

  @override
  Widget build(BuildContext context) {
    return GlobalScrollable(
      // The prose clamp bounds the WIDTH; it adds no margin, so a
      // document ran to both screen edges on a phone.
      padding: EdgeInsets.only(
        left: style.pagePadding,
        right: style.pagePadding,
        bottom: style.sectionGap + MediaQuery.paddingOf(context).bottom,
      ),
      child: GlobalMarkdown(
        data: body,
        options: const MarkdownOptions(
          callouts: true,
          codeCopy: true,
        ),
      ),
    );
  }
}

class _HtmlBody extends StatelessWidget {
  const _HtmlBody({required this.body, required this.style});

  final String body;
  final ResolvedLegalStyle style;

  @override
  Widget build(BuildContext context) {
    return GlobalScrollable(
      padding: EdgeInsets.only(
        left: style.pagePadding,
        right: style.pagePadding,
        bottom: style.sectionGap + MediaQuery.paddingOf(context).bottom,
      ),
      child: GlobalHtml(data: body),
    );
  }
}
