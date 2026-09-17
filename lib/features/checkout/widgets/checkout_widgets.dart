import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/checkout_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/content/discount_code.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/image/global_image.dart';
import '../../../shared/module/text_field/global_text_field.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_widgets.dart';

/// The quote breakdown.
///
/// **Every one of these is a decimal STRING, printed as it arrived.**
/// Nothing here is summed locally: the server applies discount to goods
/// only, adds delivery on top, then covers what is left from the
/// wallet, in that exact order. A total computed in the app will
/// disagree with the charge.
///
/// **VAT is INCLUSIVE.** `vatAmount` is the tax already contained in
/// `total`, not a line to add — showing it as an addition overcharges.
///
/// When `amountDue` is `"0.00"` the purchase has ALREADY settled from
/// wallet or a full discount, and the client must skip the pay call.
class QuoteBreakdown extends StatelessWidget {
  const QuoteBreakdown({
    this.subtotal,
    this.discount,
    this.deliveryFee,
    this.vatRate,
    this.total,
    this.walletApplied,
    this.amountDue,
    super.key,
  });

  final String? subtotal;
  final String? discount;
  final String? deliveryFee;
  final String? vatRate;
  final String? total;
  final String? walletApplied;
  final String? amountDue;

  /// `"0.00"` means nothing is left to pay.
  bool get isSettled => amountDue == '0.00';

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return TerracottaCard(
      child: Column(
        children: [
          _Line(label: CheckoutStrings.subtotal, value: subtotal),
          if (discount != null && discount != '0.00')
            _Line(
              label: CheckoutStrings.discount,
              value: discount,
              tint: context.statusColors.success,
            ),
          if (deliveryFee != null)
            _Line(
              label: CheckoutStrings.deliveryFee,
              // A ZERO fee is «مجاني», not «٠». The order cleared the
              // studio's threshold, and that is the fact worth
              // printing.
              value: deliveryFee == '0.00' ? CheckoutStrings.free : deliveryFee,
              money: deliveryFee != '0.00',
              tint: deliveryFee == '0.00' ? context.statusColors.success : null,
            ),
          if (walletApplied != null && walletApplied != '0.00')
            _Line(
              label: CheckoutStrings.walletApplied,
              value: walletApplied,
              tint: context.primaryColors.primary,
            ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.sm),
            child: Divider(
              height: 1,
              color: context.primaryColors.border,
            ),
          ),
          _Line(label: CheckoutStrings.total, value: total, strong: true),
          // WHAT IS LEFT TO PAY, when it is not the total.
          //
          // The wallet and a discount both move it, and a customer
          // looking at «١١٠ ريال» under «الإجمالي» with sixty of it
          // already covered needs the number the button will actually
          // charge — which is this one, and never a subtraction done
          // here.
          if (amountDue != null && amountDue != total)
            _Line(
              label: CheckoutStrings.amountDue,
              value: amountDue,
              strong: true,
              tint: context.primaryColors.primary,
            ),
          if (vatRate != null && vatRate != '0.00')
            Padding(
              padding: EdgeInsets.only(top: spacing.xs),
              child: Text(
                CheckoutStrings.vat(vatRate!),
                textAlign: TextAlign.end,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.textColors.disabled,
                ),
              ),
            ),
          if (isSettled)
            Padding(
              padding: EdgeInsets.only(top: spacing.sm),
              child: Text(
                CheckoutStrings.alreadySettled,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.statusColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    this.value,
    this.tint,
    this.strong = false,
    this.money = true,
  });

  final String label;
  final String? value;
  final Color? tint;
  final bool strong;

  /// Whether [value] is an AMOUNT, and so gets the app's money
  /// treatment — «٢٠٠ ريال», not `200.00`.
  ///
  /// False for the one line that says a word instead of a figure: a
  /// delivery fee of zero reads «مجاني».
  final bool money;

  /// The figure as this app writes money — the decimal string trimmed
  /// and its digits localized, with the currency after it. Never
  /// parsed to a number; see [PriceText.format].
  String get _shown {
    final raw = value;
    if (raw == null || raw.isEmpty) return '';
    if (!money) return raw;
    return '${PriceText.format(raw)} ${HomeStrings.currency}';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: context.spacing.xs),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: strong
                ? context.textTheme.titleMedium?.copyWith(
                    color: context.textColors.primary,
                  )
                : context.textTheme.bodyMedium?.copyWith(
                    color: context.textColors.primary,
                  ),
          ),
        ),
        Text(
          _shown,
          style: context.textTheme.bodyMedium?.copyWith(
            color: tint ?? context.textColors.primary,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

/// The discount-code field and its apply button.
///
/// The code is applied by RE-QUOTING, not by validating: a quote
/// re-asked with `discount_code` is the same figure the create step
/// will charge, and `POST /api/discount-codes/validate` prices the
/// goods alone. A code's use is consumed at HOLD time either way, so
/// nothing here spends one.
///
/// A rejected code comes back as a 422 keyed to `discount_code`, which
/// lands under the box it was typed in rather than as a toast.
class DiscountCodeField extends StatefulWidget {
  const DiscountCodeField({
    required this.applied,
    required this.error,
    required this.onApply,
    this.tint,
    super.key,
  });

  /// The code the quote on screen was priced with, or null.
  final String? applied;

  /// The SERVER's words about the last one tried.
  final String? error;

  final ValueChanged<String?> onApply;

  /// The FLOW's colour — the workshop's on a booking checkout. Null
  /// keeps the app's own primary, which is right on the shop and the
  /// gift, neither of which belongs to a workshop.
  final Color? tint;

  @override
  State<DiscountCodeField> createState() => _DiscountCodeFieldState();
}

class _DiscountCodeFieldState extends State<DiscountCodeField> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.applied ?? '';
  }

  @override
  void didUpdateWidget(DiscountCodeField old) {
    super.didUpdateWidget(old);
    // PICKED FROM THE LIST, not typed. Tapping a chip applies a code
    // the box knows nothing about, and a field still showing the last
    // thing typed while a different code is priced is the screen
    // disagreeing with itself.
    // ONLY WHEN THERE IS ONE. A rejected code clears `applied` — the
    // cubit drops it so the next quote is not priced with a code the
    // server refused — and emptying the box on that would take away
    // the typo the reader is being asked to correct.
    final picked = widget.applied;
    if (picked != null && picked != old.applied && picked != _controller.text) {
      _controller.text = picked;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final applied = (widget.applied ?? '').isNotEmpty;

    return Row(
      // The field draws its own header, so the button lines up with the
      // BOX rather than with the pair.
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          // The app's own field, not a bare `TextField` in a card: the
          // module owns the box, the header, and the error under it.
          child: GlobalTextFormField(
            controller: _controller,
            // The HEADER above the box. The hint inside it is an
            // example — never the field's own name, which would put the
            // same words on screen twice.
            identifier: CheckoutStrings.discountCode,
            hint: CheckoutStrings.discountCodeHint,
            behavior: const TextFieldBehavior(
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
            ),
            // The box and the button are given the SAME height, in the
            // CTA's own number. Left to their defaults the field takes
            // `InputDecorator`'s ~56 and the button its own ~48, and
            // the pair sat a hand's width out of line.
            sizing: const TextFieldSizing(height: kTerracottaCtaHeight),
            validation: TextFieldValidation(
              errorText: widget.error,
              showErrorImmediately: true,
            ),
            callbacks: TextFieldCallbacks(onSubmitted: widget.onApply),
          ),
        ),
        SizedBox(width: spacing.sm),
        // APPLY, or TAKE OFF once one is on.
        //
        // The list's rows toggle themselves, but a code the reader
        // TYPED has no row to tap — and there was no other way back to
        // the undiscounted total. The one button both applies and
        // removes, because there is only ever one thing to do to a
        // code at a time.
        GlobalFilledButton(
          text: applied ? CommonStrings.remove : CheckoutStrings.apply,
          shrinkWidth: true,
          onPressed: () {
            if (applied) {
              _controller.clear();
              widget.onApply(null);
              return;
            }
            widget.onApply(_controller.text);
          },
          style: ButtonStateStyle(
            height: kTerracottaCtaHeight,
            borderRadius: BorderRadius.circular(kTerracottaCtaRadius),
            // TAKING ONE OFF IS THE DESTRUCTIVE HALF, so it keeps the
            // error ramp whatever the flow is coloured — a workshop's
            // own hue on «حذف» would say the opposite of what the tap
            // does.
            backgroundColor: applied ? context.statusColors.error : widget.tint,
          ),
        ),
      ],
    );
  }
}

