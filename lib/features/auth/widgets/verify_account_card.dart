import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/auth/auth_gate.dart';
import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_widgets.dart';
import '../data/verification_flow.dart';

/// «وثّق رقمك» — an account that is signed in and cannot yet buy.
///
/// ## Why a card and not a door
///
/// Under `REGISTER_REQUIRES_VERIFICATION` the server issues a session
/// before the code is entered, so the customer is inside the app with
/// an account the server will refuse at the two places that matter.
/// Locking them out would teach them the app is closed; this says what
/// is missing, where they will see it, and offers the one tap that
/// fixes it — while the shop, the gallery and the workshops stay
/// readable underneath.
///
/// It COLLAPSES to nothing for everybody else: a visitor has no
/// account to verify and a finished account has nothing to do. That is
/// watched rather than read once, so the card goes the moment the code
/// is accepted rather than on the next rebuild that happens to come
/// along.
///
/// The two revenue actions ask again at the button — see
/// `AuthGate.demandVerified`. This is the standing reminder; that is
/// the refusal.
class VerifyAccountCard extends StatefulWidget {
  const VerifyAccountCard({super.key});

  @override
  State<VerifyAccountCard> createState() => _VerifyAccountCardState();
}

class _VerifyAccountCardState extends State<VerifyAccountCard> {
  bool _sending = false;

  Future<void> _verify() async {
    setState(() => _sending = true);
    await VerificationFlow.start(context);
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthGate.watchNeedsVerification(context)) {
      return const SizedBox.shrink();
    }

    final spacing = context.spacing;
    // THE WARNING RAMP, not the error one. Nothing has gone wrong —
    // there is a step left, and red would read as a failed payment on
    // a page the reader has just arrived at.
    final tint = context.statusColors.warning;

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: spacing.sm),
      child: TerracottaCard(
        borderColor: tint,
        color: tint.withValues(alpha: 0.10),
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: context.iconSizes.md,
                  color: tint,
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    AuthStrings.verifyCardTitle,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.textColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.xs),
            Text(
              AuthStrings.verifyCardBody,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.textColors.secondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: spacing.md),
            GlobalFilledButton(
              text: AuthStrings.verifyCardCta,
              isLoading: _sending,
              enabled: !_sending,
              style: terracottaCtaStyle(showArrow: false).copyWith(
                backgroundColor: tint,
                // MEASURED, not white. The amber is a light ground —
                // white on it is 3.02:1, which `GlobalFilledButton`'s
                // own checker logs as below AA. This is a status
                // surface rather than a brand band, so legibility
                // wins; see `WorkshopFamilyColors.onWireColor`.
                foregroundColor: WorkshopFamilyColors.onWireColor(tint),
              ),
              onPressed: () => unawaited(_verify()),
            ),
          ],
        ),
      ),
    );
  }
}
