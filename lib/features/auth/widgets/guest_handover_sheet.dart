import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/transfer_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/core/api_image.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_text_button.dart';
import '../../../shared/module/dialog/global_dialog.dart';
import '../../../shared/module/sheet/global_sheet.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_image.dart';
import '../../cart/data/guest_basket.dart';
import '../../profile/data/guest_addresses.dart';
import '../../shop/data/guest_wishlist.dart';

/// What the reader chose to bring with them.
class HandoverChoice {
  const HandoverChoice({
    required this.basket,
    required this.wishlist,
    this.addresses = false,
  });

  final bool basket;
  final bool wishlist;

  /// The device's address book. A visitor filling one in is about to
  /// buy something, so it is the group they most want to keep — and it
  /// was the one this sheet never offered.
  final bool addresses;

  bool get nothing => !basket && !wishlist && !addresses;
}

/// «ننقل اختياراتك معك؟» — the sheet shown the first time a visitor
/// signs in holding something.
///
/// **It shows the PIECES, not the word "migrate".** A customer picked
/// these one at a time and is deciding about those cups, not about a
/// data operation — so the sheet puts their pictures on screen, counts
/// them in their own language, and offers two switches rather than one
/// technical verb.
///
/// Returns null if the reader dismissed it without choosing, which the
/// caller must treat as "ask me again", not as "no".
Future<HandoverChoice?> showGuestHandoverSheet(
  BuildContext context, {
  required GuestBasket basket,
  required GuestWishlist wishlist,
  required GuestAddresses addresses,
}) => GlobalBottomSheet.show<HandoverChoice>(
  context: context,
  // Not dismissible by tapping away: the answer decides whether the
  // customer's picks survive, and a stray tap is not an answer. A
  // dismissal that gets through anyway returns null, which the caller
  // reads as "ask me again" rather than as "no".
  isDismissible: false,
  showCloseButton: false,
  content: _HandoverBody(
    basket: basket,
    wishlist: wishlist,
    addresses: addresses,
  ),
);

class _HandoverBody extends StatefulWidget {
  const _HandoverBody({
    required this.basket,
    required this.wishlist,
    required this.addresses,
  });

  final GuestBasket basket;
  final GuestWishlist wishlist;
  final GuestAddresses addresses;

  @override
  State<_HandoverBody> createState() => _HandoverBodyState();
}

class _HandoverBodyState extends State<_HandoverBody> {
  late bool _takeBasket = !widget.basket.isEmpty;
  late bool _takeWishlist = !widget.wishlist.isEmpty;
  late bool _takeAddresses = !widget.addresses.isEmpty;

  /// Leaving them behind DELETES them, so it asks once more and says
  /// what "leave" costs. The customer chose each of these deliberately;
  /// losing them to a mis-tap has no undo.
  Future<void> _skip() async {
    final sure = await GlobalDialog.confirm(
      context: context,
      title: TransferStrings.discardTitle,
      message: TransferStrings.discardBody,
      confirmText: TransferStrings.discardConfirm,
      isDestructive: true,
    );
    if (!sure || !mounted) return;
    Navigator.of(context).pop(
      const HandoverChoice(basket: false, wishlist: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final hasBasket = !widget.basket.isEmpty;
    final hasWishlist = !widget.wishlist.isEmpty;
    final hasAddresses = !widget.addresses.isEmpty;

    return Padding(
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            TransferStrings.title,
            style: context.textTheme.titleMedium?.copyWith(
              color: context.textColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            TransferStrings.body,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
          SizedBox(height: spacing.md),
          if (hasBasket)
            _Group(
              label: TransferStrings.basket(widget.basket.pieceCount),
              value: _takeBasket,
              onChanged: (v) => setState(() => _takeBasket = v),
              thumbnails: [
                for (final l in widget.basket.lines) l.image,
              ],
            ),
          if (hasBasket && hasWishlist) SizedBox(height: spacing.sm),
          if (hasWishlist)
            _Group(
              label: TransferStrings.saved(widget.wishlist.count),
              value: _takeWishlist,
              onChanged: (v) => setState(() => _takeWishlist = v),
              thumbnails: [
                for (final p in widget.wishlist.items) p.image,
              ],
            ),
          if ((hasBasket || hasWishlist) && hasAddresses)
            SizedBox(height: spacing.sm),
          // NO THUMBNAILS. The other two groups show the pieces because
          // a customer recognises their own cups; an address has no
          // picture, and a row of grey squares standing in for one
          // would say less than the count already does.
          if (hasAddresses)
            _Group(
              label: TransferStrings.addresses(widget.addresses.items.length),
              value: _takeAddresses,
              onChanged: (v) => setState(() => _takeAddresses = v),
              thumbnails: const [],
            ),
          SizedBox(height: spacing.lg),
          GlobalFilledButton(
            text: TransferStrings.confirm,
            // Nothing ticked is not a confirm — it is the skip, and the
            // skip has to say what it costs. Disabled rather than
            // silently doing nothing.
            onPressed: (_takeBasket || _takeWishlist || _takeAddresses)
                ? () => Navigator.of(context).pop(
                    HandoverChoice(
                      basket: _takeBasket,
                      wishlist: _takeWishlist,
                      addresses: _takeAddresses,
                    ),
                  )
                : null,
            style: terracottaCtaStyle(showArrow: false),
          ),
          SizedBox(height: spacing.xs),
          Center(
            child: GlobalTextButton(
              text: TransferStrings.skip,
              shrinkWidth: true,
              onPressed: _skip,
            ),
          ),
        ],
      ),
    );
  }
}

/// One switchable group — the count in words, and the pieces themselves.
class _Group extends StatelessWidget {
  const _Group({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.thumbnails,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final List<ApiImage?> thumbnails;

  /// How many pictures fit before the row starts to crowd. The rest are
  /// counted rather than drawn.
  static const _shown = 4;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final extra = thumbnails.length - _shown;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.backgroundColors.container,
        borderRadius: BorderRadius.circular(context.radii.md),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.sm),
        child: Row(
          children: [
            // The PIECES first, because that is what the reader is
            // deciding about. A row of counts would be a form.
            for (final image in thumbnails.take(_shown)) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(context.radii.xs),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: TerracottaImage(image: image),
                ),
              ),
              SizedBox(width: spacing.xs),
            ],
            if (extra > 0) ...[
              Text(
                '+$extra',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.textColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: spacing.xs),
            ],
            Expanded(
              child: Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.textColors.primary,
                ),
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
