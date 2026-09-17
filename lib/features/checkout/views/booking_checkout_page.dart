import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/auth/account_scope.dart';
import '../../../core/auth/auth_gate.dart';
import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/localization/strings/checkout_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/workshop/workshop.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/image/global_image.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../booking/data/picked_piece.dart';
import '../../booking/widgets/celebration_bar.dart';
import '../../booking/widgets/celebration_upsell_sheet.dart';
import '../../booking/widgets/clock_time.dart';
import '../../booking/widgets/selected_pieces_sheet.dart';
import '../../profile/cubits/wallet_cubit.dart';
import '../../profile/cubits/wallet_state.dart';
import '../../workshops/cubits/workshops_cubit.dart';
import '../../workshops/cubits/workshops_state.dart';
import '../../workshops/widgets/booking_card.dart';
import '../cubits/booking_checkout_cubit.dart';
import '../widgets/checkout_widgets.dart';
import '../widgets/wallet_toggle.dart';

/// «الدفع» for a workshop booking.
///
/// **Never compute the total here.** `GET /api/workshops/{id}/price` is
/// the quote and must be re-called on EVERY change — party size, the
/// celebration toggle, the pieces picked, a discount code. Celebration
/// fees, wallet credit and discounts are applied server-side in a fixed
/// order, and a locally-summed total will disagree with the charge.
///
/// Then `POST .../bookings` CREATES the booking unpaid and holds the
/// seat, and `POST .../bookings/{id}/pay` settles it — unless
/// `amount_due` is already `"0.00"`, in which case the pay call is
/// skipped entirely.
///
/// What the schedule screen hands the checkout: everything it already
/// knew, so this screen asks for none of it again.
@immutable
class BookingCheckoutArgs {
  const BookingCheckoutArgs({
    required this.workshopId,
    required this.title,
    required this.people,
    this.workshopSlotId,
    this.date,
    this.startTime,
    this.endTime,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
    this.products = const [],
    this.pieces = const [],
    this.cancelUntilDate,
    this.cancelUntilClock,
    this.cancellable = true,
  });

  final int workshopId;

  /// The workshop's own name as the schedule screen had it. A FALLBACK
  /// only: the server writes this, so the live one is read from the
  /// catalogue, which re-asks when the language changes.
  final String title;

  /// RAW, not a sentence.
  ///
  /// The meta line used to travel already composed, in the language the
  /// schedule screen was in — so switching language on the checkout
  /// left «٢ أشخاص · الثلاثاء…» sitting under an English page. These
  /// are the facts; the words are built at paint time, in whatever
  /// language that is.
  final int people;

  /// The session that was chosen — what the quote is priced against
  /// and what the booking reserves. Null after a hot restart, where a
  /// route extra does not survive.
  final int? workshopSlotId;

  /// `Y-m-d`, and the session's Asia/Riyadh wall clock.
  final String? date;
  final String? startTime;
  final String? endTime;

  /// The chosen session's cancellation deadline, on the STUDIO's
  /// clock — `Y-m-d` and `HH:mm`, exactly as the server wrote them.
  ///
  /// Kept as STRINGS because that is what they are. `cancel_until`
  /// arrives with the studio's offset (`…T13:00:00+03:00`), and
  /// `DateTime.parse` converts an offset-bearing string to UTC — so
  /// parsing it to print it turned 13:00 in Riyadh into 10:00 and told
  /// a customer their deadline was three hours earlier than it is.
  final String? cancelUntilDate;
  final String? cancelUntilClock;

  /// Whether that session can be called off at all
  /// (`is_non_cancellable`, inverted). The schedule screen has already
  /// warned when this is false; the note here is the reminder on the
  /// screen that takes the money.
  final bool cancellable;

  final WorkshopFamily family;
  final String? wireColor;

  /// The catalogue lines, `{workshop_product_id, quantity}` each.
  ///
  /// Empty on `make_your_piece`, which is a flat rate per person and
  /// never sees the catalogue screen. On the two catalogue types these
  /// REPLACE the seat price entirely — the workshop's own `price` is
  /// `"0.00"` there — so a quote sent without them prices the booking
  /// at nothing.
  final List<Map<String, dynamic>> products;

  /// The picked products THEMSELVES, for the screens that show them
  /// rather than send them.
  ///
  /// [products] is the wire shape and carries ids alone, so a checkout
  /// handed only that could name nothing and price nothing. These
  /// travel beside it rather than being fetched again — the catalogue
  /// screen has the rows in hand at the moment it pushes.
  final List<PickedPiece> pieces;

