import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/notifications/topic_subscription.dart';
import '../../features/cart/cubits/cart_cubit.dart';
import '../../features/home/cubits/home_cubit.dart';
import '../../features/home/cubits/live_now_cubit.dart';
import '../../features/profile/cubits/notifications_cubit.dart';
import '../../features/profile/cubits/profile_counts_cubit.dart';
import '../../features/profile/cubits/wallet_cubit.dart';
import '../../features/workshops/cubits/my_bookings_cubit.dart';
import '../di/service_locator.dart';

/// Everything on screen that belongs to a PERSON, dropped when the
/// person changes.
///
/// ## Why one place and not each call site
///
/// The account-scoped cubits are `getIt` singletons — they outlive
/// every page, because `context.go` tears a tab's `State` down and a
/// page-owned cubit would re-ask the server on every switch. The cost
/// of that is this: nothing re-asks on its own, so after a sign-in the
/// screens kept showing the last reader's answers. «ورشاتي» stayed
/// empty for someone who had bookings; the basket badge counted a
/// customer who had left.
///
/// Sign-out already dropped the CART, at the one call site that
/// remembered to. That is the shape of the bug rather than the fix:
/// four other cubits hold the same kind of data and none of them were
/// told. This is called from an `AuthBloc` listener at the app's root,
/// so every path arrives here — sign-in, sign-out, a session that
/// expired, and one account replacing another.
///
/// ## Invalidate, do not fetch
///
/// Nothing here asks the server. `invalidate` only clears the "already
/// loaded" mark, so the next screen that mounts asks — which is the
/// screen that needs it, at the moment it is looked at. Fetching every
/// endpoint on sign-in would spend the reader's connection on tabs
/// they may not open.
///
/// Only the `getIt` SINGLETONS are here. The addresses and favourites
/// cubits are owned by their pages and die with them, so they reload
/// on their own the next time those pages are opened.
abstract final class AccountScope {
  const AccountScope._();

  /// The reader changed. Drop what was the last one's.
  static void changed() {
    // The cart keeps a device basket for a signed-out reader, so it
    // has its own method rather than a bare invalidate.
    _ifRegistered<CartCubit>((c) => c.signedOut());
    _ifRegistered<LiveNowCubit>((c) => c.clear());
    // THE HOME PAYLOAD IS PER-PERSON TOO. `current_booking` is on it,
    // and a booking the STUDIO made at the desk lands on an account
    // the moment that phone number registers — so a brand-new sign-up
    // can already have one. Without this, home kept the last reader's
    // payload until the language changed, and a customer who had just
    // claimed a desk booking saw no sign of it.
    _ifRegistered<HomeCubit>((c) => c.invalidate());
    _ifRegistered<MyBookingsCubit>((c) => c.invalidate());
    _ifRegistered<WalletCubit>((c) => c.clear());
    // The numbers beside the account rows are the last reader's too.
    _ifRegistered<ProfileCountsCubit>((c) => c.clear());
    // CLEARED, not just invalidated — the rows and the unread count
    // are the last reader's, and the bell in every bar reads this
    // singleton. See [NotificationsCubit.clear].
    _ifRegistered<NotificationsCubit>((c) => c.clear());
    // AND THE BROADCAST GROUP. The studio publishes to `users` and to
    // `guests` separately, so signing in or out moves this device from
    // one to the other — without it a signed-out reader went on being
    // sent the announcements meant for account holders, and a new one
    // never got theirs. See [TopicSubscription].
    unawaited(TopicSubscription.apply());
  }

  /// Something the reader OWNS just changed — a booking made or
  /// cancelled, an order placed.
  ///
  /// The live strips read the bookings and orders lists, and both are
  /// `getIt` singletons that only re-ask when the language changes. So
  /// a booking made in this session did not appear above the home page
  /// until the app was killed and reopened, and a cancelled one went
  /// on showing as confirmed while its own detail page said otherwise.
  static void ownedChanged() {
    // FETCHED, not merely invalidated.
    //
    // `invalidate` only clears the "already loaded" mark, and the
    // screens that would act on it ask in `didChangeDependencies` —
    // which does NOT run again when a page is returned to by popping.
    // So cancelling a booking and pressing back left «ورشاتي» showing
    // it as confirmed, and a booking just made did not appear at all
    // until the language changed or the app was killed.
    //
    // These are the lists the reader is about to look at, and they
    // are one request each.
    _ifRegistered<LiveNowCubit>((c) => unawaited(c.load()));
    _ifRegistered<MyBookingsCubit>((c) => unawaited(c.load()));
    // «طلباتي ٣» and «مفضلتي ٥» count the same things an order or a
    // favourite just moved, and the profile row that prints them is
    // reached by popping — where `didChangeDependencies` does not run.
    _ifRegistered<ProfileCountsCubit>((c) => unawaited(c.load()));
    // THE BALANCE MOVED TOO.
    //
    // Paying with the Terracotta balance debits it, and cancelling
    // credits it back — but the wallet is a `getIt` singleton with a
    // `hasData` guard, so `ensureLoaded` saw a balance already on
    // screen and never asked again. The customer paid, went to their
    // profile, and read the number they had before.
    //
    // FETCHED, not just invalidated. The screens that show a balance
    // ask for it in `didChangeDependencies`, which does not run again
    // when a page is returned to by popping — and this is the one
    // number the reader looks for straight after paying. It is a
    // single row (`per_page=1`), so asking is cheap.
    _ifRegistered<WalletCubit>((c) => unawaited(c.load()));
    // THE HOME PAYLOAD CARRIES `current_booking`, and a status that
    // just moved is exactly what that strip reports.
    _ifRegistered<HomeCubit>((c) => unawaited(c.load()));

    // AND TELL WHATEVER PAGE IS OPEN.
    //
    // Everything above is a `getIt` singleton this can reach. The page
    // the reader is actually looking at usually is not: a booking
    // detail and an order detail each own their cubit, and it dies
    // with the page. So when a PUSH says a booking moved to
    // `on_the_way`, the list behind reloads and the screen in front —
    // the one showing that very booking — does not.
    //
    // A notifier rather than a registry: a page listens while it is
    // mounted and stops when it is not, which is the only lifetime
    // that is correct for a thing that dies with its route.
    revision.value++;
  }

  /// Bumped whenever something the reader OWNS has changed.
  ///
  /// Pages with their own cubit listen to this and reload. See
  /// [ownedChanged] for why the singletons above are not enough.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void _ifRegistered<T extends Object>(void Function(T) drop) {
    if (getIt.isRegistered<T>()) drop(getIt<T>());
  }
}