/// The promos the studio is advertising, each saying what it is worth.
///
/// **The list is already filtered to this customer.** The server drops
/// a code whose overall or per-user limit is spent, so a row here is
/// one they can use today.
///
/// **An empty list hides the FIELD too**, which is a deliberate choice
/// with a cost. `GET /api/discount-codes` returns the PUBLIC codes; a
/// private one still validates when typed. So on a day the studio is
/// advertising nothing, a customer holding a private code has nowhere
/// to enter it. That is the trade for not showing an empty box under a
/// heading — reverse it by drawing the field unconditionally at the
/// three checkout call sites.
///
/// A row is CODE, then what it takes off, then the floor it needs. The
/// code alone was not enough to choose between «SAVE25» and
/// «WELCOME10»: one is twenty-five riyals over a hundred and the other
/// is ten percent of anything, and the difference is the whole
/// decision.
class DiscountCodeList extends StatelessWidget {
  const DiscountCodeList({
    required this.codes,
    required this.applied,
    required this.onPick,
    this.tint,
    super.key,
  });

  final List<DiscountCode> codes;
  final String? applied;
  final ValueChanged<String?> onPick;

  /// The FLOW's colour, carried down to every ticket — see
  /// `DiscountCodeField.tint`.
  final Color? tint;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final code in codes)
        Padding(
          padding: EdgeInsets.only(bottom: context.spacing.xs),
          child: _CodeRow(
            code: code,
            tint: tint,
            active: code.code == applied,
            // Tapping the one already applied takes it OFF, which is
            // the only way back to the undiscounted total without
            // clearing the box by hand.
            onTap: () => onPick(code.code == applied ? null : code.code),
          ),
        ),
    ],
  );
}

