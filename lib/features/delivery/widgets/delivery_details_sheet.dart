import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/address_strings.dart';
import '../../../core/localization/strings/delivery_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/address_apis.dart';
import '../../../data/models/terracotta/account/address.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_outlined_button.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../booking/widgets/sheet_shell.dart';
import '../../profile/views/address_form_page.dart';

/// «الى اين نرسلها؟» — where the finished piece goes.
///
/// Opens BEFORE the fee is quoted, because the fee comes from the
/// address: `delivery_zone_id` is what prices it, so the courier
/// cannot be booked until the customer says which city.
///
/// Leads with the address they already have — most customers have one
/// and the answer is "the usual" — and offers the other two paths
/// under it rather than making everyone start from a form.
class DeliveryDetailsSheet extends StatefulWidget {
  const DeliveryDetailsSheet({this.onConfirm, super.key});

  /// Called with the chosen address once they continue. The sheet
  /// closes first, so the caller owns what happens next.
  final ValueChanged<Address>? onConfirm;

  @override
  State<DeliveryDetailsSheet> createState() => _DeliveryDetailsSheetState();
}

class _DeliveryDetailsSheetState extends State<DeliveryDetailsSheet> {
  List<Address> _addresses = const [];
  Address? _chosen;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (await AddressApis.getAddresses() case Success(:final value)) {
      if (!mounted) return;
      setState(() {
        _addresses = value;
        // Their DEFAULT, or the only one they have. The customer who
        // has never thought about this should not have to choose.
        _chosen =
            value.where((a) => a.isDefault).firstOrNull ?? value.firstOrNull;
        _loading = false;
      });
      return;
    }
    if (mounted) setState(() => _loading = false);
  }

  /// The real form, and the new address becomes the chosen one.
  ///
  /// A customer who opens this has no address that will do — landing
  /// them back on an unchanged sheet afterwards would make them pick
  /// it out of a list they just added to.
  Future<void> _addAddress() async {
    final zones = await AddressApis.getDeliveryZones();
    if (!mounted) return;

    final saved = await Navigator.of(context).push<Address>(
      MaterialPageRoute(
        builder: (_) => AddressFormPage(
          zones: switch (zones) {
            Success(:final value) => value.zones,
            Failure() => const [],
          },
          // Reached from checkout with nothing saved yet — this IS the
          // first address, and the server will make it the default.
          isFirst: true,
        ),
      ),
    );
    if (saved == null || !mounted) return;
    setState(() {
      _addresses = [saved, ..._addresses];
      _chosen = saved;
    });
  }

  /// The next address in the list, so «ارسلها الى عنوان اخر» cycles
  /// rather than opening a picker for two entries.
  void _next() {
    if (_addresses.length < 2) return;
    final at = _addresses.indexOf(_chosen!);
    setState(() => _chosen = _addresses[(at + 1) % _addresses.length]);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final chosen = _chosen;

    return SheetShell(
      heightFactor: null,
      title: DeliveryStrings.whereTitle,
      centerTitle: true,
      footer: GlobalFilledButton(
        text: DeliveryStrings.continueToPayment,
        // Nothing to send it to yet — the customer adds one first.
        enabled: chosen != null,
        style: terracottaCtaStyle(showArrow: false),
        onPressed: chosen == null
            ? null
            : () {
                Navigator.of(context).pop();
                widget.onConfirm?.call(chosen);
              },
      ),
      children: [
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator.adaptive(),
            ),
          )
        else if (chosen == null)
          Text(
            DeliveryStrings.noAddress,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.textColors.secondary,
            ),
          )
        else
          _AddressSummary(address: chosen),
        SizedBox(height: spacing.md),
        if (_addresses.length > 1) ...[
          GlobalOutlinedButton(
            text: DeliveryStrings.changeAddress,
            icon: Icons.swap_horiz_rounded,
            onPressed: _next,
          ),
          SizedBox(height: spacing.sm),
        ],
        GlobalOutlinedButton(
          text: DeliveryStrings.addAddress,
          icon: Icons.add_rounded,
          onPressed: () => unawaited(_addAddress()),
        ),
      ],
    );
  }
}

/// The address, as the sheet needs to show it back.
class _AddressSummary extends StatelessWidget {
  const _AddressSummary({required this.address});

  final Address address;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final label = address.label;
    final accent = context.primaryColors.primary;

    // CHOSEN, AND IT LOOKS IT — even when there was nothing to choose
    // between. This card is only ever built for the address the sheet
    // WILL send to, and it used to look exactly like a card that was
    // merely being shown: a customer with one saved address had no
    // sign it had been taken, and pressed «متابعة» hoping.
    return TerracottaCard(
      borderColor: accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: context.iconSizes.md,
            color: accent,
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label == null || label.isEmpty
                      ? AddressStrings.unnamed
                      : label,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.textColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${address.street} · ${address.district}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textColors.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                // The ZONE, because the zone is what prices the
                // courier — the customer is agreeing to a fee here,
                // not just to a street.
                Text(
                  '${address.deliveryZone} · ${address.deliveryFee}',
                  style: context.textTheme.labelSmall?.copyWith(
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

/// Opens [DeliveryDetailsSheet] over the booking.
Future<void> showDeliveryDetailsSheet(
  BuildContext context, {
  ValueChanged<Address>? onConfirm,
}) => showTerracottaSheet<void>(
  context,
  builder: (_) => DeliveryDetailsSheet(onConfirm: onConfirm),
);
