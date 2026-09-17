import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/localization/strings/scan_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/blocs/auth/auth_bloc.dart';
import '../../../data/models/terracotta/scan/scan_result.dart';
import '../../../data/models/terracotta/scan/scan_session.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_icon_button.dart';
import '../../../shared/module/dialog/global_dialog.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../booking/widgets/clock_time.dart';
import '../../profile/data/account_actions.dart';
import '../../shell/widgets/terracotta_app_bar.dart';
import '../cubits/scan_day_cubit.dart';
import '../widgets/finish_session_sheet.dart';
import '../widgets/scan_session_card.dart';
import '../widgets/scanned_result_sheet.dart';
import 'scan_camera_page.dart';

/// «الاستقبال» — the front desk's whole app.
///
/// ## Why staff get a screen of their own and not a tab
///
/// A scanner account is not a customer with extra buttons: the two
/// route groups are mutually exclusive on the server, so a scanner
/// calling the shop gets 403 and vice versa. There is no mode to
/// choose — the token decides, and this is where a staff sign-in
/// lands.
///
/// ## The desk's day, in order
///
/// Open the day, scan people in as they arrive, press Start when the
/// session begins, Finish at the end. Start is the one irreversible
/// step: it marks everyone unscanned ABSENT, and a no-show is never
/// refunded. It asks first, and says exactly that.
class ScannerDeskPage extends StatefulWidget {
  const ScannerDeskPage({this.cubit, super.key});

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final ScanDayCubit? cubit;

  @override
  State<ScannerDeskPage> createState() => _ScannerDeskPageState();
}

class _ScannerDeskPageState extends State<ScannerDeskPage> {
  late final _day = widget.cubit ?? ScanDayCubit();

  @override
  void initState() {
    super.initState();
    if (widget.cubit == null) unawaited(_day.load());
  }