  /// The same booking with the pieces the catalogue screen collected.
  ///
  /// The wire lines are derived HERE, from the same rows, so the two
  /// can never disagree about what was chosen.
  BookingCheckoutArgs withPieces(List<PickedPiece> picked) =>
      BookingCheckoutArgs(
        workshopId: workshopId,
        title: title,
        people: people,
        workshopSlotId: workshopSlotId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        family: family,
        wireColor: wireColor,
        cancelUntilDate: cancelUntilDate,
        cancelUntilClock: cancelUntilClock,
        cancellable: cancellable,
        pieces: picked,
        // Each line is EITHER a catalogue product with a quantity or
        // one of the customer's own pieces — never both, which is the
        // server's own rule.
        products: [for (final piece in picked) piece.toLine()],
      );
}

/// Bound to [BookingCheckoutCubit]: every figure on it is the server's
/// answer to `GET /api/workshops/{id}/price`, re-asked on every change,
/// and the button runs HOLD then SETTLE.
class BookingCheckoutPage extends StatefulWidget {
  const BookingCheckoutPage({
    this.args,
    this.cubit,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
    this.title = '',
    this.people = 1,
    super.key,
  });

  /// Everything the schedule screen knew. Null after a hot restart,
  /// where a route extra does not survive — the fields below are the
  /// fallback rather than a throw.
  final BookingCheckoutArgs? args;

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page quotes on mount. Null in the app.
  final BookingCheckoutCubit? cubit;

  final WorkshopFamily family;
  final String? wireColor;

  /// The workshop's own name, and how many are coming.
  final String title;
  final int people;

  String get effectiveTitle => args?.title ?? title;
  int get effectivePeople => args?.people ?? people;
  WorkshopFamily get effectiveFamily => args?.family ?? family;
  String? get effectiveWireColor => args?.wireColor ?? wireColor;

  @override
  State<BookingCheckoutPage> createState() => _BookingCheckoutPageState();
}

class _BookingCheckoutPageState extends State<BookingCheckoutPage> {
  late final _checkout =
      (widget.cubit ??
      BookingCheckoutCubit(
        workshopId: '${widget.args?.workshopId ?? 0}',
        workshopSlotId: widget.args?.workshopSlotId ?? 0,
        bookingDate: widget.args?.date ?? '',
        peopleCount: widget.effectivePeople,
        products: widget.args?.products ?? const [],
      ));

  /// Whether the first load has gone out.
  ///
  /// It happens in `didChangeDependencies` rather than in the field
  /// above, because whether there is an ACCOUNT decides half of it —
  /// the promo list is the caller's own and answers 401 to a guest —
  /// and `AuthGate` needs a context.
  bool _asked = false;

  /// The app's catalogue, for the workshop's NAME.
  late final _catalogue = getIt<WorkshopsCubit>();

  /// The BALANCE the toggle offers to spend. The quote answers how much
  /// of it this booking takes, not how much there is.
  /// NOT loaded here. `ensureLoaded` on mount asked the server for a
  /// balance the moment the page opened — and for a guest that is a
  /// 401, which `SessionExpiry` reads as the session ending and answers
  /// by evicting them to sign-in. The whole point of this screen being
  /// public is that it does not do that.
  late final _wallet = getIt<WalletCubit>();

  @override
  void dispose() {
    // Only what this page MADE.
    if (widget.cubit == null) unawaited(_checkout.close());
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The title is server-localized, so it only re-says itself when the
    // catalogue is asked again — which `ensureLoaded` does when the
    // language differs from the one its rows arrived in.
    unawaited(
      _catalogue.ensureLoaded(Localizations.localeOf(context).languageCode),
    );
    if (!_asked) {
      _asked = true;
      unawaited(_checkout.load(signedIn: AuthGate.has(context)));
    }
    // ONLY WITH AN ACCOUNT — see the `_wallet` field. A guest has no
    // balance to read, and asking for one is a 401 that evicts them.
    if (AuthGate.has(context)) unawaited(_wallet.ensureLoaded());
  }

  /// The catalogue row this booking is against, once the catalogue has
  /// landed. Null before that, and after a hot restart where the route
  /// extra carrying the id did not survive.
  Workshop? get _workshop {
    final id = widget.args?.workshopId;
    final state = _catalogue.state;
    if (id == null || state is! WorkshopsLoaded) return null;
    for (final workshop in state.workshops) {
      if (workshop.id == id) return workshop;
    }
    return null;
  }