class _CodeRow extends StatelessWidget {
  const _CodeRow({
    required this.code,
    required this.active,
    required this.onTap,
    this.tint,
  });

  final DiscountCode code;
  final bool active;
  final VoidCallback onTap;

  /// The flow's colour — see `DiscountCodeField.tint`.
  final Color? tint;

  /// «خصم ١٠٪» or «خصم ٤٠ ريال».
  ///
  /// A percent is a plain number and a fixed amount is MONEY — priced
  /// through [PriceText.format], which trims the trailing zeros and
  /// localizes the digits without ever parsing the string.
  String _worth() => code.isPercent
      ? CheckoutStrings.codeOffPercent(PriceText.format(code.value))
      : CheckoutStrings.codeOffFixed(
          '${PriceText.format(code.value)} ${HomeStrings.currency}',
        );

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    // THE FLOW'S COLOUR. The ticket's dashes and its filled state are
    // the same brand line the rest of the screen is drawn in — on a
    // workshop checkout that is the workshop's, not the app's.
    final primary = tint ?? context.primaryColors.primary;
    final ink = active
        ? context.textColors.onPrimary
        : context.textColors.primary;
    final floor = code.minOrderTotal;

    return Semantics(
      button: true,
      selected: active,
      child: TerracottaCard(
        // A TICKET EDGE. The dashes are what say «voucher» before a
        // word of the row is read — and they are the app's one place
        // where an outline does more than separate a panel from the
        // page.
        dashed: true,
        // The BRAND's line when it is not taken, and the card's own
        // ground behind it; taken, the fill carries the meaning and
        // the dashes go white so the edge does not disappear into it.
        borderColor: active ? context.textColors.onPrimary : primary,
        color: active ? primary : context.backgroundColors.cardBackground,
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.sm,
        ),
        // `GlobalContainer` puts an `InkWell` under this, so the row
        // ripples where it is pressed. Tapping the one already applied
        // takes it OFF — the only way back to the undiscounted total
        // without clearing the box by hand.
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              active ? Icons.local_offer_rounded : Icons.local_offer_outlined,
              size: context.iconSizes.sm,
              color: ink,
            ),
            SizedBox(width: spacing.sm),
            // WRAPS rather than clips: three facts about a promo do not
            // fit one line on a narrow phone in either language, and a
            // truncated «للطلبات فوق ٥٠…» is the half that matters.
            Expanded(
              child: Wrap(
                spacing: spacing.sm,
                runSpacing: spacing.xs / 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    code.code,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    _worth(),
                    style: context.textTheme.bodySmall?.copyWith(color: ink),
                  ),
                  if (floor != null && floor != '0.00')
                    Text(
                      // A middle dot between the two facts, the way the
                      // rest of the app separates them.
                      '· ${CheckoutStrings.codeMinOrder('${PriceText.format(floor)} ${HomeStrings.currency}')}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: active
                            ? ink.withValues(alpha: 0.8)
                            : context.textColors.secondary,
                      ),
                    ),
                ],
              ),
            ),
            // The way OFF, once it is on. A tick alone said "applied"
            // and nothing about how to undo it.
            if (active)
              Icon(Icons.close_rounded, size: context.iconSizes.sm, color: ink),
          ],
        ),
      ),
    );
  }
}

