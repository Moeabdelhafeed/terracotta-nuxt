import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/blocs/auth/auth_bloc.dart';
import '../../../data/blocs/auth/auth_state.dart';
import '../../../data/models/auth/user/user.dart';
import '../../../shared/module/avatar/global_avatar.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_widgets.dart';
import '../cubits/wallet_state.dart';

/// Who is signed in, and what they have to spend.
///
/// The account home was a bare list of rows under a centred word. This
/// is the one thing on it that is ABOUT the customer rather than a way
/// out of it.
///
/// The name, the number and the initials are read from `AuthBloc` —
/// `POST /api/login` already returned them and there is no
/// `GET /api/profile` to ask again (that route 404s). Only the balance
/// costs a request, because it is the one field that goes stale.
class AccountHeader extends StatelessWidget {
  const AccountHeader({
    required this.wallet,
    this.onEditName,
    this.onOpenWallet,
    this.onSignIn,
    super.key,
  });

  /// The balance, or null while the one request is out.
  final WalletState wallet;

  /// Rename the account. The NAME is the only profile field this tenant
  /// lets anyone edit, which is why it is a pencil here rather than a
  /// row into a page with one input on it.
  final ValueChanged<User>? onEditName;

  /// Into the ledger. The balance row IS the way there — the list below
  /// used to carry a «محفظتي» row saying the same thing twice.
  final VoidCallback? onOpenWallet;

  /// Sign in, for a reader who has not. A guest has no balance to show
  /// — the server refuses `/api/wallet/*` outright — so the strip that
  /// would sit there becomes the way to get one.
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<AuthBloc, AuthState, User?>(
        selector: (state) => switch (state) {
          AuthAuthenticated(:final user) => user,
          _ => null,
        },
        builder: (context, user) {
          final spacing = context.spacing;
          // The server keeps ONE name field, split on the first space by
          // `toAppUser` — so putting it back together is what shows the
          // whole name rather than a greeting's first word.
          final name = [
            ?user?.firstName,
            ?user?.lastName,
          ].where((p) => p.trim().isNotEmpty).join(' ');

          return TerracottaCard(
            padding: EdgeInsets.all(spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GlobalAvatar(
                      // No `avatar` on this tenant's wire, so the initials
                      // are the picture — `GlobalAvatar` derives them from
                      // the name it is given.
                      name: name.isEmpty ? null : name,
                      size: _avatar,
                    ),
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name.isEmpty
                                      ? (user == null
                                            ? ProfileStrings.guest
                                            : ProfileStrings.title)
                                      : name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.titleMedium
                                      ?.copyWith(
                                        color: context.textColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              // The NAME is the only profile field this
                              // tenant lets anyone edit, which is why it
                              // is a pencil here rather than a row into
                              // a page with one input on it.
                              if (onEditName != null && user != null)
                                IconButton(
                                  onPressed: () => onEditName!(user),
                                  icon: Icon(
                                    Icons.edit_rounded,
                                    size: context.iconSizes.sm,
                                    color: context.primaryColors.primary,
                                  ),
                                  tooltip: ProfileStrings.editName,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                          if (user?.phoneNumber case final phone?
                              when phone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              phone,
                              // The number is LTR whatever the page is:
                              // Arabic would otherwise move the leading `+`
                              // to the far end of it.
                              textDirection: TextDirection.ltr,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.textColors.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.md),
                // A guest has no balance — `/api/wallet/*` answers 401
                // for them — so the strip that would say so becomes the
                // way to stop being one.
                if (user == null)
                  _GuestStrip(onSignIn: onSignIn)
                else
                  _BalanceRow(wallet: wallet, onTap: onOpenWallet),
              ],
            ),
          );
        },
      );

  static const _avatar = 56.0;
}

/// «رصيد تيراكوتا» and the way into the ledger.
class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.wallet, this.onTap});

  final WalletState wallet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    // The WHOLE row is the target, not the arrow on the end of it: a
    // 40-point glyph is a small thing to aim at when the strip beside
    // it says the same.
    //
    // `Material` + `InkWell`, not an `InkWell` over a `DecoratedBox`:
    // ink paints on the nearest Material ABOVE it, so a box painting
    // its own colour on top hides the splash completely — the row was
    // tappable and looked dead.
    return Material(
      color: context.backgroundColors.container,
      borderRadius: BorderRadius.circular(context.radii.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          child: Row(
            // Explicit, not left to the default: the glyph, the words
            // and the price are three different heights, and the row is
            // measured by the tallest of them.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: context.iconSizes.sm,
                color: context.primaryColors.primary,
              ),
              SizedBox(width: spacing.xs),
              Expanded(
                child: Text(
                  ProfileStrings.wallet,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.textColors.primary,
                  ),
                ),
              ),
              // «٠ ريال» while it is unknown, not a spinner and not a
              // blank: a balance is a number the customer expects to be
              // there, and an empty space where one goes reads as a
              // screen that failed. Money stays a decimal STRING.
              PriceText(amount: wallet.balance ?? '0.00'),
              SizedBox(width: spacing.xs),
              Icon(
                Icons.arrow_forward_rounded,
                size: context.iconSizes.sm,
                color: context.primaryColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «سجّل الدخول لحفظ سلتك وحجوزاتك ورصيدك» — where the balance goes
/// when there is no account to have one.
class _GuestStrip extends StatelessWidget {
  const _GuestStrip({this.onSignIn});

  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ProfileStrings.guestHint,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.textColors.secondary,
          ),
        ),
        SizedBox(height: spacing.sm),
        GlobalFilledButton(
          text: AuthStrings.signIn,
          onPressed: onSignIn,
          style: terracottaCtaStyle(showArrow: false),
        ),
      ],
    );
  }
}