  /// The workshop's name, in the language on screen; the one the
  /// schedule screen handed over until the catalogue has it.
  String get _title => _workshop?.title ?? widget.effectiveTitle;

  /// What adding a celebration costs.
  ///
  /// The QUOTE is the authority — the server prices it whether or not
  /// it was taken, so the choice can be costed before it is made. But
  /// the quote lands a request after the screen does, and «اضافة
  /// احتفال ٠٫٠٠ ريال» in that gap reads as a free extra rather than
  /// as a figure that has not arrived. The catalogue row carries
  /// `celebration_price` for the same workshop, so it stands in until
  /// the quote answers.
  String get _celebrationPrice {
    final quoted = _checkout.state.quote?.celebrationPrice;
    if (quoted != null && quoted != '0.00') return quoted;
    return _workshop?.celebrationPrice ?? quoted ?? '0.00';
  }

  Future<void> _toggleCelebration() async {
    // The sheet ANSWERS. It used to return nothing and this toggled
    // regardless, so dismissing it by tapping outside — or pressing
    // «اغلاق» — added the celebration anyway.
    final said = await showCelebrationSheet(
      context,
      price: _celebrationPrice,
      added: _checkout.state.celebration,
    );
    if (!said || !mounted) return;
    _checkout.toggleCelebration(!_checkout.state.celebration);
  }

  /// HOLD, then SETTLE — one press to the customer, two calls to the
  /// server, and only one of them when the wallet already covered it.
  Future<void> _confirm() async {
    // THE ONE STEP THAT NEEDS AN ACCOUNT.
    //
    // Everything up to here is public — the availability and the price
    // both answer a guest — so the reader has picked a date, chosen
    // their seats and seen a real total before this asks. It reserves
    // a seat against a person, which is where a person becomes
    // necessary.
    //
    // The copy says what happens to the ten minutes they just spent,
    // because that is the only question anyone has at this button.
    final signedIn = await AuthGate.demandToFinish(
      context,
      because: AuthStrings.needAccountBooking,
    );
    if (!signedIn || !mounted) return;

    // AND A CONFIRMED NUMBER. The server issues a session before the
    // code is entered under `REGISTER_REQUIRES_VERIFICATION`, so an
    // account alone is not enough to book — see
    // `AuthGate.demandVerified`. Asked HERE rather than at the door,
    // for the same reason the account is.
    final verified = await AuthGate.demandVerified(
      context,
      because: AuthStrings.verifyNeededBook,
    );
    if (!verified || !mounted) return;

    final booking = await _checkout.confirm();
    if (!mounted) return;

    if (booking == null) {
      // A hold that RAN OUT gave the seat back, so the customer is told
      // to start again rather than shown a server key. Anything else
      // is said in the server's own words.
      GlobalToast.error(
        _checkout.state.holdExpired
            ? CheckoutStrings.holdExpired
            : _checkout.state.error?.spokenMessage ?? AuthStrings.errorGeneric,
      );
      return;
    }
    // The reader now has a booking they did not have a moment ago.
    // «ورشاتي» and the live strips read `getIt` singletons that only
    // re-ask on a language change, so without this the new booking did
    // not appear until the app was killed and reopened.
    AccountScope.ownedChanged();
    // THE BOOKING'S OWN DEADLINE travels with it. The page used to say
    // "within 3 hours of confirming" — a constant, and measured from
    // the wrong event: the window is the workshop's
    // `cancellation_window_hours` counted back from the SESSION.
    context.pushNamed(
      'booking-confirmed',
      // A MAP, because the page needs two things now: which booking to
      // open, and when the right to cancel it runs out.
      extra: {
        'bookingId': booking.id,
        'editableUntil': booking.editableUntil,
      },
    );
  }

  /// What the catalogue screen picked, if this booking went through
  /// one. Empty on `make_your_piece`, and after a hot restart.
  List<PickedPiece> get _pieces => widget.args?.pieces ?? const [];

  int get _pieceCount => _pieces.fold(0, (sum, line) => sum + line.quantity);