/// The payment-method row — Apple Pay, Google Pay, Visa.
///
/// **The tiles are cosmetic, and the payment is NOT.**
///
/// `POST .../pay` takes **no body** — verified against the live
/// OpenAPI on 2026-09-08 for all three of `bookings/{id}/pay`,
/// `shop/orders/{id}/pay` and `gifts/{id}/pay` — so there is no method
/// to send and nothing this row could carry. The call settles the
/// purchase server-side and the app runs it for real; the web channel
/// does exactly the same.
///
/// What is missing is a GATEWAY: no card is charged, so a booking
/// settles without money moving. That is the commercial blocker, and
/// it is behind the endpoint rather than in front of it. These tiles
/// exist so the screen matches the design, and the choice is remembered
/// only to put the right mark in the CTA's arrow slot.
class PaymentMethodRow extends StatelessWidget {
  const PaymentMethodRow({
    this.selected = 0,
    this.onSelect,
    this.tint,
    super.key,
  });

  final int selected;
  final ValueChanged<int>? onSelect;

  /// The WORKSHOP's colour, when this row is inside a booking flow.
  ///
  /// The chosen card was the palette's `secondary` wherever it stood —
  /// a green card at the foot of a red workshop's checkout, which is
  /// the one screen where the flow's colour has been carried all the
  /// way from the catalogue. Null keeps `secondary`, which is right on
  /// the shop and the gift, neither of which belongs to a workshop.
  final Color? tint;

  /// The wallets' own marks, as the design draws them — not Material
  /// lookalikes. A payment method a customer cannot RECOGNISE is one
  /// they hesitate over, and `Icons.apple_rounded` is an apple, not
  /// Apple Pay.
  static const brands = <String>[
    'assets/icons/cib_cc_apple_pay.svg',
    'assets/icons/logos_google_pay.svg',
    'assets/icons/selfhst_visa.svg',
  ];

  /// ▸ TUNE THE MARKS HERE ◂
  ///
  /// How tall each wallet's artwork is drawn, in the same order as
  /// [brands] — Apple Pay, Google Pay, Visa. The CARDS are always
  /// identical ([cardHeight] below, and `Expanded` across the row);
  /// only the picture inside each one is tuned.
  ///
  /// It has to be per-brand: these are three different artworks with
  /// three different amounts of air baked into them, so `contain` in
  /// one identical box made Google Pay tower over a Visa that looked
  /// like a footnote. Raise a number to make that one mark bigger.
  static const brandHeights = <double>[35, 20, 40];

  /// ▸ AND THE CARDS HERE ◂
  ///
  /// One height for all three, so a taller mark cannot make its own
  /// card taller than its neighbours.
  static const cardHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Row(
      children: [
        for (var i = 0; i < brands.length; i++) ...[
          if (i > 0) SizedBox(width: spacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect?.call(i),
              child: TerracottaCard(
                color: i == selected
                    ? (tint ?? context.primaryColors.secondary)
                    : context.backgroundColors.cardBackground,
                // The CARD's size is fixed and identical across the
                // three; only the mark inside it is tuned, so a taller
                // artwork cannot make its own card taller.
                padding: EdgeInsets.zero,
                child: SizedBox(
                  height: cardHeight,
                  child: Center(
                    child: SizedBox(
                      height: brandHeights[i],
                      child: GlobalImage.a(
                        brands[i],
                        placeholder: const SizedBox.shrink(),
                        style: ImageStyle(
                          fit: BoxFit.contain,
                          borderRadius: BorderRadius.zero,
                          // The chosen card is dark, and these marks
                          // are drawn for a light one. White on every
                          // brand band in this app — see
                          // `WorkshopFamilyColors.resolve`.
                          color: i == selected
                              ? context.textColors.onPrimary
                              : null,
                          overlayBlendMode: i == selected
                              ? BlendMode.srcIn
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// «رصيد تيراكوتا» — the wallet row on a checkout.
class WalletRow extends StatelessWidget {
  const WalletRow({this.balance = '', super.key});

  final String balance;

  @override
  Widget build(BuildContext context) => TerracottaCard(
    child: Row(
      children: [
        Expanded(
          child: Text(
            CheckoutStrings.walletApplied,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.textColors.primary,
            ),
          ),
        ),
        Text(
          balance,
          style: context.textTheme.titleMedium?.copyWith(
            color: context.primaryColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
