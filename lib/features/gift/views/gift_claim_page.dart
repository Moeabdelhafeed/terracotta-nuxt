import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_gate.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/gift_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/commerce/gift_preview.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_text_button.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/celebration_confetti.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';
import '../cubits/gift_claim_cubit.dart';
import '../data/pending_gift.dart';
import '../widgets/gift_hero_card.dart';

/// «هدية لك» — the screen a share link opens.
///
/// ## Who is standing here
///
/// Usually somebody with no account, who has never opened this app
/// before and has just installed it because a friend sent them a link.
/// That shapes everything:
///
///  * **The gift is shown BEFORE the account is asked for.** `GET
///    /api/gifts/{token}` is public, so the page can say what they have
///    been given and who sent it while they are still a stranger.
///    Bouncing them to a sign-up form first asks them to trust an app
///    they have not seen for a gift they cannot see.
///  * **The gate is at the Claim button**, which is where the app puts
///    every other gate. Signing in from there comes back HERE rather
///    than to home, which is what `PendingGift` is for.
///  * **There is no back button.** A launch from a link has nothing
///    behind it, and a chevron into an empty stack is a dead control.
///    The way out is «تصفح الاستوديو», which is a real destination.
///
/// ## Claiming
///
/// `POST /api/gifts/{token}/redeem` needs a session and answers 401
/// without one — and a 401 in this app is the session ending, so the
/// button must never fire for a signed-out reader. [AuthGate.demand]
/// is what stops it.
class GiftClaimPage extends StatefulWidget {
  const GiftClaimPage({required this.token, this.cubit, super.key});

  /// The share token out of `terracotta://gift/{token}`.
  final String token;

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final GiftClaimCubit? cubit;

  @override
  State<GiftClaimPage> createState() => _GiftClaimPageState();
}

class _GiftClaimPageState extends State<GiftClaimPage> {
  late final GiftClaimCubit _gift =
      widget.cubit ?? GiftClaimCubit(token: widget.token);

  @override
  void initState() {
    super.initState();
    // TAKEN, not peeked: the link has arrived where it was going, and
    // leaving it parked would re-open this screen on the next sign-in.
    PendingGift.take();
    unawaited(_gift.load());
  }

  @override
  void dispose() {
    // OURS, unlike the tab cubits — this page is pushed, it is not a
    // destination anyone returns to, and one gift is one screen.
    if (widget.cubit == null) unawaited(_gift.close());
    super.dispose();
  }

  Future<void> _claim() async {
    // NO SESSION, NO CALL. `redeem` answers 401 without one, and a 401
    // here is `SessionExpiry` clearing the token and re-running the
    // guards — so an ungated tap would sign the reader out rather than
    // tell them to sign in. `PendingGift` is what brings them back.
    PendingGift.remember(widget.token);
    final signedIn = await AuthGate.demand(context);
    if (!signedIn || !mounted) return;

    await _gift.claim();
    if (!mounted) return;

    // The server's own sentence, already localized. Shown as a toast
    // rather than inline because the page under it has just reloaded
    // and says the same thing in its own state.
    if (_gift.state.refusal case final refusal?) GlobalToast.error(refusal);
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<GiftClaimCubit, GiftClaimState>(
        bloc: _gift,
        builder: (context, state) => Scaffold(
          backgroundColor: context.backgroundColors.scaffoldBackground,
          appBar: TerracottaPageBar(
            title: GiftStrings.claimTitle,
            // NOTHING BEHIND IT. The app was launched by the link, so
            // the stack is empty and a chevron would do nothing.
            showBack: Navigator.of(context).canPop(),
            showShopActions: false,
          ),
          body: _Body(
            state: state,
            onClaim: () => unawaited(_claim()),
            onRetry: () => unawaited(_gift.load()),
          ),
        ),
      );
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.onClaim,
    required this.onRetry,
  });

  final GiftClaimState state;
  final VoidCallback onClaim;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.gift == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    // NOTHING TO SHOW. A 404 is the common one and it is not a network
    // problem, so it gets its own sentence and a way onward rather
    // than a Retry that will fail identically.
    //
    // SINCE 2026-09-13 IT IS ALSO THE UNPAID CASE. A gift row exists
    // the moment the buyer taps Send, and its link used to resolve
    // straight away reporting `is_claimable: true` — so the recipient
    // opened it, tapped claim, and was refused by a 422. The preview
    // was the lie, and the server now answers 404 for a gift that is
    // unpaid or cancelled. Nothing tells the two apart from here,
    // which is why the sentence names both possibilities.
    if (state.gift == null) {
      final missing = state.error is NotFoundException;
      return _CentredInPage(
        child: GlobalEmptyState(
          icon: missing ? Icons.card_giftcard_rounded : Icons.wifi_off_rounded,
          title: missing ? GiftStrings.claimNotFound : AuthStrings.errorGeneric,
          subtitle: missing ? null : state.error?.message,
          primaryAction: GlobalFilledButton(
            text: missing ? GiftStrings.claimBrowse : CommonStrings.retry,
            onPressed: missing ? () => context.goNamed('home') : onRetry,
            style: terracottaCtaStyle(showArrow: false),
          ),
        ),
      );
    }

    final gift = state.gift!;
    final done = state.redeemed;

    // CLAIMED, JUST NOW — the same celebration the rest of the app
    // uses, because this is the moment the gift becomes theirs.
    final page = GlobalRefreshable(
      onRefresh: () async => onRetry(),
      child: GlobalScrollable(
        physics: const AlwaysScrollableScrollPhysics(),
        child: GlobalContainer.prose(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: context.spacing.md),
              ScreenEntrance(child: GiftHeroCard(amount: gift.amount)),
              SizedBox(height: context.spacing.lg),
              ScreenEntrance(step: 1, child: _Note(gift: gift)),
              SizedBox(height: context.spacing.lg),
              ScreenEntrance(
                step: 2,
                child: _Action(
                  state: state,
                  onClaim: onClaim,
                ),
              ),
              SizedBox(height: context.spacing.xl),
            ],
          ),
        ),
      ),
    );

    return done == null ? page : CelebrationConfetti(child: page);
  }
}

