import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_gate.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/date_time_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/account/app_notification.dart';
import '../../../data/models/terracotta/account/notification_filter.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_icon_button.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/list/global_list.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../_shared/account_refresh.dart';
import '../../_shared/filter_chip_rail.dart';
import '../../_shared/skeleton_block.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../shell/widgets/terracotta_app_bar.dart';
import '../cubits/notifications_cubit.dart';
import '../cubits/notifications_state.dart';
import '../data/notification_kind.dart';

/// «الاشعارات» — the inbox.
///
/// `GET /api/notifications`. Every push also writes a row here, so this
/// is where order status changes, workshop reminders, piece-ready and
/// wallet credits land.
///
/// The badge comes from `unread_count` on the same call — never from
/// counting unread rows, because the list paginates and the count does
/// not.
class NotificationsInboxPage extends StatefulWidget {
  const NotificationsInboxPage({this.cubit, super.key});

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final NotificationsCubit? cubit;

  @override
  State<NotificationsInboxPage> createState() => _NotificationsInboxPageState();
}

class _NotificationsInboxPageState extends State<NotificationsInboxPage> {
  // THE APP'S OWN, not this page's. The bell in every bar reads the
  // same cubit, so marking something read here moves the badge
  // everywhere at once.
  late final _inbox = widget.cubit ?? getIt<NotificationsCubit>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `title` and `body` arrive PRE-RENDERED from the server, so a
    // language change leaves every row on screen in the wrong one and
    // nothing in the app can translate them.
    // NOT FOR A GUEST. `GET /api/notifications` answers 401 for them —
    // verified live, and a registered guest gets the same — and a 401
    // anywhere in this app is the session ending, so asking would
    // evict a visitor who was only curious. The page draws its
    // signed-out state instead; see [_Body].
    if (AuthGate.has(context)) unawaited(_inbox.ensureLoaded(_locale));
  }

  String get _locale => Localizations.localeOf(context).languageCode;

  /// Mark it read, then go where it points.
  ///
  /// Both, and in that order: the row is read the moment it is opened
  /// whether or not it has anywhere to go, and the badge moves before
  /// the next page is on screen rather than after coming back from it.
  Future<void> _open(AppNotification n) async {
    unawaited(_inbox.markRead(n));

    final kind = NotificationKind.of(n);
    if (!kind.opens(n) || !mounted) return;

    final id = kind.idIn(n);
    context.pushNamed(
      kind.routeName!,
      pathParameters: {if (id != null) kind.pathKey!: id},
    );
  }

  // NOTHING TO DISPOSE. The cubit is a `getIt` singleton now — the
  // bell in every bar reads it — so closing it here would leave every
  // other screen's badge listening to a dead stream. An injected one
  // belongs to its test.
  //
  // This is the same reason the tab cubits are singletons:
  // `context.go` tears a page's `State` down, and a badge that dies
  // with a page is a badge that is right on one screen.

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<NotificationsCubit, NotificationsState>(
        bloc: _inbox,
        builder: (context, state) => Scaffold(
          backgroundColor: context.backgroundColors.scaffoldBackground,
          appBar: TerracottaPageBar(
            title: ProfileStrings.notifications,
            // PINNED. The inbox is a list that runs long, and its one
            // control — «تعليم الكل كمقروء» — is in the bar: a bar
            // that retreats takes that control away exactly when the
            // reader has scrolled far enough to want it.
            pinned: true,
            actions: [
              // Only when there IS something to mark. A control that
              // does nothing is worse than no control.
              //
              // A GLYPH, not the words: an app bar hands its actions
              // UNBOUNDED width, and a label button in one asks to be
              // infinitely wide. The sentence lives on the tooltip,
              // which is also what a screen reader reads.
              if (state.unread > 0)
                GlobalIconButton(
                  iconData: Icons.done_all_rounded,
                  onPressed: () => unawaited(_inbox.markAllRead()),
                  tooltip: ProfileStrings.markAllRead,
                  semanticLabel: ProfileStrings.markAllRead,
                  size: ButtonSize.small,
                  style: ButtonStateStyle(
                    backgroundColor: TerracottaAppBar.plate(context),
                    foregroundColor: TerracottaAppBar.glyph(context),
                  ),
                ),
            ],
          ),
          body: AuthGate.watch(context)
              ? GlobalRefreshable(
                  onRefresh: () async {
                    // AND WHO THEY ARE. A pull on a page about the customer
                    // is a person asking whether the app is still right about
                    // them — see [AccountRefresh].
                    await Future.wait([
                      AccountRefresh.user(context),
                      _inbox.refresh(_locale),
                    ]);
                  },
                  child: _Body(
                    state: state,
                    onFilter: (f) => unawaited(_inbox.showFilter(f)),
                    onRetry: () => unawaited(_inbox.refresh(_locale)),
                    onOpen: (n) => unawaited(_open(n)),
                  ),
                )
              // A GUEST IS LET IN, and the page explains itself.
              //
              // It used to be a dialog on the tap — «سجّل الدخول» over
              // whatever they were looking at — which interrupts
              // rather than answers. A screen that says what the inbox
              // is for, with the way in on it, is the same information
              // without the ambush.
              : _CentredInPage(
                  child: GlobalEmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: ProfileStrings.notifSignedOut,
                    subtitle: ProfileStrings.notifSignedOutBody,
                    primaryAction: GlobalFilledButton(
                      text: AuthStrings.signIn,
                      onPressed: () => context.pushNamed('login'),
                      style: terracottaCtaStyle(showArrow: false),
                    ),
                  ),
                ),
        ),
      );
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.onFilter,
    required this.onRetry,
    required this.onOpen,
  });

  final NotificationsState state;
  final ValueChanged<NotificationFilter> onFilter;
  final VoidCallback onRetry;
  final ValueChanged<AppNotification> onOpen;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    // Placeholders only when there is NOTHING to keep — a failed
    // refresh leaves the rows the reader was already looking at.
    //
    // THE TABS STAY UP while a tab loads. Taking them away with the
    // rows would strand the reader on a filter they cannot change
    // until the request they are waiting on has finished.
    if (state.loading && state.items.isEmpty) {
      return state.filter.isAll
          ? const _InboxSkeleton()
          : _Filtered(
              state: state,
              onFilter: onFilter,
              child: const _InboxSkeleton(),
            );
    }

    // AN EMPTY TAB IS NOT AN EMPTY INBOX. Once a filter is on, the
    // whole-page empty state below would tell somebody with 26
    // notifications that they have none — so the tabs stay on screen
    // and the emptiness is reported inside them.
    if (state.items.isEmpty && state.error == null && !state.filter.isAll) {
      return _Filtered(
        state: state,
        onFilter: onFilter,
        child: _CentredInPage(
          child: GlobalEmptyState(
            title: ProfileStrings.notifNoneInFilter,
            icon: Icons.filter_alt_off_rounded,
            variant: EmptyStateVariant.compact,
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      // CENTRED in the page, not sitting under the app bar.
      //
      // The empty state was the first child of a stretched column, so
      // it drew at the top of a screen with nothing else on it — the
      // one case where the whole page IS the empty state.
      return _CentredInPage(
        child: state.error != null
            ? GlobalEmptyState(
                icon: Icons.wifi_off_rounded,
                title: AuthStrings.errorGeneric,
                subtitle: state.error is NetworkException
                    ? null
                    : state.error!.message,
                primaryAction: GlobalFilledButton(
                  text: CommonStrings.retry,
                  onPressed: onRetry,
                  style: terracottaCtaStyle(showArrow: false),
                ),
              )
            : GlobalEmptyState(
                title: ProfileStrings.noNotifications,
                icon: Icons.notifications_off_rounded,
                variant: EmptyStateVariant.compact,
              ),
      );
    }

    return _Filtered(
      state: state,
      onFilter: onFilter,
      child: GlobalList<AppNotification>.static(
        items: state.items,
        // Rows ARRIVE rather than appear — as the server answers, and
        // as more scroll into view.
        //
        // `subtle`: a fade with no cascade. An inbox is a dense list
        // the reader scans, and a wave of motion down it is noise
        // rather than rhythm.
        style: ListStyle(
          padding: EdgeInsets.all(spacing.md),
          scrollIn: ScrollInStyle.subtle,
        ),
        separatorBuilder: (_, _) => SizedBox(height: spacing.sm),
        itemBuilder: (context, notification, index) =>
            _NotificationRow(notification: notification, onTap: onOpen),
      ),
    );
  }
}

/// The tab strip, and whatever the chosen tab has to show under it.
class _Filtered extends StatelessWidget {
  const _Filtered({
    required this.state,
    required this.onFilter,
    required this.child,
  });

  final NotificationsState state;
  final ValueChanged<NotificationFilter> onFilter;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(height: context.spacing.sm),
      _InboxTabs(state: state, onChanged: onFilter),
      Expanded(child: child),
    ],
  );
}

