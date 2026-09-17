import 'package:flutter/material.dart';

import '../../core/animations/animation_presets.dart';
import '../../core/localization/strings/module_strings.dart'
    show IndicatorStrings;
import '../../shared/module/image/global_image.dart';

/// The design's page indicator: small VESSELS, the current one filled
/// in the mark brown and the rest in grey.
///
/// Laid out in LOGICAL order, so the Arabic build fills from the right
/// and the English build from the left without either being
/// special-cased.
///
/// Lived inside `onboarding_page.dart` until the piece-photos sheet
/// needed the same thing. A second copy would have been two drawings
/// of the same mark drifting apart — the onboarding's is the one the
/// design draws, and anywhere else showing plain dots beside it reads
/// as a different app's screen.
class VesselIndicator extends StatelessWidget {
  const VesselIndicator({
    required this.count,
    required this.activeIndex,
    this.onTap,
    this.scale = 1,
    super.key,
  });

  final int count;
  final int activeIndex;

  /// Null makes the row inert — a REPORT of where the reader is rather
  /// than a way to move.
  final ValueChanged<int>? onTap;

  /// How big to draw it. [compactScale] for a sheet.
  final double scale;

  static const double dotWidth = 20.64;
  static const double dotHeight = 29;
  static const double dotGap = 7;

  /// A smaller draw of the same mark, for a sheet.
  ///
  /// The onboarding's size is set against a full-screen illustration;
  /// in a bottom sheet, under a picker, the same vessels read as a
  /// third element competing with the field and the photographs rather
  /// than as a footnote saying where you are.
  static const double compactScale = 0.62;

  /// The mark brown. DARKER than the `#81341A` app chrome — the design
  /// uses it for the vessel silhouette and the active indicator, and
  /// the two are close enough that substituting one for the other
  /// reads as a rendering bug rather than a choice.
  static const Color brown = Color(0xFF72291B);

  /// The spent-indicator grey. Slightly green, not the palette's
  /// neutral `outline`.
  static const Color grey = Color(0xFFE4E6E1);

  static const String asset = 'assets/images/vessel-dot.png';

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    value: IndicatorStrings.pageOf(activeIndex + 1, count),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) SizedBox(width: dotGap * scale),
          if (onTap case final tap?)
            Semantics(
              button: true,
              selected: i == activeIndex,
              label: IndicatorStrings.goToPage(i + 1),
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => tap(i),
                behavior: HitTestBehavior.opaque,
                child: _Vessel(active: i == activeIndex, scale: scale),
              ),
            )
          else
            _Vessel(active: i == activeIndex, scale: scale),
        ],
      ],
    ),
  );
}

class _Vessel extends StatelessWidget {
  const _Vessel({required this.active, this.scale = 1});

  final bool active;
  final double scale;

  /// How much bigger the current vessel sits. Small on purpose — the
  /// row is 8pt tall and anything more reads as a wobble.
  static const _activeScale = 1.28;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: active ? 1 : 0),
      duration: reduced ? Duration.zero : AppDurations.normal,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => Transform.scale(
        scale: 1 + (_activeScale - 1) * t,
        child: GlobalImage.a(
          VesselIndicator.asset,
          width: VesselIndicator.dotWidth * scale,
          height: VesselIndicator.dotHeight * scale,
          style: ImageStyle(
            // The dot is 8 by 11. The house 8pt corner radius would
            // round away most of it.
            borderRadius: BorderRadius.zero,
            color: Color.lerp(VesselIndicator.grey, VesselIndicator.brown, t),
            // srcIn, not the default srcATop: the asset is a solid
            // silhouette on transparency, and srcATop would tint the
            // transparent field with it too.
            overlayBlendMode: BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
