import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/notifications/push_diagnostics.dart';
import '../../../data/notifications/topic_subscription.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_text_button.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_page_bar.dart';

/// «تشخيص الإشعارات» — whether push actually works on THIS device.
///
/// Not a customer screen. It exists because every way FCM topics fail
/// is silent and they all look the same from outside — "the studio
/// sent a broadcast and nothing arrived" — and because the log lines
/// that would answer it are behind `kDebugMode`, so the build on a
/// tester's phone prints nothing at all.
///
/// ## How to read it
///
/// **Subscriptions** is what this run asked FCM for, and whether the
/// call was accepted. FCM has no API to ask which topics a device is
/// on, so if this list is empty or red, the device is not on them.
///
/// **Messages** is what arrived, and the important column is where
/// from. `topic:users_ar` means a broadcast reached this device —
/// subscription works, end of argument. `token` means the message was
/// addressed to this one device, which is how every ordinary
/// notification in this app is sent and proves nothing about topics.
///
/// So the two questions separate cleanly:
///
///   * subscriptions green, no `topic:` line ever → **the device is
///     subscribed and nothing is being sent to the topic.**
///   * subscriptions red or empty → the fault is here.
///
/// ## What it cannot see
///
/// A push that lands while the app is closed is handled in another
/// isolate and never reaches this list. Run `tools/watch_push.sh` to
/// watch the device's own log for those.
class PushDiagnosticsPage extends StatelessWidget {
  const PushDiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final d = PushDiagnostics.instance;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      appBar: const TerracottaPageBar(title: 'Push diagnostics', pinned: true),
      body: ValueListenableBuilder<int>(
        valueListenable: d.revision,
        builder: (context, _, _) => GlobalScrollable(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Section(
                  title: 'This device',
                  children: [
                    _Row(
                      label: 'FCM token',
                      value: d.token == null
                          ? 'none yet'
                          : '${d.token!.substring(0, 12)}…',
                      ok: d.token != null,
                    ),
                    // THE LINE THAT TELLS THE THREE FAULTS APART. An
                    // empty list below can mean the call never ran,
                    // ran and failed, or genuinely published nothing —
                    // and they used to look identical.
                    _Row(
                      label: 'GET /api/config',
                      value: d.configState,
                      ok: d.configState.startsWith('ok'),
                    ),
                    _Row(
                      label: 'Published by the server',
                      value: d.published.isEmpty
                          ? 'none — see the line above for why'
                          : d.published.join(', '),
                      ok: d.published.isNotEmpty,
                    ),
                    _Row(
                      label: 'This reader belongs on',
                      value: d.wanted.isEmpty ? 'nothing' : d.wanted.join(', '),
                      ok: d.wanted.isNotEmpty,
                    ),
                  ],
                ),
                SizedBox(height: spacing.md),
                _Section(
                  title: 'Subscriptions (${d.topics.length})',
                  empty:
                      'Nothing asked for yet. If this stays empty the '
                      'device is on no topics at all — FCM cannot be '
                      'queried, so this list is the only record.',
                  children: [
                    for (final t in d.topics)
                      _Row(label: t.topic, value: t.line, ok: t.ok),
                  ],
                ),
                SizedBox(height: spacing.md),
                _Section(
                  title: 'Messages seen (${d.received.length})',
                  empty:
                      'Nothing has arrived while the app was open. A '
                      'push that lands with the app closed is handled '
                      'in another isolate and cannot appear here.',
                  children: [
                    for (final r in d.received)
                      _Row(
                        label: r.viaTopic ? 'topic:${r.topic}' : 'to token',
                        value: r.line,
                        ok: r.viaTopic,
                        neutral: !r.viaTopic,
                      ),
                  ],
                ),
                SizedBox(height: spacing.lg),
                GlobalFilledButton(
                  text: 'Copy report',
                  style: terracottaCtaStyle(showArrow: false),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: d.report()),
                    );
                    GlobalToast.success('Copied');
                  },
                ),
                SizedBox(height: spacing.sm),
                // ASK AGAIN. One failed call at boot used to cost the
                // whole run — `topics` stayed empty and every later
                // trigger found it empty and returned. This drops what
                // was loaded and starts over.
                GlobalTextButton(
                  text: 'Retry config + subscribe',
                  onPressed: () => unawaited(TopicSubscription.retry()),
                ),
                SizedBox(height: spacing.sm),
                GlobalTextButton(text: 'Clear', onPressed: d.clear),
                SizedBox(height: spacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.empty});

  final String title;
  final List<Widget> children;
  final String? empty;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(
            color: context.textColors.primary,
          ),
        ),
        SizedBox(height: spacing.xs),
        if (children.isEmpty && empty != null)
          Text(
            empty!,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textColors.secondary,
            ),
          )
        else
          ...children,
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.ok,
    this.neutral = false,
  });

  final String label;
  final String value;
  final bool ok;

  /// True where "not a topic" is a fact rather than a fault — a
  /// message sent to this device's token is the normal case and says
  /// nothing about whether topics work.
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final tint = neutral
        ? context.textColors.secondary
        : ok
        ? context.statusColors.success
        : context.statusColors.error;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            neutral
                ? Icons.remove_circle_outline
                : ok
                ? Icons.check_circle_outline
                : Icons.error_outline,
            size: context.iconSizes.sm,
            color: tint,
          ),
          SizedBox(width: spacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.textColors.primary,
                  ),
                ),
                SelectableText(
                  value,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