/// The empty state, in the middle of what is left of the screen.
///
/// A scrollable rather than a bare `Center`: the CALLER has to ask for
/// `AlwaysScrollableScrollPhysics`, or a page shorter than the viewport
/// drops the drag recogniser and the pull-to-refresh above it never
/// sees an overscroll — and the empty page is the one that most needs
/// pulling.
class _CentredInPage extends StatelessWidget {
  const _CentredInPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GlobalScrollable(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(child: child),
      ),
    ),
  );
}

/// WHAT IT IS, in one glance: a tinted glyph for the kind, the words,
/// and a chevron when there is somewhere to go.
///
/// The colour and the icon both come from [NotificationKind], which
/// reads the machine `type` rather than the prose — see that class for
/// why it matches on parts of the string.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.onTap});

  final AppNotification notification;
  final ValueChanged<AppNotification> onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final unread = !notification.isRead;
    final kind = NotificationKind.of(notification);
    final tint = kind.color(context);

    return TerracottaCard(
      onTap: () => onTap(notification),
      padding: EdgeInsets.all(spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // THE KIND, as a tinted disc. It replaces the unread dot as
          // the first thing the eye meets — a dot says only "new",
          // and this says what happened before a word is read.
          _KindGlyph(icon: kind.icon, tint: tint, unread: unread),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Pre-rendered and pre-translated. Displayed verbatim.
                  notification.title,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.textColors.primary,
                    fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                SizedBox(height: spacing.xs),
                Text(
                  notification.body,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textColors.secondary,
                  ),
                ),
                SizedBox(height: spacing.xs),
                // WHEN. «قبل ساعتين», not a timestamp.
                //
                // An inbox is read newest-first and what the reader
                // wants from a date here is how FRESH it is — "2 hours
                // ago" answers that at a glance where
                // «٢٠٢٦/٠٩/١٤ ١٤:٣٠» has to be worked out against the
                // clock. Localized through `timeago`, whose messages
                // are registered at boot.
                //
                // `.toLocal()` first: these timestamps are UTC — this
                // endpoint sends an offset where `GET /api/user` sends
                // a `Z`, and both mean the same thing — so formatted
                // raw they would read hours off wherever the reader is.
                Text(
                  notification.createdAt.toLocal().ago,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.textColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          // ONLY when the tap goes somewhere. A chevron on a row that
          // does nothing is a promise the page cannot keep — and a
          // `type` this app has never met is exactly that row.
          if (kind.opens(notification))
            Padding(
              padding: EdgeInsetsDirectional.only(start: spacing.xs, top: 2),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: context.textColors.secondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// The kind's glyph, and the unread mark riding it.
///
/// Unread is a RING plus a full-strength fill; read is the same disc
/// faded back. Two states of one object rather than a separate dot, so
/// a read row still says what it was about.
class _KindGlyph extends StatelessWidget {
  const _KindGlyph({
    required this.icon,
    required this.tint,
    required this.unread,
  });

  final IconData icon;
  final Color tint;
  final bool unread;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 36,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tint.withValues(alpha: unread ? 0.18 : 0.10),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: tint.withValues(alpha: unread ? 1 : 0.55),
            ),
          ),
        ),
        if (unread)
          PositionedDirectional(
            top: -1,
            end: -1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.primaryColors.accent,
                border: Border.all(
                  color: context.backgroundColors.container,
                  width: 1.5,
                ),
              ),
              child: const SizedBox.square(dimension: 10),
            ),
          ),
      ],
    ),
  );
}

