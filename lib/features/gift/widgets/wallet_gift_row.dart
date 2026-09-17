import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/assets/assets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/workshop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/buttons/global_outlined_button.dart';
import '../../_shared/localized_rebuild.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../workshops/widgets/gift_backdrop.dart';
import '../data/gift_availability.dart';

/// «رصيدي» and «أهدِ رصيداً», side by side.
///
/// Lifted out of the workshops header so the SHOP can carry the same
/// pair. They are one offer — what the reader has, and the way to give
/// somebody else some — and two copies of it would drift.
class WalletGiftRow extends StatelessWidget {
  const WalletGiftRow({
    required this.balance,
    required this.onOpenWallet,
    required this.onGiftTap,
    this.showGift,
    super.key,
  });

  /// The wallet balance as a decimal STRING, exactly as the wire sends
  /// it. Never parsed on the way past.
  final String balance;
  final VoidCallback onOpenWallet;
  final VoidCallback onGiftTap;

  /// Whether the studio is selling gift credit at all — see
  /// `AppConfigService.allowsGift`.
  ///
  /// False takes the tile off and the BALANCE takes the width back.
  /// Leaving a gap where it was would read as something that failed to
  /// load rather than something the studio does not offer.
  ///
  /// Null asks the config itself, which is what both live callers
  /// want — the flag is one switch and every gift surface reads the
  /// same one.
  final bool? showGift;

  /// The height the pair is drawn at. Fixed, because the two cards
  /// carry different amounts of text and a row that sized itself to
  /// the taller one moved whenever the balance changed width.
  static const height = 172.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // BALANCE first. It is the fact the reader came for; the gift
      // tile is an offer beside it.
      children: [
        Expanded(
          child: WalletCard(balance: balance, onOpenLedger: onOpenWallet),
        ),
        if (showGift ?? giftsAllowed()) ...[
          SizedBox(width: context.spacing.md),
          GiftCard(onTap: onGiftTap),
        ],
      ],
    ),
  );
}

class GiftCard extends StatelessWidget {
  const GiftCard({this.onTap});

  final VoidCallback? onTap;

  /// The line work is HAIRLINE — a 121pt drawing blown up past the
  /// tile, so the strokes stay about a pixel wide however large the
  /// loop gets. At the 0.35 this started on they were invisible on a
  /// phone; the alpha has to carry the whole of the contrast.
  static const _patternAlpha = 0.55;

  @override
  Widget build(BuildContext context) {
    // The label is read HERE — see `dependOnLanguage`.
    dependOnLanguage(context);
    final onCoral = context.textColors.onPrimary;

    return SizedBox(
      width: 101,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.radii.md),
        // `Material` + `InkWell`, not a `GestureDetector`: a tap on a
        // coral tile with no ripple reads as a dead surface. The ink
        // needs a `Material` to splash on, and the tile's colour has to
        // BE that Material rather than a `ColoredBox` under it —
        // otherwise the splash paints beneath the coral and never
        // shows.
        child: Material(
          color: context.primaryColors.accent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // BEHIND everything and ignored by hit testing — it is
                // a texture, not a picture anyone is meant to look at.
                Positioned.fill(
                  child: GiftBackdrop(
                    tint: onCoral.withValues(alpha: _patternAlpha),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(context.spacing.sm),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        Assets.icons.gift.defaultPath,
                        width: context.iconSizes.lg,
                        height: context.iconSizes.lg,
                        colorFilter: ColorFilter.mode(onCoral, BlendMode.srcIn),
                      ),
                      SizedBox(height: context.spacing.sm),
                      Text(
                        WorkshopStrings.gift,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: onCoral,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «رصيد تيراكوتا» — the balance, with a link into the ledger.
class WalletCard extends StatelessWidget {
  const WalletCard({required this.balance, this.onOpenLedger});

  /// The decimal string exactly as the API sends it. Zero until the
  /// wallet is bound — printed, not hidden: an empty space where a
  /// balance goes reads as a screen that failed, and «٠ ريال» is the
  /// true answer for a new customer.
  final String balance;

  /// Into «محفظتي», where the rows behind this number are.
  final VoidCallback? onOpenLedger;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return TerracottaCard(
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            WorkshopStrings.walletBalance,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.textColors.primary,
            ),
          ),
          SizedBox(height: spacing.xs),
          // Through `PriceText`, so the digits localize and the
          // currency comes with them — «١٠٠ ريال». Never parsed to a
          // number on the way past.
          PriceText(amount: balance, large: true),
          const Spacer(),
          // A BUTTON, not a card that happens to be tappable: it was
          // a `TerracottaCard` with an arrow in it, which announced
          // nothing to a screen reader and had no pressed state.
          GlobalOutlinedButton(
            text: WorkshopStrings.viewTransactions,
            onPressed: onOpenLedger,
            style: ButtonStateStyle(
              // No inner gutter: the arrow is PINNED to the edge below,
              // and the module's default 16pt inset was measured from
              // inside it — so the arrow sat well short of the edge and
              // the label was centred in what was left. Same shape as
              // the auth CTA.
              padding: EdgeInsets.zero,
              // The SAME hairline the cards use, so the button reads as
              // part of the card it sits in rather than a control
              // dropped on top of it.
              border: BorderSide(color: context.primaryColors.border),
              // The trailing slot is the LOGICAL end — the left in
              // Arabic, because left is forward there — so the arrow
              // lands on the right side in both locales with no branch.
              trailing: TerracottaCtaArrow(color: context.iconColors.primary),
              // Pinned to the edge with the label centred in the whole
              // button: packed in a row the label sits off-centre by
              // half the arrow.
              slotsAtEdges: true,
              slotEdgeInset: kTerracottaCtaArrowInset,
            ),
          ),
        ],
      ),
    );
  }
}