/// Who it is from, who it is for, and what they wrote.
class _Note extends StatelessWidget {
  const _Note({required this.gift});

  final GiftPreview gift;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final text = context.textColors;

    return TerracottaCard(
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            GiftStrings.claimTo(gift.recipientName),
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(
              color: text.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (gift.message.isNotEmpty) ...[
            SizedBox(height: spacing.sm),
            Text(
              // The buyer's own words. Never translated, never trimmed
              // to a line — a note is the point of a gift.
              gift.message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: text.secondary,
                height: 1.6,
              ),
            ),
          ],
          if (gift.from.isNotEmpty) ...[
            SizedBox(height: spacing.md),
            Text(
              GiftStrings.claimFrom(gift.from),
              textAlign: TextAlign.center,
              style: context.textTheme.labelLarge?.copyWith(
                color: context.primaryColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The one control, in whichever of its three states applies.
class _Action extends StatelessWidget {
  const _Action({required this.state, required this.onClaim});

  final GiftClaimState state;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final gift = state.gift!;

    // ALREADY IN THE WALLET — this run claimed it. The balance is the
    // number worth printing: it answers "what do I have now".
    if (state.redeemed case final done?) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            GiftStrings.claimDoneTitle,
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(
              color: context.statusColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            GiftStrings.claimDoneBody(
              PriceText.format(done.amount),
              PriceText.format(done.walletBalance),
            ),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
          SizedBox(height: spacing.lg),
          GlobalFilledButton(
            text: GiftStrings.claimOpenWallet,
            onPressed: () => context.goNamed('wallet'),
            style: terracottaCtaStyle(showArrow: false),
          ),
        ],
      );
    }

    // NOT CLAIMABLE. `is_claimable` is the only thing read here — it
    // is not `!is_redeemed`, because a gift can also be switched off
    // or be the reader's own purchase. Offering a button the server
    // will refuse is worse than not offering one.
    //
    // UNPAID no longer reaches this branch: it 404s above. This is
    // still the right gate, because it is the server's own answer to
    // "may this person claim this gift" and there will be other
    // reasons for it to say no.
    if (!gift.isClaimable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            gift.isRedeemed
                ? GiftStrings.claimAlready
                : GiftStrings.claimUnavailable,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
          SizedBox(height: spacing.lg),
          GlobalTextButton(
            text: GiftStrings.claimBrowse,
            onPressed: () => context.goNamed('home'),
          ),
        ],
      );
    }

    final signedIn = AuthGate.watch(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlobalFilledButton(
          text: GiftStrings.claimCta,
          isLoading: state.claiming,
          onPressed: state.claiming ? null : onClaim,
          style: terracottaCtaStyle(showArrow: false),
        ),
        // SAID, not enforced by hiding the button. The gate is at the
        // tap; this only warns them what the tap will ask for.
        if (!signedIn) ...[
          SizedBox(height: spacing.sm),
          Text(
            GiftStrings.claimSignedOut,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// The empty state, in the middle of what is left of the screen.
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
