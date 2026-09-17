import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/country_codes.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/checkout_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/gift_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/common/text_form_fields/text_form_fields.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_text_button.dart';
import '../../../shared/module/segmented_control/global_segmented_control.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../booking/widgets/sheet_shell.dart';
import '../cubits/my_gifts_cubit.dart';
import '../data/gift_availability.dart';
import '../data/gift_draft.dart';
import 'gift_hero_card.dart';
import 'my_gifts_list.dart';

/// «اهداء رصيد» — buy a balance for someone.
///
/// `GET /api/gifts/package` returns the admin-set amount and whether
/// gifting is switched on at all, so the amount is not the customer's
/// to choose — the card at the top STATES it rather than asking.
///
/// A sheet rather than a page: it opens off the tile at the head of the
/// workshops list, and everything it needs is two boxes.
///
/// Redeeming happens through a SHARE LINK opened in the app
/// (`GET /api/gifts/{token}` then `POST /api/gifts/{token}/redeem`),
/// which is the one place this app genuinely needs deep links — they
/// were descoped at intake, so the share link currently has nowhere to
/// land in-app.
class GiftCreditSheet extends StatefulWidget {
  const GiftCreditSheet({this.amount, super.key});

  /// Decimal string. NULL asks `GiftPackageService`, which is what
  /// every live caller does — the amount is the studio's and the
  /// service holds the one answer for the whole app. Passing one is
  /// for a screen that already has it, and for tests.
  final String? amount;

  @override
  State<GiftCreditSheet> createState() => _GiftCreditSheetState();
}

/// Which half of the sheet is showing.
enum GiftTab {
  /// The form — buy one for somebody.
  send,

  /// What has already been bought.
  mine,
}

class _GiftCreditSheetState extends State<GiftCreditSheet> {
  /// THE TWO HALVES SIT SIDE BY SIDE, not one under the other.
  ///
  /// A history below the form means scrolling past a form to reach it,
  /// and every gift sent pushes it further down. They share a subject
  /// and a colour, the reader arrives wanting one or the other, and
  /// neither needs the other's scroll position — which is exactly what
  /// a segmented control is for.
  GiftTab _tab = GiftTab.send;

  late final _mine = MyGiftsCubit();

  final _name = TextEditingController();
  final _message = TextEditingController();
  final _phone = TextEditingController();

  /// The number in E.164, which is what the field reports and what the
  /// wire wants — the controller holds the national digits only, so
  /// sending its text would drop the country.
  String? _phoneE164;

  @override
  void initState() {
    super.initState();
    // The CTA is dead until there is a name, so it has to hear every
    // keystroke.
    _name.addListener(_onTyped);

    // ON THE WAY IN, not on the tab.
    //
    // The count on «هداياي» has to be true before anybody opens it —
    // that is the whole reason the server sends `totals` over a list
    // it does not narrow. Waiting for the tap would label the tab
    // «هداياي» and then make it jump to «هداياي ٢» under the reader's
    // finger.
    unawaited(_mine.ensureLoaded());

    // AND THE STUDIO'S FIGURE, if the boot call missed it. It 422s on
    // an empty `X-FCM-Token`, which is the normal case on a cold
    // radio — see `GiftPackageService`. Opening the sheet is the next
    // moment the app can put a number on the card.
    unawaited(_refreshPackage());
  }

  void _onTyped() => setState(() {});

  Future<void> _refreshPackage() async {
    final changed = await ensureGiftPackage();
    if (changed && mounted) setState(() {});
  }

  @override
  void dispose() {
    _name
      ..removeListener(_onTyped)
      ..dispose();
    _message.dispose();
    _phone.dispose();
    unawaited(_mine.close());
    super.dispose();
  }

  void _select(GiftTab tab) => setState(() => _tab = tab);

