import 'package:flutter/widgets.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/localization/strings/transfer_strings.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../cart/cubits/cart_cubit.dart';
import '../../cart/data/guest_basket.dart';
import '../../profile/data/guest_addresses.dart';
import '../../shop/data/guest_wishlist.dart';
import '../widgets/guest_handover_sheet.dart';
import 'guest_handover.dart';

/// Offer to bring a visitor's picks into the account they just signed
/// into — and act on the answer.
///
/// Called from every screen that lands a session (sign-in, and
/// registration, which also returns a token). Silent when there is
/// nothing on the device, which is the common case.
///
/// **Declining DELETES.** The sheet says so before it happens; this
/// clears only after the customer has confirmed it in a dialog of its
/// own. Dismissing the sheet without answering leaves everything alone,
/// so the offer comes back next time.
///
/// **Answering it ALSO clears.** Whatever the server refused stays on
/// the device inside `GuestHandover`, which is right for that request
/// and wrong for the next sign-in: the sheet used to come back with
/// the same refused items every single time, forever. Once the
/// customer has answered, the visitor's basket is done with.
class GuestHandoverFlow {
  const GuestHandoverFlow._();

  static Future<void> offer(BuildContext context) async {
    final basket = getIt<GuestBasket>()..load();
    final wishlist = getIt<GuestWishlist>()..load();
    final addresses = getIt<GuestAddresses>()..load();
    if (basket.isEmpty && wishlist.isEmpty && addresses.isEmpty) return;

    final choice = await showGuestHandoverSheet(
      context,
      basket: basket,
      wishlist: wishlist,
      addresses: addresses,
    );
    // Null is a dismissal, not a decision. Nothing is moved and nothing
    // is thrown away.
    if (choice == null) return;

    if (choice.nothing) {
      // They said leave them, and the sheet already made sure they
      // meant it.
      basket.clear();
      wishlist.clear();
      addresses.clear();
      return;
    }

    var moved = 0;
    var refused = 0;

    if (choice.basket) {
      final result = await GuestHandover.basket(basket);
      moved += result.moved;
      refused += result.refused;
      // The cart cubit is a singleton and its badge is on every app
      // bar. It was serving the LOCAL basket a moment ago; now the
      // account owns one, so it has to go and read it.
      await getIt<CartCubit>().load();
    }
    if (choice.wishlist) {
      final result = await GuestHandover.wishlist(wishlist);
      moved += result.moved;
      refused += result.refused;
    }
    if (choice.addresses) {
      final result = await GuestHandover.addresses(addresses);
      moved += result.moved;
      refused += result.refused;
    }

    if (moved > 0) GlobalToast.success(TransferStrings.done(moved));
    // Said out loud rather than swallowed. A basket that quietly
    // arrives shorter than it left is the kind of thing a customer
    // finds at checkout.
    if (refused > 0) GlobalToast.info(TransferStrings.partial(refused));

    // THE QUESTION HAS BEEN ANSWERED — ask it once.
    //
    // `GuestHandover` removes each item as it lands and leaves behind
    // whatever the server refused: a piece the studio has run out of,
    // a duplicate address. That is right for the one request, and
    // wrong for the next sign-in — the leftovers are still on the
    // device, so the sheet came back with them every single time,
    // offering to move things that had already been refused once and
    // would be refused again. A customer with one sold-out piece in an
    // old visitor basket met this sheet on every sign-in, for good.
    //
    // The refusal has been reported. What is left is a visitor's
    // basket from before they had an account, and it does not belong
    // to the account they are now in.
    basket.clear();
    wishlist.clear();
    addresses.clear();
  }
}
