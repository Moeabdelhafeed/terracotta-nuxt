import 'package:flutter/material.dart';

import '../../../core/localization/strings/module_strings.dart';
import '../../module/buttons/global_filled_button.dart';
import '../../module/buttons/global_text_button.dart';
import '../../module/empty_state/global_empty_state.dart';

export '../../module/empty_state/global_empty_state.dart'
    show EmptyStateStyle, EmptyStateVariant, GlobalEmptyState;

/// The four empty states every app ends up writing.
///
/// They are wrappers, not a second widget: each one is a
/// `GlobalEmptyState` with the copy, the glyph and the action already
/// decided, so the same "no results" screen does not get re-invented —
/// with different words — in six features.
///
/// Copy comes from `EmptyStateStrings` (the `empty_` ARB prefix), which
/// is why these live in commons rather than in the module: the module
/// must not know what an app calls things.

// ---------------------------------------------------------------------------
// NoResultsEmptyState
// ---------------------------------------------------------------------------

/// A search that matched nothing.
///
/// The query is ECHOED in the title, because "no results" alone leaves
/// the user unsure whether the search ran at all — and a typo is the
/// most common reason it matched nothing.
class NoResultsEmptyState extends StatelessWidget {
  const NoResultsEmptyState({
    required this.query,
    super.key,
    this.onClear,
    this.variant = EmptyStateVariant.compact,
    this.style = const EmptyStateStyle(),
  });

  final String query;

  /// Offers a way BACK. Without it the only exit is the keyboard.
  final VoidCallback? onClear;

  final EmptyStateVariant variant;
  final EmptyStateStyle style;

  @override
  Widget build(BuildContext context) => GlobalEmptyState(
    title: EmptyStateStrings.noResultsTitle(query),
    subtitle: EmptyStateStrings.noResultsSubtitle,
    icon: Icons.search_off_rounded,
    variant: variant,
    style: style,
    primaryAction: onClear == null
        ? null
        : GlobalTextButton(
            text: EmptyStateStrings.clearSearch,
            onPressed: onClear,
          ),
  );
}

// ---------------------------------------------------------------------------
// OfflineEmptyState
// ---------------------------------------------------------------------------

/// No connection. Distinct from a failure: nothing is broken, and the
/// fix is the user's to make.
class OfflineEmptyState extends StatelessWidget {
  const OfflineEmptyState({
    super.key,
    this.onRetry,
    this.variant = EmptyStateVariant.fullPage,
    this.style = const EmptyStateStyle(),
  });

  final VoidCallback? onRetry;
  final EmptyStateVariant variant;
  final EmptyStateStyle style;

  @override
  Widget build(BuildContext context) => GlobalEmptyState(
    title: EmptyStateStrings.offlineTitle,
    subtitle: EmptyStateStrings.offlineSubtitle,
    icon: Icons.wifi_off_rounded,
    variant: variant,
    style: style,
    primaryAction: onRetry == null
        ? null
        : GlobalFilledButton(
            text: EmptyStateStrings.retry,
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
  );
}

// ---------------------------------------------------------------------------
// LoadFailedEmptyState
// ---------------------------------------------------------------------------

/// Something broke on our side.
///
/// [detail] replaces the stock second line — a server's own message is
/// more use than "try again in a moment", when there is one.
class LoadFailedEmptyState extends StatelessWidget {
  const LoadFailedEmptyState({
    super.key,
    this.detail,
    this.onRetry,
    this.variant = EmptyStateVariant.fullPage,
    this.style = const EmptyStateStyle(),
  });

  final String? detail;
  final VoidCallback? onRetry;
  final EmptyStateVariant variant;
  final EmptyStateStyle style;

  @override
  Widget build(BuildContext context) => GlobalEmptyState(
    title: EmptyStateStrings.failedTitle,
    subtitle: detail ?? EmptyStateStrings.failedSubtitle,
    icon: Icons.error_outline_rounded,
    variant: variant,
    style: style,
    primaryAction: onRetry == null
        ? null
        : GlobalFilledButton(
            text: EmptyStateStrings.retry,
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
  );
}

// ---------------------------------------------------------------------------
// FirstRunEmptyState
// ---------------------------------------------------------------------------

/// Nothing here YET — the one empty state that is an invitation rather
/// than a dead end.
///
/// Its copy is the caller's, because only the feature knows what the
/// first thing is called. What the wrapper standardises is the SHAPE:
/// a glyph, a name for the thing, one line on why it is worth making,
/// and a single button that makes one.
class FirstRunEmptyState extends StatelessWidget {
  const FirstRunEmptyState({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    super.key,
    this.subtitle,
    this.icon = Icons.add_circle_outline_rounded,
    this.variant = EmptyStateVariant.fullPage,
    this.style = const EmptyStateStyle(),
  });

  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;
  final EmptyStateVariant variant;
  final EmptyStateStyle style;

  @override
  Widget build(BuildContext context) => GlobalEmptyState(
    title: title,
    subtitle: subtitle,
    icon: icon,
    variant: variant,
    style: style,
    primaryAction: GlobalFilledButton(
      text: actionLabel,
      icon: Icons.add_rounded,
      onPressed: onAction,
    ),
  );
}