/// The tab strip: «الكل», «غير المقروءة», and the categories the
/// inbox actually holds.
///
/// **The SERVER filters and the SERVER counts.** Both were done here
/// before, over whatever page happened to be loaded — which meant a
/// tab labelled with a slice of a slice, and a "bookings" tab that
/// showed four of nine because the other five had not been fetched.
/// `meta.filter_counts` is always the whole inbox, which is the only
/// reason a tab can carry a number before anyone opens it.
///
/// A tab with nothing behind it is hidden, the same rule as «ورشاتي»'
/// status strip: a chip for a category nobody has any of asks the
/// reader to work out which apply. The chosen tab stays whatever its
/// count, or turning one off would take the way back with it.
///
/// The strip reaches the SCREEN edges rather than the page's gutter —
/// same `OverflowBox` idiom as `BookingStatusFilter`, and for the same
/// reason: a rail that stops at the padding leaves its first and last
/// chip clipped however far it is pushed.
class _InboxTabs extends StatelessWidget {
  const _InboxTabs({required this.state, required this.onChanged});

  final NotificationsState state;
  final ValueChanged<NotificationFilter> onChanged;

  /// Whether this tab earns a place on the strip.
  ///
  /// With no counts at all — an older server, or the first load — every
  /// tab shows and none carries a number. Hiding them all would be
  /// worse than offering one that turns out to be empty, which says so
  /// when it is opened.
  bool _shows(NotificationFilter filter) {
    if (filter == state.filter || filter.isAll) return true;
    if (state.counts.isEmpty) return true;
    return (state.countFor(filter) ?? 0) > 0;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = NotificationFilter.values
        .where(_shows)
        .toList(
          growable: false,
        );

    // Nothing to choose between: «الكل» on its own is the list itself,
    // and a strip of one chip is decoration.
    if (tabs.length < 2) return const SizedBox.shrink();

    return FilterChipRail(
      // NOTHING TO ESCAPE. This page's body is not inside a gutter —
      // the rows carry their own padding — so the rail stays inside
      // the width it was handed and insets its own content instead.
      // Reaching out through a gutter that is not there would push the
      // first and last chip off the screen. See [FilterChipRail].
      chips: [
        for (final filter in tabs)
          FilterChipSpec(
            label: ProfileStrings.notifFilter(filter),
            count: state.countFor(filter),
            selected: filter == state.filter,
            tint: filter.isUnread ? context.primaryColors.accent : null,
            onTap: () => onChanged(filter),
          ),
      ],
    );
  }
}

class _InboxSkeleton extends StatelessWidget {
  const _InboxSkeleton();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    // AS MANY AS FIT, not five.
    //
    // Five rows at 80 plus their gaps is 440 points, which overflowed
    // a landscape phone by 138 — the placeholder for a list was the
    // one thing on the screen that could not fit on it. It is a
    // stand-in for rows the reader is about to scroll, so filling the
    // window it has is both correct and what the real list does.
    return LayoutBuilder(
      builder: (context, constraints) {
        const rowHeight = 80.0;
        final step = rowHeight + spacing.sm;
        final room = constraints.maxHeight - spacing.md * 2;
        final rows = room.isFinite ? (room / step).floor().clamp(1, 5) : 5;

        return Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows; i++) ...[
                const SizedBox(height: rowHeight, child: SkeletonBlock()),
                if (i < rows - 1) SizedBox(height: spacing.sm),
              ],
            ],
          ),
        );
      },
    );
  }
}