  /// «شخص واحد · الخميس ٣ سبتمبر · ورشة من ٧ م الى ٨ م».
  ///
  /// Built at PAINT time from the raw facts, so a language switch
  /// re-says it. Composed at push time it kept the language the
  /// schedule screen was in.
  String get _meta {
    final args = widget.args;
    final locale = Localizations.localeOf(context).toString();
    final day = args?.date == null
        ? ''
        : DateFormat.MMMMEEEEd(locale).format(DateTime.parse(args!.date!));

    return BookingStrings.meta(
      BookingStrings.party(widget.effectivePeople),
      day,
      args == null
          ? ''
          : BookingStrings.slotLabel(
              formatClock(args.startTime, locale),
              formatClock(args.endTime, locale),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final fam = WorkshopFamilyColors.resolve(
      family: widget.effectiveFamily,
      isDark: context.isDarkMode,
      wireColor: widget.effectiveWireColor,
    );

    return BlocBuilder<WorkshopsCubit, WorkshopsState>(
      bloc: _catalogue,
      // Watched only for the TITLE on the card below.
      builder: (context, _) =>
          BlocBuilder<BookingCheckoutCubit, BookingCheckoutState>(
            bloc: _checkout,
            builder: (context, quote) => Scaffold(
              backgroundColor: context.backgroundColors.scaffoldBackground,
              appBar: TerracottaPageBar(
                title: CheckoutStrings.title,
                pinned: true,
              ),
              body: GlobalScrollable(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    // STAGGERED as the page settles.
                    //
                    // The pinned CTA at the foot is NOT in here: a hero
                    // flies it between the steps of this flow, and an
                    // entrance replaying on top of a landed flight is the
                    // thing `ScreenEntrance` stands down for.
                    children: ScreenEntrance.stage([
                      SizedBox(height: spacing.md),
                      // The bar is BEHIND the card and slides out from under
                      // its top edge.
                      //
                      // A real `Stack`, so the card paints OVER the bar's
                      // foot — the two are one block, not a strip resting on
                      // a card. What animates is how far the bar has
                      // travelled up out of it; the card itself never moves,
                      // which is the difference between this and pushing it
                      // down by a bar's height.
                      _CelebrationHeader(
                        added: quote.celebration,
                        onTap: _toggleCelebration,
                        card: BookingCard(
                          title: _title,
                          meta: _meta,
                          price: quote.quote?.totalPrice ?? '0.00',
                          family: widget.effectiveFamily,
                          wireColor: widget.effectiveWireColor,
                        ),
                      ),
                      // Only on a booking whose price CAME from a catalogue.
                      // On a flat-rate workshop there is nothing picked to
                      // show, and the bar would open an empty sheet.
                      if (_pieces.isNotEmpty) ...[
                        SizedBox(height: spacing.md),
                        GlobalFilledButton(
                          text: BookingStrings.selectedPieces(_pieceCount),
                          onPressed: () => showSettledPiecesSheet(
                            context,
                            lines: _pieces,
                            tint: fam.primary,
                          ),
                          style: terracottaCtaStyle(showArrow: false).copyWith(
                            backgroundColor: fam.container,
                            textStyle: TextStyle(
                              fontSize: kTerracottaCtaLabelSize,
                              color: fam.primary,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: spacing.md),
                      _Lines(
                        celebration: quote.celebration,
                        title: _title,
                        people: BookingStrings.party(widget.effectivePeople),
                        // The SERVER's figures. The subtotal is the goods
                        // before the discount; the celebration is quoted
                        // whether or not it was taken, so the choice can be
                        // priced before it is made.
                        workshopPrice: quote.quote?.subtotal ?? '0.00',
                        celebrationPrice: _celebrationPrice,
                      ),
                      SizedBox(height: spacing.md),
                      // THE PROMO CODE. Applying one re-quotes rather
                      // than validating: the figure the create step
                      // charges is the one this screen has to show, and
                      // `POST /discount-codes/validate` prices the
                      // goods alone.
                      //
                      // THE WHOLE SECTION GOES when the studio is
                      // advertising nothing — see [DiscountCodeList].
                      // A guest has no list to read either, and an
                      // empty box under a heading asks the reader for
                      // something the studio has not offered.
                      if (quote.codes.isNotEmpty) ...[
                        DiscountCodeField(
                          applied: quote.discountCode,
                          error: quote.discountError,
                          // The WORKSHOP's line, on the apply button
                          // and on the ticket edges below it.
                          tint: fam.primary,
                          onApply: _checkout.applyDiscount,
                        ),
                        SizedBox(height: spacing.sm),
                        DiscountCodeList(
                          codes: quote.codes,
                          applied: quote.discountCode,
                          tint: fam.primary,
                          onPick: _checkout.applyDiscount,
                        ),
                        SizedBox(height: spacing.md),
                      ],
                      PaymentMethodRow(
                        selected: quote.method,
                        // THE WORKSHOP'S COLOUR, like everything else
                        // this flow has carried from the catalogue.
                        tint: fam.primary,
                        onSelect: _checkout.selectMethod,
                      ),
                      SizedBox(height: spacing.md),
                      // The balance is the WALLET's; what this booking
                      // takes off it and what is left are the QUOTE's.
                      // Neither is computed here.
                      //
                      // NOT DRAWN FOR A GUEST. A wallet belongs to an
                      // account, and there is no such thing as a
                      // visitor's balance — a toggle offering to spend
                      // one would be offering nothing, and drawing it
                      // at «٠٫٠٠» reads as an empty purse rather than
                      // as no purse. It appears when they sign in at
                      // the seat, with whatever they actually have.
                      if (AuthGate.watch(context))
                        BlocBuilder<WalletCubit, WalletState>(
                          bloc: _wallet,
                          builder: (context, purse) => WalletToggle(
                            balance: purse.balance ?? '0.00',
                            applied: quote.quote?.walletApplied ?? '0.00',
                            due: quote.quote?.amountDue ?? '0.00',
                            enabled: quote.useWallet,
                            onChanged: _checkout.toggleWallet,
                          ),
                        ),
                      // WHAT HAPPENS IF THEY CHANGE THEIR MIND.
                      //
                      // Said on the screen that takes the money, not
                      // afterwards on one that has no «الغاء» button.
                      // The deadline is the SESSION's, and the refund
                      // goes to the Terracotta balance rather than
                      // back to a card — which is the part nobody
                      // guesses.
                      SizedBox(height: spacing.md),
                      _CancelNote(
                        date: widget.args?.cancelUntilDate,
                        clock: widget.args?.cancelUntilClock,
                        cancellable: widget.args?.cancellable ?? true,
                      ),
                      // «الملخص» — every figure the server's own.
                      //
                      // Nothing here is summed on this side: the
                      // discount comes off the goods, the celebration
                      // is added, then the wallet covers what it can,
                      // in that order. An app-side total disagrees
                      // with what is charged.
                      if (quote.quote case final priced?) ...[
                        SizedBox(height: spacing.md),
                        QuoteBreakdown(
                          subtotal: priced.subtotal,
                          discount: priced.discountAmount,
                          deliveryFee: priced.deliveryFee,
                          vatRate: priced.vatRate,
                          total: priced.totalPrice,
                          walletApplied: priced.walletApplied,
                          amountDue: priced.amountDue,
                        ),
                      ],
                      SizedBox(height: spacing.xxl),
                    ]),
                  ),
                ),
              ),
              // PINNED. The summary grows with the booking, and a confirm
              // button at the foot of it is one the customer has to go looking
              // for.
              bottomNavigationBar: Material(
                color: context.backgroundColors.scaffoldBackground,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      spacing.md,
                      spacing.sm,
                      spacing.md,
                      spacing.sm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Only when there is one to ADD. Taking it off again is
                        // done on the bar over the card, where the thing it
                        // affects is.
                        if (!quote.celebration) ...[
                          CelebrationBar(
                            added: false,
                            onTap: _toggleCelebration,
                          ),
                          SizedBox(height: spacing.sm),
                        ],
                        SharedHero(
                          tag: HeroTag.bookingCta,
                          exitsWithRoute: true,
                          child: GlobalFilledButton(
                            text: CheckoutStrings.confirmAndPay,
                            enabled: quote.canSubmit,
                            isLoading: quote.paying,
                            onPressed: () => unawaited(_confirm()),
                            // The auth CTA's bar, in the WORKSHOP's colour — the
                            // whole flow is themed by it, with the chosen
                            // wallet's own mark in the arrow's slot so the button
                            // says which of the three above it will charge.
                            style: terracottaCtaStyle(showArrow: false)
                                .copyWith(
                                  backgroundColor: fam.primary,
                                  trailing: SizedBox(
                                    height: 18,
                                    child: GlobalImage.a(
                                      PaymentMethodRow.brands[quote.method],
                                      placeholder: const SizedBox.shrink(),
                                      style: ImageStyle(
                                        fit: BoxFit.contain,
                                        borderRadius: BorderRadius.zero,
                                        color: context.textColors.onPrimary,
                                        overlayBlendMode: BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

/// «ألغِ قبل … ويعود المبلغ كاملاً إلى رصيدك».
///
/// Two sentences, and which one appears is the whole point: a session
/// that can still be called off says by when and what comes back, and
/// one that cannot says so plainly rather than staying silent and
/// letting the customer find out on a detail page with no button.
class _CancelNote extends StatelessWidget {
  const _CancelNote({
    required this.date,
    required this.clock,
    required this.cancellable,
  });

  /// `Y-m-d` and `HH:mm` on the STUDIO's clock, as sent.
  final String? date;
  final String? clock;
  final bool cancellable;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final canStill = cancellable && date != null && clock != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          canStill ? Icons.info_outline_rounded : Icons.lock_clock_outlined,
          size: context.iconSizes.sm,
          color: canStill
              ? context.textColors.secondary
              : context.statusColors.warning,
        ),
        SizedBox(width: context.spacing.xs),
        Expanded(
          child: Text(
            canStill
                // Asia/Riyadh as the server wrote it — the studio's
                // clock is the one the window is measured on, and
                // re-expressing it in the reader's would move the
                // deadline by the offset between them.
                ? BookingStrings.cancelPolicy(
                    '${formatBookingDate(date!, locale)}'
                    ' · '
                    '${formatClock(clock!, locale)}',
                  )
                : BookingStrings.cancelPolicyNone,
            style: context.textTheme.bodySmall?.copyWith(
              color: canStill
                  ? context.textColors.secondary
                  : context.statusColors.warning,
            ),
          ),
        ),
      ],
    );
  }
}

/// What the booking is made of, line by line.
class _Lines extends StatelessWidget {
  const _Lines({
    required this.celebration,
    required this.title,
    required this.people,
    required this.workshopPrice,
    required this.celebrationPrice,
  });

  final bool celebration;
  final String title;

  /// «٢ اشخاص», already composed by the screen that knows the count.
  final String people;

  /// Decimal STRINGS from the quote, once it is wired.
  final String workshopPrice;
  final String celebrationPrice;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return TerracottaCard(
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        children: [
          _Line(
            // What is being PAID FOR — the workshop and the party. It
            // read «اختر موعد», which is the heading of the screen
            // before this one and says nothing about the charge.
            label: CheckoutStrings.workshopLine(title, people),
            price: workshopPrice,
          ),
          if (celebration) ...[
            SizedBox(height: spacing.md),
            _Line(
              label: BookingStrings.addCelebration,
              price: celebrationPrice,
              // The add-on reads in the accent, as the design draws it
              // — it is the line the customer chose to add.
              tint: context.primaryColors.accent,
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.price, this.tint});

  final String label;
  final String price;
  final Color? tint;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.textColors.primary,
          ),
        ),
      ),
      // Money stays a decimal STRING the whole way — a double rounds
      // totals wrong on this API.
      PriceText(amount: price, color: tint),
    ],
  );
}

/// The celebration bar, stacked BEHIND the booking card.
///
/// The bar does not push the card anywhere. It starts fully hidden
/// under the card's top edge and travels up out of it, and the card
/// paints over whatever is left underneath — so the two read as one
/// block rather than as a strip resting on a card.
class _CelebrationHeader extends StatelessWidget {
  const _CelebrationHeader({
    required this.added,
    required this.onTap,
    required this.card,
  });

  final bool added;
  final VoidCallback onTap;
  final Widget card;

  /// How much of the bar stays tucked under the card — the same number
  /// the bar itself offsets its label by, so the two cannot drift.
  static const _tuck = CelebrationBar.tuckedFoot;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: added ? 1 : 0),
    duration: AppDurations.normal,
    curve: Curves.easeOutCubic,
    builder: (context, t, child) {
      // What the bar contributes to the block's height: nothing when
      // it is away, its own height less the tuck when it is out.
      final shown = (CelebrationBar.tuckedHeight - _tuck) * t;

      return Stack(
        children: [
          // FIRST, so the card paints over it. And only while there is
          // any of it to see: fully away is OUT of the tree, not
          // zero-height in it — a bar clipped to nothing is still one a
          // screen reader announces.
          if (t > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: Align(
                  alignment: AlignmentDirectional.bottomCenter,
                  heightFactor: t,
                  // No SizedBox: the BAR owns its height, so there is
                  // one number and it cannot be set twice.
                  child: CelebrationBar(
                    added: true,
                    tucked: true,
                    onTap: onTap,
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: shown),
            child: card,
          ),
        ],
      );
    },
  );
}
