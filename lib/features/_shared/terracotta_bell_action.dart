import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_gate.dart';
import '../../core/constants/assets/assets.dart';
import '../../core/di/service_locator.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../../shared/module/buttons/global_icon_button.dart';
import '../profile/cubits/notifications_cubit.dart';
import '../profile/cubits/notifications_state.dart';
import '../shell/widgets/terracotta_app_bar.dart';
import 'terracotta_count_badge.dart';

/// The bell, with its unread dot — as one widget, so every bar that
/// carries it carries the SAME one.
///
/// [unread] comes from `unread_count` on `GET /api/notifications`, never
/// from counting unread rows: the list paginates and the count does
/// not.
class TerracottaBellAction extends StatefulWidget {
  const TerracottaBellAction({this.unread, this.cubit, super.key});

  /// A fixed count, for a test or a preview. Null reads the app's own
  /// — see [build].
  final int? unread;

  /// The cubit to watch. Null takes the app's, which is what every bar
  /// does.
  final NotificationsCubit? cubit;

  @override
  State<TerracottaBellAction> createState() => _TerracottaBellActionState();
}

class _TerracottaBellActionState extends State<TerracottaBellAction> {
  int? get unread => widget.unread;
  NotificationsCubit? get cubit => widget.cubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // THE COUNT FOLLOWS THE LANGUAGE.
    //
    // Runs on mount and again whenever `Localizations` changes above
    // us, which is the app's own contract for server-localized data —
    // a notification's `title` and `body` are written by the server in
    // whatever `Accept-Language` asked for, so a language change makes
    // the ones already loaded wrong.
    //
    // GATED: the inbox is the reader's own and `GET /api/notifications`
    // answers 401 without a session — which the app reads as the
    // session ending, so asking as a guest would evict them.
    if (widget.unread != null) return;
    if (!getIt.isRegistered<NotificationsCubit>()) return;
    if (!AuthGate.has(context)) return;

    unawaited(
      (cubit ?? getIt<NotificationsCubit>()).ensureLoaded(
        Localizations.localeOf(context).languageCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A FIXED number when one was given, the live one otherwise.
    //
    // It used to be a parameter defaulting to 0, and every bar in the
    // app built `const TerracottaBellAction()` — so the badge was
    // always absent, on every screen, whatever the inbox held.
    //
    // Watched rather than read once: marking something read moves the
    // number on the screen the reader is looking at, not the next one
    // they open. A GUEST has no inbox and no count, and the singleton
    // answers zero for them, so nothing is drawn.
    final fixed = unread;
    if (fixed != null) return _bell(context, fixed);

    if (!getIt.isRegistered<NotificationsCubit>()) return _bell(context, 0);

    return BlocBuilder<NotificationsCubit, NotificationsState>(
      bloc: cubit ?? getIt<NotificationsCubit>(),
      buildWhen: (a, b) => a.unread != b.unread,
      builder: (context, state) => _bell(context, state.unread),
    );
  }

  Widget _bell(BuildContext context, int unread) => Stack(
    clipBehavior: Clip.none,
    children: [
      GlobalIconButton(
        iconPath: Assets.icons.notificationBell.defaultPath,
        // OPENS FOR ANYBODY. The inbox needs a session — `GET
        // /api/notifications` answers 401 without one, for a
        // registered guest too — but that is the PAGE's business, and
        // it now says so with the way in on it. A dialog on the tap
        // interrupted a visitor instead of answering them.
        onPressed: () => context.pushNamed('notifications'),
        semanticLabel: ProfileStrings.notifications,
        // SMALL. The default box is sized for a labelled button; on a
        // bare glyph it reads as a slab.
        size: ButtonSize.small,
        style: ButtonStateStyle(
          backgroundColor: TerracottaAppBar.plate(context),
          foregroundColor: TerracottaAppBar.glyph(context),
        ),
      ),
      // THE SAME BADGE THE CART WEARS — see [TerracottaCountBadge].
      // The bell used to carry a red ringed pill of its own, next to
      // the cart's coral disc, on the same bar.
      if (unread > 0)
        PositionedDirectional(
          top: TerracottaCountBadge.top,
          end: TerracottaCountBadge.end,
          child: IgnorePointer(child: TerracottaCountBadge(count: unread)),
        ),
    ],
  );
}