  GiftDraft get _draft => GiftDraft(
    recipientName: _name.text,
    message: _message.text,
    recipientPhone: _phoneE164,
  );

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return SheetShell(
      // No title: the coral card IS the heading, and a line of text
      // above it would say the same thing twice.
      //
      // Sized to its contents under a ceiling — two boxes and a button
      // do not need two thirds of the screen, and a long message still
      // has somewhere to go.
      heightFactor: null,
      maxHeightFactor: 0.9,
      children: [
        GiftHeroCard(amount: widget.amount ?? giftAmount()),
        SizedBox(height: spacing.md),
        // THE TWO HALVES. The card above stays whichever is showing —
        // it is the studio's offer, and it heads both «إهداء رصيد» and
        // the list of ones already sent.
        //
        // WATCHED, so the count on «هداياي» arrives with the history
        // rather than on the tap that opens it.
        BlocBuilder<MyGiftsCubit, MyGiftsState>(
          bloc: _mine,
          builder: (context, state) => GlobalSegmentedControl<GiftTab>(
            value: _tab,
            onChanged: _select,
            style: SegmentedStyle(
              expandEqual: true,
              backgroundColor: context.buttonsColors.disabled,
              // CORAL, like everything else on this sheet.
              selectedColor: context.primaryColors.accent,
              selectedForegroundColor: context.textColors.onPrimary,
              unselectedForegroundColor: context.textColors.disabled,
              borderRadius: BorderRadius.circular(context.radii.md),
              indicatorPadding: 4,
            ),
            segments: [
              SegmentItem(value: GiftTab.send, label: GiftStrings.tabSend),
              SegmentItem(
                value: GiftTab.mine,
                label: GiftStrings.tabMine,
                // HOW MANY THEY HAVE SENT, on the tab. `sent_count` is
                // the whole history and does not move with the list,
                // so it is honest before the tab is opened — and a
                // zero is worth nothing to anybody, so it draws
                // nothing.
                trailing: state.totals.sentCount == 0
                    ? null
                    : _Count(
                        value: state.totals.sentCount,
                        selected: _tab == GiftTab.mine,
                      ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.lg),
        if (_tab == GiftTab.mine)
          MyGiftsList(cubit: _mine)
        else ...[
          // `identifier` is the header ABOVE the box and `hint` is the
          // example inside it. Passing `label` as well put the field's
          // own name in both places, so every box read «اسم المستلم»
          // twice and showed the customer no example at all.
          NameField(
            controller: _name,
            identifier: GiftStrings.recipientName,
            // A GIVEN name, which is the field's default mode and the
            // one that asks for a single part. `recipient_name` is a
            // note shown on the redeem screen, not an identity to
            // match — «سارة» is a complete answer, and the full-name
            // mode would hold out for a family name it is never sent.
            showPartsProgress: false,
            required: true,
            hint: GiftStrings.recipientHint,
          ),
          SizedBox(height: spacing.md),
          // OPTIONAL, and it does not gate anything. The spec calls
          // `recipient_phone` "a contact note for the purchaser's own
          // reference" — nothing is sent to it, because the gift is
          // claimed by whoever opens the share link.
          PhoneNumberField(
            controller: _phone,
            identifier: GiftStrings.recipientPhone,
            hint: GiftStrings.recipientPhoneHint,
            // The studio's customers are in Saudi Arabia, and the
            // number is one THEY will dial.
            initialCountry: CountryCodes.getCountryCodeByCode('SA'),
            preferredCountries: const ['SA'],
            onNumberChanged: (n) => _phoneE164 = n.e164,
          ),
          SizedBox(height: spacing.md),
          MultilineTextField(
            controller: _message,
            identifier: GiftStrings.message,
            hint: GiftStrings.messageHint,
            showCharCount: false,
          ),
          SizedBox(height: spacing.lg),
          GlobalFilledButton(
            text: CheckoutStrings.title,
            // The name is the only thing the server requires, so it is
            // the only thing that gates the way on.
            enabled: _draft.isComplete,
            onPressed: () {
              // POP FIRST: pushing from under the sheet leaves it on
              // the stack, so coming back from the checkout lands on it
              // again with the fields it was left with.
              //
              // The router is read before that, off a context that is
              // still mounted, rather than after — which is a lookup
              // through an element the pop has just deactivated.
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.pushNamed('gift-checkout', extra: _draft);
            },
            style: terracottaCtaStyle().copyWith(
              backgroundColor: context.primaryColors.accent,
            ),
          ),
        ],
        SizedBox(height: spacing.sm),
        // ONE DISMISS, under both halves — it is about the SHEET, not
        // about whichever side is showing.
        GlobalTextButton(
          text: CommonStrings.close,
          // THE SHEET'S OWN COLOUR, not the app's link blue. A
          // secondary control belongs to the surface it is on: this
          // sheet is coral from its heading to its CTA, and a dismiss
          // in a different hue reads as a control borrowed from another
          // screen.
          style: ButtonStateStyle(
            foregroundColor: context.primaryColors.accent,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// «٢» on the «هداياي» tab.
///
/// A pill rather than a bracketed number: the tab's own label is a
/// word, and «هداياي (٢)» reads as punctuation where the workshops bar
/// next door draws a count.
class _Count extends StatelessWidget {
  const _Count({required this.value, required this.selected});

  final int value;

  /// Whether the tab it sits on is the chosen one — the pill has to
  /// read on the coral as well as off it.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ink = selected
        ? context.primaryColors.accent
        : context.textColors.onPrimary;
    final ground = selected
        ? context.textColors.onPrimary
        : context.textColors.disabled;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ground,
        borderRadius: BorderRadius.circular(context.radii.full),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: context.spacing.xs,
          vertical: 1,
        ),
        child: Text(
          // Arabic-Indic where the language asks for them.
          AppNumbers.localizeDigits('$value'),
          style: context.textTheme.labelSmall?.copyWith(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Opens [GiftCreditSheet].
Future<void> showGiftCreditSheet(BuildContext context, {String? amount}) =>
    showTerracottaSheet<void>(
      context,
      builder: (_) => GiftCreditSheet(amount: amount),
    );
