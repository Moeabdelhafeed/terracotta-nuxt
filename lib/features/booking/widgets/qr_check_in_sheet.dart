import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../workshops/widgets/gift_backdrop.dart';
import 'sheet_shell.dart';

/// «رمز المسح» — the QR the customer shows at the door.
///
/// The API returns `qr_value` and `checkin_code` as the SAME 8-digit
/// value: the original 36-character token produced a dense symbol too
/// large to print on a label, so it was shortened to match what the
/// design already drew. Render `qr_value` as the QR and print
/// `checkin_code` underneath — the studio types it in if a camera
/// fails, which is the whole reason it is visible.
class QrCheckInSheet extends StatelessWidget {
  const QrCheckInSheet({
    this.code = '',
    this.panelColor,
    this.tint,
    super.key,
  });

  /// `checkin_code`, printed under the symbol.
  final String code;

  /// The workshop family's panel tint — the well behind the symbol.
  final Color? panelColor;

  /// The workshop's own colour, for the symbol and the close button.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final ink = tint ?? context.primaryColors.primary;

    return SheetShell(
      // SIZED TO ITSELF. A symbol, a line and a button do not fill 62%
      // of a screen, and putting them in a scroll view that can never
      // scroll only costs a gesture-arena entry.
      heightFactor: null,
      title: BookingStrings.scanCode,
      // Over a symbol that is itself centred.
      centerTitle: true,
      // The close button in the WORKSHOP's colour, like every other
      // action on this booking.
      footer: GlobalFilledButton(
        text: BookingStrings.close,
        style: terracottaCtaStyle(
          showArrow: false,
        ).copyWith(backgroundColor: ink),
        onPressed: () => Navigator.of(context).pop(),
      ),
      children: [
        // The house loop behind the WHOLE card — the same drawing the
        // gift tile and the scan chip wear, so the well reads as a
        // surface rather than a grey box. It runs under the code as
        // well as the symbol: behind the symbol alone it stopped at a
        // seam halfway down the card, which is the one place a
        // background must not have an edge.
        ClipRRect(
          borderRadius: BorderRadius.circular(context.radii.lg),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: panelColor ?? context.backgroundColors.container,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: GiftBackdrop(tint: ink.withValues(alpha: 0.16)),
                ),
                Padding(
                  // Room to breathe: the design gives the card a good
                  // deal more height than the symbol needs, and the
                  // loop wants space to show through.
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.md,
                    vertical: spacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // A REAL SYMBOL, not a glyph of one.
                      //
                      // It drew `Icons.qr_code_2_rounded` — the same
                      // picture for every booking, and unscannable. The
                      // desk's camera reads THIS, and the eight digits
                      // under it are what the studio types when a
                      // camera will not focus.
                      //
                      // `qr_value` and `checkin_code` are the same
                      // eight digits on this API, so one value serves
                      // both the symbol and the fallback.
                      SizedBox.square(
                        dimension: 240,
                        child: code.isEmpty
                            // Nothing to encode. A blank square is
                            // honest; a symbol of an empty string is a
                            // code that scans to nothing.
                            ? Icon(
                                Icons.qr_code_2_rounded,
                                size: 230,
                                color: ink.withValues(alpha: 0.3),
                              )
                            : QrImageView(
                                data: code,
                                version: QrVersions.auto,
                                // The panel behind it is already the
                                // card; drawing another would put a
                                // white square on a white square.
                                backgroundColor: Colors.transparent,
                                eyeStyle: QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: ink,
                                ),
                                dataModuleStyle: QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: ink,
                                ),
                                // Silence around the symbol is part of
                                // the symbol — a scanner needs it to
                                // find the edges.
                                padding: EdgeInsets.all(spacing.sm),
                              ),
                      ),
                      SizedBox(height: spacing.md),
                      Text(
                        code,
                        // The manual fallback is always Latin digits and
                        // always reads left-to-right, whatever the
                        // locale — it is typed into a till, not read as
                        // prose.
                        textDirection: TextDirection.ltr,
                        style: context.textTheme.headlineSmall?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: spacing.md),
        Text(
          BookingStrings.qrInstructions,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.textColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Opens [QrCheckInSheet] over the booking detail.
Future<void> showQrCheckInSheet(
  BuildContext context, {
  String code = '',
  Color? panelColor,
  Color? tint,
}) => showTerracottaSheet<void>(
  context,
  builder: (_) =>
      QrCheckInSheet(code: code, panelColor: panelColor, tint: tint),
);