  /// The language the list on screen was fetched in.
  String? _loadedLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // THE DAY FOLLOWS THE LANGUAGE.
    //
    // `workshop_title` on every session is written by the server in
    // whatever `Accept-Language` asked for, so a language change makes
    // the whole list wrong — Arabic titles under an English bar. This
    // fires on mount and again whenever `Localizations` changes above
    // us, and re-asks only when it actually did.
    final locale = Localizations.localeOf(context).languageCode;
    if (_loadedLocale == locale) return;
    final first = _loadedLocale == null;
    _loadedLocale = locale;
    // The first pass is `initState`'s job — this would double it.
    if (!first) unawaited(_day.load());
  }

  @override
  void dispose() {
    if (widget.cubit == null) unawaited(_day.close());
    super.dispose();
  }

  /// Opens the camera, then does whatever the code turns out to mean.
  Future<void> _scan() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanCameraPage()),
    );
    if (code == null || !mounted) return;
    await _submit(code);
  }

  /// The typed fallback — the eight digits printed under every symbol,
  /// for when a camera will not focus or a phone screen is too dim.
  Future<void> _type() async {
    final code = await showCodeEntrySheet(context);
    if (code == null || !mounted) return;
    await _submit(code);
  }

  /// One code, and the conversation it may start.
  ///
  /// A booking for one person checks straight in. A party comes back
  /// `needs_count` having written NOTHING, so the desk is asked how
  /// many actually turned up and the code goes again with that number.
  Future<void> _submit(String code, {int? count}) async {
    final result = await _day.checkIn(code, count: count);
    if (!mounted) return;

    if (result == null) {
      GlobalToast.error(
        _day.state.error?.spokenMessage ?? AuthStrings.errorGeneric,
      );
      return;
    }

    if (result.needsCount) {
      final chosen = await showHeadcountSheet(context, result: result);
      if (chosen == null || !mounted) return;
      await _submit(code, count: chosen);
      return;
    }

    final name = result.userName ?? '';
    if (result.alreadyCheckedIn) {
      GlobalToast.info(ScanStrings.alreadyIn(name));
    } else {
      GlobalToast.success(ScanStrings.checkedIn(name));
    }
  }

  /// Leaves the desk.
  ///
  /// Staff share a device: a shift ends and the next person needs
  /// their own session, which is why this is a first-class control
  /// here rather than buried. There is no profile tab to hide it in —
  /// the desk IS the app for this account.
  Future<void> _signOut() async {
    final auth = context.read<AuthBloc>();
    final sure = await GlobalDialog.confirm(
      context: context,
      title: ScanStrings.signOut,
      message: ProfileStrings.signOutMessage,
      confirmText: ScanStrings.signOut,
      icon: Icons.logout_rounded,
    );
    if (!sure || !mounted) return;

    // The local session is cleared WHATEVER the server says — see
    // `AccountActions`.
    await AccountActions.signOut(auth);
    if (!mounted) return;
    // The SIGN-IN screen, not the shop: a scanner account has no
    // customer app to fall back to, and `home` would 403 its way
    // through every request.
    context.goNamed('login');
  }

  /// Whether a code can be taken at all right now.
  ///
  /// Two gates, both the server's: **today only** — any other date is
  /// a 422 — and **at least one session still open**, since Finish
  /// closes check-in on the session it ran on.
  ///
  /// A day whose sessions have not arrived yet keeps the buttons: the
  /// desk is usually mid-queue and hiding them on every refresh would
  /// be worse than a 422 nobody hits.
  bool get _canCheckInToday {
    if (!_day.isToday) return false;
    final sessions = _day.state.sessions;
    if (sessions.isEmpty) return !_day.state.hasData;
    return sessions.any((s) => s.canCheckIn);
  }

  Future<void> _start(ScanSession session) async {
    final sure = await GlobalDialog.confirm(
      context: context,
      title: ScanStrings.startWarningTitle,
      message: ScanStrings.startWarningBody,
      confirmText: ScanStrings.startSession,
    );
    if (!sure || !mounted) return;

    if (await _day.start(session)) {
      if (mounted) GlobalToast.success(ScanStrings.sessionStarted);
    } else if (mounted) {
      GlobalToast.error(
        _day.state.error?.spokenMessage ?? AuthStrings.errorGeneric,
      );
    }
  }

  /// Finish, having first shown the desk who has not photographed
  /// their pieces.
  ///
  /// **The day is RE-READ before the question is asked.** There is no
  /// push and no socket on this endpoint, and `pieces_count` moves
  /// because a customer uploaded a photograph on their own phone
  /// thirty seconds ago — so the list the desk opened this morning is
  /// the wrong one to send them chasing people with. The reload costs
  /// one request at the one moment it matters.
  ///
  /// If the session has gone from the day in the meantime — somebody
  /// finished it on another device — there is nothing left to finish
  /// and the refreshed screen already says so.
  Future<void> _finish(ScanSession session) async {
    await _day.load();
    if (!mounted) return;

    final fresh = _day.state.sessions
        .where(
          (s) =>
              s.workshopId == session.workshopId &&
              s.workshopSlotId == session.workshopSlotId,
        )
        .firstOrNull;
    if (fresh == null || !fresh.canFinish) {
      // Somebody finished it on another device while this desk was
      // looking at it. The refreshed card already shows that, but a
      // tap that produces nothing at all reads as the app ignoring
      // the press.
      GlobalToast.info(ScanStrings.sessionFinished);
      return;
    }

    final sure = await showFinishSessionSheet(
      context,
      missing: fresh.missingPieces,
    );
    if (!sure || !mounted) return;

    if (await _day.finish(session)) {
      if (mounted) GlobalToast.success(ScanStrings.sessionFinished);
    } else if (mounted) {
      GlobalToast.error(
        _day.state.error?.spokenMessage ?? AuthStrings.errorGeneric,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      // THE APP'S OWN BAR, not Material's.
      //
      // It was a plain `AppBar`, which gave the desk a different
      // typeface, a different height and square Material icon buttons
      // — a screen that looked like it came from somewhere else. Staff
      // are a different reader, not a different product.
      //
      // PINNED: the desk is worked, not browsed, and the day's date
      // and the two controls have to stay put while a queue is being
      // scanned through.
      appBar: TerracottaPageBar(
        title: ScanStrings.deskTitle,
        pinned: true,
        // NO CHEVRON. The desk is where staff land from sign-in and
        // the way out is signing out — a back arrow would point at the
        // login screen they just came through.
        showBack: false,
        // NO BELL, NO BASKET. Both belong to a customer: the inbox and
        // the cart are customer routes, and a scanner account gets 403
        // from either. Drawing them is a door into an app this reader
        // is not in.
        showShopActions: false,
        actions: [
          // GLYPHS in the app's own pill, not words: an app bar hands
          // its actions unbounded width, and a labelled button in one
          // asks to be infinitely wide. The sentence lives on the
          // tooltip, which is what a screen reader reads too.
          GlobalIconButton(
            iconData: Icons.refresh_rounded,
            onPressed: () => unawaited(_day.load()),
            tooltip: CommonStrings.retry,
            semanticLabel: CommonStrings.retry,
            size: ButtonSize.small,
            style: ButtonStateStyle(
              backgroundColor: TerracottaAppBar.plate(context),
              foregroundColor: TerracottaAppBar.glyph(context),
            ),
          ),
          GlobalIconButton(
            iconData: Icons.logout_rounded,
            onPressed: () => unawaited(_signOut()),
            tooltip: ScanStrings.signOut,
            semanticLabel: ScanStrings.signOut,
            size: ButtonSize.small,
            style: ButtonStateStyle(
              backgroundColor: TerracottaAppBar.plate(context),
              foregroundColor: TerracottaAppBar.glyph(context),
            ),
          ),
        ],
      ),
      // THE TWO WAYS IN, side by side and reachable whenever a code
      // can actually be taken.
      //
      // Typing the code is not a fallback buried in a menu: a phone
      // screen too dim to scan, a dead battery or a cracked lens all
      // end here, and at a desk with a queue behind it the second
      // option has to be one tap away. The camera is the wider of the
      // two because it is what a desk reaches for first.
      //
      // BOTH COME OFF THE SCREEN when nothing on the day can take a
      // check-in — a day that is not today (the server refuses any
      // other date), or one where every session has been finished
      // (Finish CLOSES check-in, so a code scanned against it answers
      // 422 whoever is standing there). A control whose only possible
      // outcome is an error is worse than no control, and the CMS
      // hides the same one in the same case.
      //
      // Its OWN `BlocBuilder`: a `floatingActionButton` is a property
      // of the `Scaffold`, not a child of the one wrapping the body,
      // so without this the buttons would keep whatever they were on
      // the frame the page was built in and never notice the day
      // arriving.
      floatingActionButton: BlocBuilder<ScanDayCubit, ScanDayState>(
        bloc: _day,
        builder: (context, _) => _canCheckInToday
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: FloatingActionButton.extended(
                        heroTag: 'desk-scan',
                        onPressed: () => unawaited(_scan()),
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: Text(ScanStrings.scanCode),
                      ),
                    ),
                    SizedBox(width: spacing.sm),
                    FloatingActionButton(
                      heroTag: 'desk-type',
                      onPressed: () => unawaited(_type()),
                      backgroundColor: context.backgroundColors.container,
                      foregroundColor: context.primaryColors.primary,
                      tooltip: ScanStrings.enterCode,
                      child: const Icon(Icons.keyboard_alt_outlined),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: BlocBuilder<ScanDayCubit, ScanDayState>(
        bloc: _day,
        builder: (context, state) {
          // THE DAY BAR STAYS UP while a day loads.
          //
          // A full-page spinner took the chevrons away with it, so the
          // desk could not step on to the next day until the last one
          // had finished arriving — and had nothing on screen saying
          // which day it was waiting for.
          if (state.error != null && !state.hasData) {
            return Center(
              child: GlobalEmptyState(
                icon: Icons.wifi_off_rounded,
                title: AuthStrings.errorGeneric,
                subtitle: state.error?.message,
                primaryAction: GlobalFilledButton(
                  text: CommonStrings.retry,
                  onPressed: () => unawaited(_day.load()),
                  style: terracottaCtaStyle(showArrow: false),
                ),
              ),
            );
          }

          return GlobalRefreshable(
            onRefresh: _day.load,
            child: GlobalScrollable(
              // A day with nothing on it still has to be pullable —
              // the desk's first act each morning is to check.
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  spacing.md,
                  spacing.md,
                  spacing.md,
                  // Clear of the scan button.
                  spacing.md + 88,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // WHICH DAY, and a way to another one. The
                    // sessions endpoint takes a date; the desk was
                    // stuck on today with no way to check tomorrow's
                    // list or look back at yesterday's.
                    _DayBar(
                      date: _day.shownDate,
                      isToday: _day.isToday,
                      onPrevious: () => unawaited(_day.shiftDay(-1)),
                      onNext: () => unawaited(_day.shiftDay(1)),
                      onToday: () => unawaited(_day.goToToday()),
                    ),
                    SizedBox(height: spacing.md),
                    if (state.loading && !state.hasData)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 64),
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      )
                    else if (state.sessions.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: spacing.xxl),
                        child: GlobalEmptyState(
                          icon: Icons.event_busy_rounded,
                          // WHICH DAY IS EMPTY. The strip moves a week
                          // either way and this said «اليوم» whatever
                          // it was showing — a true sentence about the
                          // wrong date.
                          title: ScanStrings.noSessions(today: _day.isToday),
                          subtitle: ScanStrings.noSessionsBody(
                            today: _day.isToday,
                          ),
                        ),
                      )
                    else
                      for (final session in state.sessions) ...[
                        ScanSessionCard(
                          session: session,
                          working: state.working,
                          // START AND FINISH ARE TODAY'S ONLY. The
                          // server refuses any other day with a 422,
                          // so offering the buttons on tomorrow's list
                          // would be offering an error.
                          canRun: _day.isToday,
                          onStart: () => unawaited(_start(session)),
                          onFinish: () => unawaited(_finish(session)),
                        ),
                        SizedBox(height: spacing.md),
                      ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Which day the desk is looking at, and the way to another.
class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.date,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final String date;
  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              // The `_rounded` pair MIRRORS: "previous" is on the
              // right in Arabic and the left in English, and these two
              // arrows swap together with the language.
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: ScanStrings.previousDay,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatBookingDate(date, locale),
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.textColors.primary,
                    ),
                  ),
                  if (isToday)
                    Text(
                      ScanStrings.today,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.primaryColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: ScanStrings.nextDay,
            ),
          ],
        ),
        // Only when it is worth saying: on today the controls are
        // there and there is nothing to explain.
        if (!isToday) ...[
          SizedBox(height: context.spacing.xs),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: context.iconSizes.sm,
                color: context.statusColors.warning,
              ),
              SizedBox(width: context.spacing.xs),
              Expanded(
                child: Text(
                  ScanStrings.notToday,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.statusColors.warning,
                  ),
                ),
              ),
              TextButton(
                onPressed: onToday,
                child: Text(ScanStrings.backToToday),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Digits, localized for display only.
String scanDigits(int value) => AppNumbers.localizeDigits('$value');

/// Re-exported so the desk's widgets share one import.
typedef DeskScanResult = ScanResult;
